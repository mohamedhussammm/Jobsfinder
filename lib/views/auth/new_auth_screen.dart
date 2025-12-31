import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/glass.dart';
import '../../controllers/auth_controller.dart';

class NewAuthScreen extends ConsumerStatefulWidget {
  const NewAuthScreen({Key? key}) : super(key: key);

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
  bool _rememberMe = false;
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
      case 'company':
        context.go('/company/dashboard');
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
      case 'company':
        return 'Company';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
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
                    color: AppColors.accent,
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
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
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
                              color: AppColors.accent,
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
                      color: AppColors.error.withOpacity(0.1),
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
                            labelStyle: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: AppColors.accent,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accent),
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
                          labelStyle: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: AppColors.accent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
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
                          labelStyle: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: Icon(Icons.lock, color: AppColors.accent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role Selection (Registration only)
                      if (!_isLogin) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          style: AppTypography.body1,
                          decoration: InputDecoration(
                            labelText: 'I am a...',
                            labelStyle: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.work,
                              color: AppColors.accent,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accent),
                            ),
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
                            DropdownMenuItem(
                              value: 'company',
                              child: Text(_getRoleDisplayName('company')),
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
                            labelStyle: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.phone,
                              color: AppColors.accent,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // National ID (Optional)
                        TextField(
                          controller: _nationalIdController,
                          style: AppTypography.body1,
                          decoration: InputDecoration(
                            labelText: 'National ID',
                            labelStyle: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.badge,
                              color: AppColors.accent,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.accent),
                            ),
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
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  style: AppTypography.button,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                          style: TextStyle(
                            color: AppColors.accent,
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
