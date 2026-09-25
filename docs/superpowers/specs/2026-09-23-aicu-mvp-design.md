# AICU MVP Design Spec

**Date:** 2026-09-23
**Product:** AICU — shared nurse/doctor patient handover app for hospital wards.

## 1. Problem and approach

Paper and verbal handovers lose information both within a role (nurse to nurse)
and across roles (nurse to doctor, doctor to doctor). AICU is one shared
patient record with two role-specific views generated from it: nurses document
in an SBAR-oriented workflow, doctors in an I-PASS-oriented workflow, and both
handovers are auto-generated from the same underlying data so nothing has to
be re-typed or re-said.

The demo centerpiece is the escalation flow: a nurse's vitals entry pushes a
patient's NEWS2 score over threshold, an alert reaches the doctor, and the
doctor acknowledges it in-app with the response time logged. Everything else
in the MVP exists to make that flow real (shared record, roles, tasks) or to
round out the handover pitch (SBAR/I-PASS generation, audit log).

## 2. Tech stack (given, not chosen here)

| Layer | Choice |
|---|---|
| Mobile frontend | Flutter (Dart) |
| Wearable connectivity | BLE GATT via `flutter_blue_plus` |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File storage | Firebase Storage |
| Push notifications | Firebase Cloud Messaging |
| Local/offline storage | Hive (or SQLite) |
| Scoring logic | Custom Dart implementation of NEWS2 |

Installed locally: Flutter 3.41.6 / Dart 3.11.4. The Firebase CLI is **not**
installed; provisioning a Firebase project and running `flutterfire configure`
is a prerequisite step, not a plan task (it needs an interactive Google
login).

## 3. Explicit stack-gap decisions

These are real gaps between the stated stack and the pitched features. Each
is decided here so tasks don't invent a different answer.

