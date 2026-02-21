import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/dark_colors.dart';
import '../../core/theme/glass.dart';
import '../../controllers/auth_controller.dart';
import 'widgets/social_login_section.dart';

class NewAuthScreen extends ConsumerStatefulWidget {
  const NewAuthScreen({super.key});

  @override
  ConsumerState<NewAuthScreen> createState() => _NewAuthScreenState();
}

class _NewAuthScreenState extends ConsumerState<NewAuthScreen> {
  bool _isLogin = false;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _nationalIdController;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'normal'; // Default role: Usher/Applicant

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _nationalIdController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Login with role-based authentication
        final result = await ref
            .read(authControllerProvider)
            .loginWithRole(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (result.success && result.role != null) {
          if (mounted) {
            // Navigate based on role
            _navigateByRole(result.role!);
          }
        } else {
          setState(() => _errorMessage = result.errorMessage ?? 'Login failed');
        }
      } else {
        // Register with selected role
        final result = await ref
            .read(authControllerProvider)
            .registerUserWithRole(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              role: _selectedRole,
              // Phone and National ID are now REQUIRED
              phone: _phoneController.text.trim(),
              nationalId: _nationalIdController.text.trim(),
            );

        if (result.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Registration successful! Please login.',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.success,
              ),
            );
            setState(() {
              _isLogin = true;
              _selectedRole = 'normal';
            });
            _emailController.clear();
            _passwordController.clear();
            _fullNameController.clear();
            _phoneController.clear();
            _nationalIdController.clear();
          }
        } else {
          setState(
            () => _errorMessage = result.errorMessage ?? 'Registration failed',
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'admin':
        context.go('/admin/dashboard');
        break;
      case 'team_leader':
        context.go('/team-leader/events');
        break;
      case 'normal':
      case 'user': // Backward compatibility
      default:
        context.go('/');
        break;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'normal':
      case 'user':
        return 'Usher / Applicant';
      case 'team_leader':
        return 'Team Leader';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Title
                Text(
                  'ShiftSphere',
                  style: AppTypography.displayLarge.copyWith(
                    color: DarkColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Admin Login Hint
                if (_isLogin)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin: admin@shiftsphere.com',
                            style: AppTypography.caption.copyWith(
                              color: DarkColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Full Name (Registration only)
                      if (!_isLogin) ...[
                        TextField(
                          controller: _fullNameController,
                          style: AppTypography.body1,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: DarkColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: DarkColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextField(
                        controller: _emailController,
                        style: AppTypography.body1,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(
                            Icons.email,
                            color: DarkColors.primary,
                          ),
                          // Inherits other styles from theme
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextField(
                        controller: _passwordController,
                        style: AppTypography.body1,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: DarkColors.primary,
                          ),
                          // Inherits other styles from theme
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role Selection (Registration only)
                      if (!_isLogin) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          style: AppTypography.body1,
                          decoration: const InputDecoration(
                            labelText: 'I am a...',
                            prefixIcon: Icon(
                              Icons.work,
                              color: DarkColors.primary,
                            ),
                            // Inherits borders from theme
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'normal',
                              child: Text(_getRoleDisplayName('normal')),
                            ),
                            DropdownMenuItem(
                              value: 'team_leader',
                              child: Text(_getRoleDisplayName('team_leader')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone (Optional)
                        TextField(
                          controller: _phoneController,
                          style: AppTypography.body1,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            // Inherits borders from theme
                          ),
                        ),
                        const SizedBox(height: 16),

                        // National ID (Optional)
                        TextField(
                          controller: _nationalIdController,
                          style: AppTypography.body1,
                          decoration: InputDecoration(
                            labelText: 'National ID',
                            // Inherits borders from theme
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DarkColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Login' : 'Register',
                                  style: AppTypography.button.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Social Login Section
                const SocialLoginSection(),
                const SizedBox(height: 16),

                // Toggle Login/Register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                      _selectedRole = 'normal';
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin
                              ? "Don't have an account? "
                              : "Already have an account? ",
                        ),
                        TextSpan(
                          text: _isLogin ? 'Register' : 'Login',
                          style: const TextStyle(
                            color: DarkColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
