import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final authController = ref.read(authControllerProvider);
      final user = await authController.signInWithGoogle();
      
      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final authController = ref.read(authControllerProvider);
      final user = await authController.signInWithFacebook();
      
      if (user != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Title
              Text(
                'Architects of the\nNext Era',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32.sp,
                    ),
              ),
              SizedBox(height: 16.h),
              
              // Subtitle
              Text(
                'Join the conversation',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              SizedBox(height: 48.h),
              
              // Google Sign In
              _buildSocialButton(
                context,
                icon: LucideIcons.chrome,
                label: 'Continue with Google',
                onPressed: _isLoading ? null : _handleGoogleSignIn,
              ),
              SizedBox(height: 16.h),
              
              // Facebook Sign In
              _buildSocialButton(
                context,
                icon: LucideIcons.facebook,
                label: 'Continue with Facebook',
                onPressed: _isLoading ? null : _handleFacebookSignIn,
              ),
              SizedBox(height: 32.h),
              
              // Guest mode
              TextButton(
                onPressed: _isLoading ? null : () {
                  context.go('/home');
                },
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              if (_isLoading) ...[
                SizedBox(height: 24.h),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24.sp),
        label: Text(
          label,
          style: TextStyle(fontSize: 16.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