1. **Cross-user push (FCM) needs a server.** A Flutter client cannot send an
   FCM message to another client's device directly — that requires a trusted
   sender (Cloud Functions on the Blaze plan, or a custom backend), which is
   not in the stack. **Decision:** the demo-critical path is a Firestore
   **realtime listener** on the `escalations` collection — the doctor app
   opens a `snapshots()` stream filtered to their ward and shows an in-app
   alert the instant a document is written. FCM push (for when the doctor's
   app isn't foregrounded) is explicitly **roadmap**, gated on standing up a
   Cloud Function, and must not be a dependency of the escalation demo.

2. **Voice-to-SBAR / voice-to-note has no speech-to-text or LLM in the
   stack.** Building it would mean adding an unlisted dependency
   (`speech_to_text` or similar) and a summarization step with no model
   behind it. **Decision:** voice input is **roadmap**, not MVP. Nurse and
   doctor views use structured quick-entry forms (dropdowns, steppers, short
   text fields) for the same data voice would have captured. This is called
   out explicitly in the pitch as "voice input is the next iteration," not
   silently dropped.

3. **Offline storage.** Cloud Firestore ships with offline persistence
   built in (cached reads, queued writes, auto-replay on reconnect) once
   persistence is enabled on the client. **Decision:** don't build a custom
   Hive↔Firestore sync engine — that would duplicate what Firestore already
   does and risks the two stores disagreeing. Use Firestore's own offline
   cache for all shared patient data. Reserve Hive for genuinely
   local-only, non-synced data: unsent draft notes, per-device UI
   preferences, and the raw BLE sample buffer before it's parsed into a
   vitals reading. If a reviewer wants a custom sync engine instead, that's
   a deliberate scope increase to flag, not a default.

4. **BLE wearable connectivity is not one of the 6 MVP items** in section 4
   below (manual vitals entry is). **Decision:** BLE is the *last* build
   phase, additive behind manual entry — a nurse can always type vitals in.
   Because stage demos can't depend on a physical wearable being present and
   paired, the BLE phase also includes a simulated-deterioration data
   generator that feeds the same vitals pipeline, so the escalation demo
   works with or without hardware in the room.

5. **QR scan (MVP item 1) needs a camera/QR package not listed in the
   stack table.** Unlike voice input, this one is explicitly named in the
   MVP scope, so it isn't deferred. **Decision:** add `mobile_scanner` as a
   minimal, single-purpose dependency (camera permission + QR decode only);
   it decodes to a `patientId` string that's looked up directly in
   `patients/{patientId}` — no new data model needed.

6. **Security rules are a trust boundary, not an implementation detail.**
   Firestore security rules must enforce: only a doctor role can write to
   `orders`; only a nurse role can write to `medAdmins`; `events` (the audit
   log) is append-only for all roles (create, no update/delete); a user can
   only read/write patients on their own ward. These are tested against the
   Firestore emulator, not left to client-side checks. This is a synthetic
   -patient prototype — the plan makes no HIPAA/clinical-compliance claim.

## 4. MVP scope (from the adjusted brief)

1. Shared patient card — QR scan, allergies, diagnosis, vitals with NEWS2
   trend, lines/tubes, intake/output.
2. Nurse view — vitals entry, medication administration record (MAR), task
   list, structured SBAR note (voice input is roadmap, see §3.2).
3. Doctor view — patient summary, orders that create nurse tasks, structured
   note (voice input is roadmap).
4. Escalation flow — NEWS2 threshold alert, nurse-to-doctor SBAR escalation,
   doctor acknowledgement, response-time logging.
5. Auto-generated handovers — SBAR for nurses, I-PASS for doctors, "changes
   since last shift" diff, missing-data warnings, receiver acknowledgement.
6. Event timeline and audit log.

**Demo-critical cut line** (build first, per the vertical slice in §7):
items 1, 2 (vitals entry only), and 4. Items 2 (MAR/tasks/note), 3, 5, 6 are
needed for the full pitch but can slip without breaking the headline demo.
BLE (§3.4) is post-cut-line.

## 5. Roles

- **Nurse** — ward list with NEWS2-colored rows, quick vitals entry, MAR,
  task list, SBAR note.
- **Doctor** — patient summary, trends, timeline, orders, I-PASS handover.
- **Consultant / Admin** — read-only + analytics. Explicitly **roadmap**,
  not in this plan.

## 6. Firestore data model

All collections are top-level, scoped by `wardId` for the security rules in
§3.6. IDs are Firestore auto-IDs unless noted. Timestamps are Firestore
`Timestamp`, stored and compared in UTC.

```
patients/{patientId}
  wardId: string
  fullName: string
  dob: Timestamp
  allergies: string[]
  diagnosis: string
  lines: { type: string, insertedAt: Timestamp, site: string }[]
  intakeOutputMl: { intake: number, output: number, sinceTimestamp: Timestamp }
  qrCode: string                      // encodes patientId for the scan flow

vitals/{vitalId}
  patientId: string
  wardId: string
  recordedBy: string                  // uid of nurse
  recordedAt: Timestamp
  respirationRate: number             // breaths/min
  spo2: number                        // %
  spo2Scale: 1 | 2                    // which NEWS2 SpO2 scale was used
  onSupplementalOxygen: bool
  systolicBp: number                  // mmHg
  pulse: number                       // beats/min
  consciousness: "A" | "C" | "V" | "P" | "U"   // ACVPU
  temperature: number                 // °C
  news2Score: number                  // computed at write time, see §8
  news2Band: "none" | "low" | "medium" | "high"
  news2RedFlag: bool                  // true if any single parameter scored 3

orders/{orderId}
  patientId: string
  wardId: string
  createdBy: string                   // uid of doctor
  createdAt: Timestamp
  description: string                 // e.g. "repeat lactate at 06:00"
  dueAt: Timestamp
  taskId: string                      // the tasks/{taskId} this order created

tasks/{taskId}
  patientId: string
  wardId: string
  sourceOrderId: string | null        // null for nurse-originated tasks
  description: string
  dueAt: Timestamp
  status: "pending" | "done" | "overdue"
  completedBy: string | null
  completedAt: Timestamp | null

medAdmins/{medAdminId}
  patientId: string
  wardId: string
  orderId: string | null
  medication: string
  scheduledAt: Timestamp
  administeredBy: string              // uid of nurse
  status: "given" | "held"
  holdReason: string | null
  administeredAt: Timestamp | null
  pharmacyVerified: bool              // simple flag; full module is roadmap

escalations/{escalationId}
  patientId: string
  wardId: string
  triggeredByVitalId: string
  news2Score: number
  news2Band: string
  raisedBy: string                    // uid of nurse
  raisedAt: Timestamp
  sbarSummary: { situation: string, background: string, assessment: string, recommendation: string }
  acknowledgedBy: string | null       // uid of doctor
  acknowledgedAt: Timestamp | null
  responseTimeSeconds: number | null  // acknowledgedAt - raisedAt, computed at ack time

handovers/{handoverId}
  patientId: string
  wardId: string
  type: "sbar" | "ipass"
  generatedAt: Timestamp
  shiftFrom: Timestamp
  shiftTo: Timestamp
  content: map                        // shape depends on type, see §9
  missingDataWarnings: string[]
  acknowledgedBy: string | null
  acknowledgedAt: Timestamp | null

events/{eventId}                      // append-only audit log
  patientId: string
  wardId: string
  actorId: string
  action: string                      // e.g. "vitals.recorded", "order.created"
  refCollection: string
  refId: string
  occurredAt: Timestamp
```

Every task in the plan that touches one of these collections must use these
field names exactly — this is the shared contract between tasks.

## 7. Build order (vertical slice)

1. Project scaffold, Firebase Auth, role-based routing.
2. Patient record model + NEWS2 scoring engine (pure Dart, §8).
3. Nurse vitals entry (writes `vitals`, computes NEWS2 on write).
4. Escalation flow (NEWS2 red-flag/threshold → `escalations` doc → doctor
   realtime listener → acknowledgement).
5. Doctor acknowledgement UI + response-time logging.
   *(1–5 is the demo-critical path.)*
6. Handover generation (SBAR + I-PASS, diff-since-last-shift, missing-data
   warnings, acknowledgement).
7. Orders → tasks (doctor creates order, nurse sees task, overdue status).
8. Medication loop (prescribe → administer/hold → doctor sees actual).
9. Event timeline / audit log.
10. BLE wearable connectivity + simulated deterioration feed (roadmap-facing,
    additive, see §3.4).

## 8. NEWS2 scoring (source of truth)

Source: Royal College of Physicians, *National Early Warning Score (NEWS) 2:
Standardising the assessment of acute-illness severity in the NHS*, updated
report of a working party, December 2017 (the NEWS2 observation chart,
p.16 of the PDF). Not to be re-derived from memory; these are the exact
published bands.

**Respiration rate (breaths/min):**
| Range | Score |
|---|---|
| ≥25 | 3 |
| 21–24 | 2 |
| 18–20 | 0 |
| 15–17 | 0 |
| 12–14 | 0 |
| 9–11 | 1 |
| ≤8 | 3 |

**SpO2 Scale 1 (%) — default scale, used unless Scale 2 is explicitly selected:**
| Range | Score |
|---|---|
| ≥96 | 0 |
| 94–95 | 1 |
| 92–93 | 2 |
| ≤91 | 3 |

**SpO2 Scale 2 (%) — only for clinician-directed use, e.g. hypercapnic
respiratory failure with a target range of 88–92%:**
| Range | Score |
|---|---|
| ≥97 on O2 | 3 |
| 95–96 on O2 | 2 |
| 93–94 on O2 | 1 |
| ≥93 on air | 0 |
| 88–92 | 0 |
| 86–87 | 1 |
| 84–85 | 2 |
| ≤83 | 3 |

**Supplemental oxygen:** +2 if the patient is on any supplemental O2 to
maintain their target saturation (this is on top of whichever SpO2 scale
score applies; it's an input flag, not a scale itself).

**Systolic blood pressure (mmHg):**
| Range | Score |
|---|---|
| ≥220 | 3 |
| 111–219 | 0 |
| 101–110 | 1 |
| 91–100 | 2 |
| ≤90 | 3 |

**Pulse (beats/min):**
| Range | Score |
|---|---|
| ≥131 | 3 |
| 121–130 | 2 |
| 91–120 | 1 |
| 51–90 | 0 |
| 41–50 | 1 |
| ≤40 | 3 |

**Consciousness (ACVPU):**
| Value | Score |
|---|---|
| Alert | 0 |
| Confusion (new), Voice, Pain, Unresponsive | 3 |

New confusion scores the same as V/P/U (3) — it is not a separate lesser
score. If it's unclear whether confusion is new, treat it as new.

**Temperature (°C):**
| Range | Score |
|---|---|
| ≥39.1 | 2 |
| 38.1–39.0 | 1 |
| 36.1–38.0 | 0 |
| 35.1–36.0 | 1 |
| ≤35.0 | 3 |

**Aggregation and bands:**
- Aggregate = sum of the six parameter scores + supplemental-oxygen (+2).
- `news2RedFlag` = true if **any single parameter** scored 3, regardless of
  aggregate — this triggers urgent review even at a low aggregate.
- Bands: aggregate 0 → `none` (routine, 12-hourly monitoring); 1–4 →
  `low` (nurse-led review, 4–6 hourly); a red flag (any single 3) always
  means at least hourly monitoring and urgent clinician review regardless of
  band; 5–6 → `medium` (urgent clinician review, hourly monitoring, consider
  escalation to a team with critical-care skills); ≥7 → `high` (emergency
  assessment, continuous monitoring).
- Escalation trigger (§9 below) fires on `medium`, `high`, or any red flag —
  not on a raw aggregate cutoff invented outside this chart.

## 9. Escalation and handover generation logic

**Escalation trigger:** a nurse's `vitals` write computes NEWS2. If the
result is `medium`, `high`, or `news2RedFlag`, the app prompts the nurse to
escalate. On confirm, it writes an `escalations` doc with an auto-filled SBAR
summary (Situation = patient + score + band, Background = diagnosis +
allergies, Assessment = which parameters are abnormal, Recommendation =
suggested urgency from the band). The doctor's realtime listener on
`escalations` (filtered by `wardId`, `acknowledgedAt == null`) surfaces it
immediately. Acknowledging sets `acknowledgedBy`/`acknowledgedAt` and computes
`responseTimeSeconds`.

**SBAR handover (nurse-to-nurse):** generated from the most recent `vitals`,
open `tasks`, `medAdmins` in the shift window, and any `escalations` in the
window. Includes a "changes since last shift" diff against the previous
handover of the same type for the same patient (which vitals/tasks changed),
and `missingDataWarnings` for any expected-but-absent data (e.g. no vitals
recorded in the last 4 hours).

**I-PASS handover (doctor-to-doctor):** generated from `patients` (illness
severity from latest NEWS2 band), diagnosis and plan (from notes/orders),
pending `orders`/`tasks`, and a "watch for overnight" field derived from the
most recent abnormal parameters. Same diff-since-last-shift and
missing-data-warning treatment as SBAR.

## 10. Out of scope for this plan (explicit roadmap)

- FCM background push (§3.1).
- Voice-to-SBAR / voice-to-note (§3.2).
- Custom Hive↔Firestore sync engine (§3.3) — Firestore's own persistence is
  used instead.
- Consultant/admin read-only + analytics views.
- Full pharmacy verification module (only a boolean flag is in MVP).
- HIPAA/regulatory compliance work — this is a synthetic-data prototype.
