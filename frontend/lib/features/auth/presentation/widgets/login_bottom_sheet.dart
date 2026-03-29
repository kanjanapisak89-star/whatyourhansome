import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/providers/auth_providers.dart';

class LoginBottomSheet extends ConsumerStatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  ConsumerState<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends ConsumerState<LoginBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final authController = ref.read(authControllerProvider);
      final user = await authController.signInWithGoogle();
      
      if (user != null && mounted) {
        Navigator.of(context).pop(true);
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
        Navigator.of(context).pop(true);
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
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),
          
          // Title
          Text(
            'Sign in to continue',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20.sp,
                ),
          ),
          SizedBox(height: 8.h),
          
          // Subtitle
          Text(
            'Like, comment, and interact with posts',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          
          // Google Sign In
          _buildSocialButton(
            icon: LucideIcons.chrome,
            label: 'Continue with Google',
            onPressed: _isLoading ? null : _handleGoogleSignIn,
          ),
          SizedBox(height: 16.h),
          
          // Facebook Sign In
          _buildSocialButton(
            icon: LucideIcons.facebook,
            label: 'Continue with Facebook',
            onPressed: _isLoading ? null : _handleFacebookSignIn,
          ),
          SizedBox(height: 16.h),
          
          // Cancel
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isLoading
            ? SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 24.sp),
        label: Text(
          label,
          style: TextStyle(fontSize: 16.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
