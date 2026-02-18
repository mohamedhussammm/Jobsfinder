import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/social_button.dart';
import '../../../services/social_auth_service.dart';
import '../../../core/theme/colors.dart';

class SocialLoginSection extends ConsumerWidget {
  const SocialLoginSection({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      final socialAuth = ref.read(socialAuthServiceProvider);
      final result = await socialAuth.signInWithGoogle();

      result.when(
        success: (_) {
          // OAuth flow initiated - user will be redirected to Google
          // The actual callback will be handled by deep linking
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to Google...'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        error: (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Google sign in failed: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleFacebookSignIn(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final socialAuth = ref.read(socialAuthServiceProvider);
      final result = await socialAuth.signInWithFacebook();

      result.when(
        success: (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to Facebook...'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        error: (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Facebook sign in failed: ${e.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SocialButton(
          label: 'Google',
          iconPath: 'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
          onTap: () => _handleGoogleSignIn(context, ref),
        ),
        const SizedBox(height: 16),
        SocialButton(
          label: 'Facebook',
          iconPath: 'https://cdn-icons-png.flaticon.com/512/5968/5968764.png',
          isOutlined: true,
          onTap: () => _handleFacebookSignIn(context, ref),
        ),
      ],
    );
  }
}
