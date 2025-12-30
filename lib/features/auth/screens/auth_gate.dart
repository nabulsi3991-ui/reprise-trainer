import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:reprise/features/auth/screens/loading_screen.dart';
import 'package:reprise/features/auth/screens/login_screen.dart';
import 'package:reprise/features/user/providers/user_provider.dart';
import 'package:reprise/shared/widgets/main_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance. authStateChanges(),
      builder: (context, snapshot) {
        // ✅ Loading state - Show beautiful loading screen
        if (snapshot. connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // Not logged in → Show login screen
        if (! snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Logged in → Load user data and show main app
        return Consumer<UserProvider>(
          builder:  (context, userProvider, child) {
            // ✅ Loading user profile - Show beautiful loading screen
            if (userProvider.isLoading || !userProvider.isInitialized) {
              return const LoadingScreen();
            }

            // User data loaded but user is null
            if (userProvider.currentUser == null) {
              return const LoadingScreen();
            }

            // Everything is good → Show main app
            return const MainNavigation();
          },
        );
      },
    );
  }
}