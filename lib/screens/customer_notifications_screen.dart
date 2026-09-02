import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
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
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('You are not logged in.');
      }

      final customerResponse = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (customerResponse == null) {
        throw Exception('Customer profile could not be found.');
      }

      final customerId = customerResponse['id'];

      final response = await supabase
          .from('customer_notifications')
          .select(
            'id, customer_id, order_id, title, message, '
            'is_read, created_at',
          )
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
        errorMessage =
            'Unable to load notifications: $e';
      });
    }
  }

  Future<void> markAsRead(
    Map<String, dynamic> notification,
  ) async {
    final notificationId = notification['id'];

    if (notificationId == null ||
        notification['is_read'] == true) {
      return;
    }

    try {
      await supabase
          .from('customer_notifications')
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
    final unreadNotifications = notifications
        .where(
          (notification) =>
              notification['is_read'] != true,
        )
        .toList();

    if (unreadNotifications.isEmpty) {
      return;
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final customerResponse = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (customerResponse == null) {
        return;
      }

      final customerId = customerResponse['id'];

      await supabase
          .from('customer_notifications')
          .update({
            'is_read': true,
          })
          .eq('customer_id', customerId)
          .eq('is_read', false);

      if (!mounted) {
        return;
      }

      setState(() {
        for (final notification
            in notifications) {
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

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Unknown date';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Unknown date';
    }

    final localDate = date.toLocal();

    final day =
        localDate.day.toString().padLeft(2, '0');

    final month =
        localDate.month.toString().padLeft(2, '0');

    final year =
        localDate.year.toString();

    final hour = localDate.hour == 0
        ? 12
        : localDate.hour > 12
            ? localDate.hour - 12
            : localDate.hour;

    final minute =
        localDate.minute.toString().padLeft(2, '0');

    final period =
        localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year '
        '$hour:$minute $period';
  }

  Widget _notificationCard(
    Map<String, dynamic> notification,
  ) {
    final title =
        notification['title']?.toString() ??
            'Notification';

    final message =
        notification['message']?.toString() ??
            '';

    final orderUuid =
        notification['order_id'];

    final isRead =
        notification['is_read'] == true;

    final createdAt =
        notification['created_at']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isRead ? 1 : 3,
      color: isRead
          ? Colors.white
          : const Color(0xFFEAF5FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isRead
            ? BorderSide.none
            : const BorderSide(
                color: Color(0xFF90CAF9),
                width: 1,
              ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => markAsRead(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1976D2),
                  size: 27,
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
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(0xFF1976D2),
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
                        color: Color(0xFF555555),
                      ),
                    ),

                    if (orderUuid != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Order notification',
                        style: TextStyle(
                          fontSize: 12,
                          color: isRead
                              ? const Color(0xFF888888)
                              : const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

              const SizedBox(height: 15),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 15),

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
                'You do not have any notifications yet.',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where(
          (notification) =>
              notification['is_read'] != true,
        )
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),

      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          IconButton(
            tooltip: 'Refresh notifications',
            onPressed:
                isLoading ? null : loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
}