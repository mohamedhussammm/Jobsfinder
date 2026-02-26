import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/social_button.dart';
import '../../../core/theme/colors.dart';
import '../../../controllers/auth_controller.dart';

/// Social login section with Google Sign-In
class SocialLoginSection extends ConsumerStatefulWidget {
  const SocialLoginSection({super.key});

  @override
  ConsumerState<SocialLoginSection> createState() => _SocialLoginSectionState();
}

class _SocialLoginSectionState extends ConsumerState<SocialLoginSection> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await ref.read(authControllerProvider).signInWithGoogle();

      if (!mounted) return;

      if (result.success && result.role != null) {
        // Navigate based on role
        switch (result.role) {
          case 'admin':
            context.go('/admin/dashboard');
            break;
          case 'team_leader':
            context.go('/team-leader/events');
            break;
          default:
            context.go('/');
            break;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Google sign-in failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          label: _isGoogleLoading ? 'Signing in...' : 'Google',
          iconPath: 'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
          onTap: _isGoogleLoading ? () {} : () => _handleGoogleSignIn(),
        ),
      ],
    );
  }
}
