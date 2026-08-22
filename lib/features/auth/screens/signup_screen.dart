import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

enum _SignupRole { user, it, admin }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  _SignupRole _selectedRole = _SignupRole.user;

  String get _selectedRoleValue {
    switch (_selectedRole) {
      case _SignupRole.admin:
        return 'admin';
      case _SignupRole.it:
        return 'it';
      case _SignupRole.user:
        return 'user';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        role: _selectedRoleValue,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // After successful registration, we sign out to ensure the user lands
        // on the login page to sign in manually, as requested.
        await _authService.signOut();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Detailed Signup Error: $e');
      setState(() {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('email-already-in-use')) {
          _errorMessage = 'This email is already in use.';
        } else if (errorString.contains('weak-password')) {
          _errorMessage = 'Password is too weak. Use at least 6 characters.';
        } else if (errorString.contains('invalid-email')) {
          _errorMessage = 'The email address is not valid.';
        } else if (errorString.contains('operation-not-allowed')) {
          _errorMessage = 'Email signup is disabled in Firebase Console.';
        } else if (errorString.contains('permission-denied')) {
          _errorMessage = 'Firestore permission denied. Check your rules.';
        } else {
          _errorMessage =
              'Signup failed: ${e.toString().split(']').last.trim()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: AppBar(
        backgroundColor: AppThemeColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppThemeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemeColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppThemeColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account role',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppThemeColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<_SignupRole>(
                          segments: const [
                            ButtonSegment<_SignupRole>(
                              value: _SignupRole.user,
                              label: Text('General User'),
                              icon: Icon(Icons.person_outline),
                            ),
                            ButtonSegment<_SignupRole>(
                              value: _SignupRole.it,
                              label: Text('IT'),
                              icon: Icon(Icons.computer_outlined),
                            ),
                            ButtonSegment<_SignupRole>(
                              value: _SignupRole.admin,
                              label: Text('Administrator'),
                              icon: Icon(Icons.admin_panel_settings_outlined),
                            ),
                          ],
                          selected: <_SignupRole>{_selectedRole},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _selectedRole = selection.first;
                            });
                          },
                        ),
                        if (_selectedRole == _SignupRole.admin ||
                            _selectedRole == _SignupRole.it) ...[
                          const SizedBox(height: 10),
                          Text(
                            _selectedRole == _SignupRole.admin
                                ? 'Admin access is granted by role assignment in Firestore after registration.'
                                : 'IT role is a label for now; elevated access is not enabled automatically.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? 'Min 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
