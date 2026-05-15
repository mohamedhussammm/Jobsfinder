import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/logo/bond.jpeg',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'BOND',
              style: TextStyle(
                fontSize: ResponsiveHelper.sp(context, 32),
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find your next shift',
              style: TextStyle(
                fontSize: ResponsiveHelper.sp(context, 14),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accent.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
