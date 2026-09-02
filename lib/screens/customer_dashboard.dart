import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'new_laundry_order.dart';
import 'current_orders_screen.dart';
import 'customer_order_tracking_screen.dart';
import 'order_history_screen.dart';
import 'notifications_screen.dart';
import 'customer_profile_screen.dart';
import 'payment_screen.dart';

class CustomerDashboard extends StatefulWidget {
  final String customerEmail;

  const CustomerDashboard({
    super.key,
    required this.customerEmail,
  });

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  bool isLoggingOut = false;

  Future<void> _logout() async {
    if (isLoggingOut) {
      return;
    }

    setState(() {
      isLoggingOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } on TimeoutException {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Logout is taking too long. Please check your connection and try again.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to logout. Please try again: $e',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Dzidz Laundry'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back 👋🏽',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              widget.customerEmail,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),

            const SizedBox(height: 25),

            _dashboardCard(
              context,
              icon: Icons.local_laundry_service,
              title: 'New Laundry Order',
              subtitle: 'Create a new laundry order',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewLaundryOrder(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _dashboardCard(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'My Current Orders',
              subtitle: 'View your active laundry orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CurrentOrdersScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _dashboardCard(
              context,
              icon: Icons.track_changes,
              title: 'Track Order',
              subtitle: 'Check the progress of your laundry',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CustomerOrderTrackingScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _dashboardCard(
              context,
              icon: Icons.history,
              title: 'Order History',
              subtitle: 'View your previous orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _dashboardCard(
              context,
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: 'View your latest updates',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const NotificationsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _dashboardCard(
              context,
              icon: Icons.person_outline,
              title: 'My Profile',
              subtitle: 'Manage your account information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CustomerProfileScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _dashboardCard(
              context,
              icon: Icons.payment_outlined,
              title: 'Payments',
              subtitle: 'View your payment information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PaymentScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isLoggingOut ? null : _logout,
                icon: isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  isLoggingOut ? 'Logging out...' : 'Logout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1976D2),
                  side: const BorderSide(
                    color: Color(0xFF42A5F5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1976D2),
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}