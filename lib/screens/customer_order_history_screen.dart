import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerOrderHistoryScreen extends StatefulWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  State<CustomerOrderHistoryScreen> createState() =>
      _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState
    extends State<CustomerOrderHistoryScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> orders = [];

  // Only delivered orders are considered completed order history.
  static const List<String> completedStatuses = [
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    loadOrderHistory();
  }

  Future<void> loadOrderHistory() async {
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
          .from('laundry_orders')
          .select()
          .eq('customer_id', customerId)
          .inFilter('status', completedStatuses)
          .order('created_at', ascending: false);

      if (!mounted) {
        return;
      }

      setState(() {
        orders = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load order history: $e';
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return const Color(0xFF2E7D32);

      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.done_all;

      default:
        return Icons.info_outline;
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

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour == 0
        ? 12
        : localDate.hour > 12
            ? localDate.hour - 12
            : localDate.hour;

    final minute = localDate.minute.toString().padLeft(2, '0');

    final period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId =
        order['order_id']?.toString() ?? 'Unknown order';

    final status =
        order['status']?.toString() ?? 'Unknown';

    final laundryTotal =
        (order['laundry_total'] as num?)?.toDouble() ?? 0;

    final deliveryFee =
        (order['delivery_fee'] as num?)?.toDouble() ?? 0;

    final total =
        (order['total'] as num?)?.toDouble() ?? 0;

    final deliveryRequired =
        order['delivery_required'] == true;

    final items = Map<String, dynamic>.from(
      order['items'] ?? {},
    );

    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _formatDate(
                          order['created_at']?.toString(),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 16,
                        color: statusColor,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            const Text(
              'Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 8),

            if (items.isEmpty)
              const Text(
                'No item details available.',
                style: TextStyle(
                  color: Color(0xFF777777),
                ),
              )
            else
              ...items.entries.map(
                (item) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 5),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),

                      Text(
                        '× ${item.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service',
                  style: TextStyle(
                    color: Color(0xFF666666),
                  ),
                ),

                Text(
                  deliveryRequired
                      ? 'Delivery'
                      : 'Pickup',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Laundry',
                  style: TextStyle(
                    color: Color(0xFF666666),
                  ),
                ),

                Text(
                  'GHS ${laundryTotal.toStringAsFixed(2)}',
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery',
                  style: TextStyle(
                    color: Color(0xFF666666),
                  ),
                ),

                Text(
                  'GHS ${deliveryFee.toStringAsFixed(2)}',
                ),
              ],
            ),

            const Divider(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'GHS ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ],
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
                onPressed: loadOrderHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadOrderHistory,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),

            Icon(
              Icons.history,
              size: 75,
              color: Color(0xFF90CAF9),
            ),

            SizedBox(height: 20),

            Center(
              child: Text(
                'You do not have any delivered orders yet.',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 10),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Text(
                'Your completed laundry orders will appear here after delivery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadOrderHistory,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(
            orders[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),

      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            tooltip: 'Refresh order history',
            onPressed:
                isLoading ? null : loadOrderHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }
}