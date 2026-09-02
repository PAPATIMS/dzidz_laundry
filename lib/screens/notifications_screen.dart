import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
          errorMessage = 'You are not logged in.';
        });

        return;
      }

      final customer = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (customer == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
          errorMessage = 'Customer profile not found.';
        });

        return;
      }

      final customerId = customer['id'];

      final response = await supabase
          .from('notifications')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      if (!mounted) {
        return;
      }

      setState(() {
        notifications =
            List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load notifications: $e';
      });
    }
  }

  Future<void> markAsRead(
    Map<String, dynamic> notification,
  ) async {
    final notificationId = notification['id'];

    if (notificationId == null) {
      return;
    }

    try {
      await supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('id', notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        notification['is_read'] = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark notification as read: $e',
          ),
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final customer = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (customer == null) {
        return;
      }

      await supabase
          .from('notifications')
          .update({
            'is_read': true,
          })
          .eq('customer_id', customer['id']);

      if (!mounted) {
        return;
      }

      setState(() {
        for (final notification in notifications) {
          notification['is_read'] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All notifications marked as read.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark notifications as read: $e',
          ),
        ),
      );
    }
  }

  IconData _notificationIcon(String title) {
    final status = title.toLowerCase();

    if (status.contains('received')) {
      return Icons.inbox_outlined;
    }

    if (status.contains('washing') ||
        status.contains('drying')) {
      return Icons.local_laundry_service;
    }

    if (status.contains('ironing')) {
      return Icons.iron_outlined;
    }

    if (status.contains('quality')) {
      return Icons.verified_outlined;
    }

    if (status.contains('ready')) {
      return Icons.check_circle_outline;
    }

    if (status.contains('delivered')) {
      return Icons.local_shipping_outlined;
    }

    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((notification) {
      return notification['is_read'] != true;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: markAllAsRead,
              icon: const Icon(
                Icons.done_all,
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadNotifications,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF42A5F5),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.notifications_none,
              size: 75,
              color: Color(0xFF90CAF9),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                  fontSize: 19,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  'Updates about your laundry orders will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _notificationCard(
            notifications[index],
          );
        },
      ),
    );
  }

  Widget _notificationCard(
    Map<String, dynamic> notification,
  ) {
    final title =
        notification['title']?.toString() ??
        'Dzidz Laundry Update';

    final message =
        notification['message']?.toString() ??
        'You have a new laundry update.';

    final orderId =
        notification['order_id']?.toString();

    final isRead =
        notification['is_read'] == true;

    final createdAt = DateTime.tryParse(
      notification['created_at']?.toString() ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!isRead) {
            markAsRead(notification);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isRead
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFBBDEFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _notificationIcon(title),
                  color: const Color(0xFF1976D2),
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: const Color(0xFF1976D2),
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration:
                                const BoxDecoration(
                              color: Color(0xFF1976D2),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444444),
                      ),
                    ),

                    if (orderId != null &&
                        orderId.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Order: $orderId',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],

                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(
                          createdAt.toLocal(),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day
        .toString()
        .padLeft(2, '0');

    final month = dateTime.month
        .toString()
        .padLeft(2, '0');

    final year = dateTime.year.toString();

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final minute = dateTime.minute
        .toString()
        .padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }
}