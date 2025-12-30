import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reprise/core/constants/app_colors.dart';
import 'package:reprise/core/constants/app_text_styles.dart';
import 'package:reprise/core/constants/app_spacing.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTrainer = false; // ✅ Changed from _selectedRole to simple boolean

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateTrainerCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = List. generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'TRN-$code';
  }

  Future<void> _register() async {
    if (!_formKey. currentState!.validate()) return;

    setState(() => _isLoading = true);

    UserCredential? credential;

    try {
      print('🔐 Starting Firebase Auth registration.. .');
      
      // Create Firebase Auth user
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:  _emailController.text.trim(),
        password: _passwordController. text,
      );

      print('✅ Firebase Auth user created: ${credential.user?.uid}');

      final uid = credential. user!.uid;
      
      // ✅ Generate trainer code if trainer
      final trainerCode = _isTrainer ?  _generateTrainerCode() : null;

      // ✅ Create user document with correct format
      final userData = {
        'id': uid,
        'name': _nameController.text. trim(),
        'email': _emailController.text.trim(),
        'isTrainer': _isTrainer, // ✅ Boolean, not enum
        'trainerId': null,
        'trainerName':  null,
        'traineeIds': [],
        'trainees': [], // ✅ Add empty trainees array
        'trainerCode': trainerCode,
        'createdAt': DateTime.now().toIso8601String(),
        'trainerCodeUpdatedAt': trainerCode != null ? DateTime.now().toIso8601String() : null,
      };

      print('📝 Creating Firestore document: $userData');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      print('✅ Firestore document created successfully');

      // Wait for propagation
      await Future. delayed(const Duration(milliseconds:  500));

      print('✅ Registration complete!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome to RepRise, ${_nameController.text.trim()}!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Auto-navigate to main page
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e. code == 'email-already-in-use') {
        message = 'An account already exists with this email';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else {
        message = 'Auth error: ${e.message}';
      }

      // Delete the auth user if Firestore failed
      if (credential != null && credential.user != null) {
        try {
          await credential.user!.delete();
          print('🗑️ Deleted orphaned auth user');
        } catch (deleteError) {
          print('⚠️ Could not delete orphaned user: $deleteError');
        }
      }

      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ General error: $e');
      print('📍 Stack trace:  $stackTrace');
      
      // Delete the auth user if it was created
      if (credential != null && credential.user != null) {
        try {
          await credential.user!.delete();
          print('🗑️ Deleted orphaned auth user');
        } catch (deleteError) {
          print('⚠️ Could not delete orphaned user: $deleteError');
        }
      }

      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content: Text('Error:  ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds:  5),
          ),
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
      appBar: AppBar(
        title: Text('Create Account', style: AppTextStyles.h2()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing. xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment. start,
              children: [
                // Header
                Text(
                  'Join RepRise! ',
                  style: AppTextStyles.h1(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create your account to start tracking your fitness journey',
                  style: AppTextStyles.body(color: AppColors.textSecondaryLight),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing. md),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons. email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration:  InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon:  IconButton(
                      icon:  Icon(
                        _obscurePassword ? Icons.visibility : Icons. visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value. isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Role Selection
                Text('Choose Your Mode', style: AppTextStyles.h3()),
                const SizedBox(height: AppSpacing.md),

                // Personal Mode
                _buildRoleCard(
                  isTrainer: false,
                  icon: Icons.person,
                  title: 'Personal Mode',
                  description: 'Track your own workouts',
                  color: AppColors.primary,
                ),

                const SizedBox(height: AppSpacing.md),

                // Trainer Mode
                _buildRoleCard(
                  isTrainer: true,
                  icon: Icons.people,
                  title: 'Trainer Mode',
                  description:  'Manage trainees and assign workouts',
                  color:  AppColors.secondary,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ?  null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height:  AppSpacing.lg),

                // Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.body(),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required bool isTrainer,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _isTrainer == isTrainer;

    return Card(
      elevation:  isSelected ? 4 : 1,
      child: InkWell(
        onTap: () {
          setState(() => _isTrainer = isTrainer);
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color :  Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing. sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing. radiusSmall),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h4()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description, style: AppTextStyles.caption()),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 28)
              else
                Icon(Icons.circle_outlined, color: Colors.grey, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}