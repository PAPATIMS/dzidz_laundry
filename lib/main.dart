
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'config/supabase_test.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/staff_login_screen.dart';
import 'screens/customer_dashboard.dart';
import 'screens/staff_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const DzidzLaundryApp());
}

class DzidzLaundryApp extends StatelessWidget {
  const DzidzLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dzidz Laundry Services',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF9F9F4),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  Widget? destination;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        supabase.auth.onAuthStateChange.listen((data) {
      _handleSession(data.session);
    });

    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final session = supabase.auth.currentSession;

    await _handleSession(session);
  }

  Future<void> _handleSession(Session? session) async {
    if (!mounted) {
      return;
    }

    // No active session means the user is logged out.
    if (session == null) {
      setState(() {
        destination = const WelcomeScreen();
        loading = false;
      });

      return;
    }

    final user = session.user;

    try {
      // Check whether this authenticated user is a staff member.
      final staff = await supabase
          .from('staff_users')
          .select('id, email, role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) {
        return;
      }

      if (staff != null) {
        setState(() {
          destination = const StaffDashboard();
          loading = false;
        });

        return;
      }

      // Authenticated user is a customer.
      setState(() {
        destination = CustomerDashboard(
          customerEmail: user.email ?? '',
        );
        loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      // If the staff lookup fails, keep the valid
      // authentication session and treat the user as a customer.
      setState(() {
        destination = CustomerDashboard(
          customerEmail: user.email ?? '',
        );
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9F4),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF42A5F5),
          ),
        ),
      );
    }

    return destination ?? const WelcomeScreen();
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Dzidz Laundry Services'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.local_laundry_service,
                  size: 90,
                  color: Color(0xFF42A5F5),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Welcome to Dzidz Laundry',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Professional Laundry Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegisterScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const LoginScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(
                        color: Color(0xFF42A5F5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton(
                    onPressed: () async {
                      final result =
                          await SupabaseTest.testConnection();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result),
                        ),
                      );
                    },
                    child: const Text(
                      'Test Database Connection',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StaffLoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.admin_panel_settings,
                    ),
                    label: const Text(
                      'Staff Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
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
