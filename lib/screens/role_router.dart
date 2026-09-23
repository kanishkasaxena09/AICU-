import 'package:flutter/material.dart';
import 'package:aicu/repositories/auth_repository.dart';

class RoleRouter extends StatelessWidget {
  final AuthRepository authRepository;
  final Widget nurseHome;
  final Widget doctorHome;
  const RoleRouter({super.key, required this.authRepository, required this.nurseHome, required this.doctorHome});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: authRepository.currentUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return snapshot.data == 'doctor' ? doctorHome : nurseHome;
      },
    );
  }
}
