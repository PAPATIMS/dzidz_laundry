import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerOrderTrackingScreen extends StatefulWidget {
  const CustomerOrderTrackingScreen({super.key});

  @override
  State<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState
    extends State<CustomerOrderTrackingScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> orders = [];

  // These values MUST match the database constraint.
  static const List<String> statuses = [
    'Order Received',
    'Washing/Drying',
    'Ironing',
    'Quality Check',
    'Ready',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

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
        errorMessage = 'Unable to load your orders: $e';
      });
    }
  }

  int _statusIndex(String status) {
    final index = statuses.indexOf(status);

    if (index == -1) {
      return 0;
    }

    return index;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Order Received':
        return const Color(0xFF1976D2);

      case 'Washing/Drying':
        return const Color(0xFF0288D1);

      case 'Ironing':
        return const Color(0xFF7B1FA2);

      case 'Quality Check':
        return const Color(0xFFEF6C00);

      case 'Ready':
        return const Color(0xFF388E3C);

      case 'Delivered':
        return const Color(0xFF2E7D32);

      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Order Received':
        return Icons.receipt_long;

      case 'Washing/Drying':
        return Icons.local_laundry_service;

      case 'Ironing':
        return Icons.iron;

      case 'Quality Check':
        return Icons.verified;

      case 'Ready':
        return Icons.inventory_2;

      case 'Delivered':
        return Icons.home;

      default:
        return Icons.local_laundry_service;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'Order Received':
        return 'Your order has been received by Dzidz Laundry and is waiting to be processed.';

      case 'Washing/Drying':
        return 'Your clothes are currently being washed and dried.';

      case 'Ironing':
        return 'Your clothes are currently being ironed and prepared.';

      case 'Quality Check':
        return 'Your order is being checked carefully to ensure everything meets our quality standards.';

      case 'Ready':
        return 'Your laundry is ready for pickup or delivery.';

      case 'Delivered':
        return 'Your laundry has been delivered successfully. Thank you for choosing Dzidz Laundry!';

      default:
        return 'Your order is currently being processed.';
    }
  }

  Widget _buildProgress(String currentStatus) {
    final currentIndex = _statusIndex(currentStatus);

    return Column(
      children: [
        for (int i = 0; i < statuses.length; i++)
          _buildProgressStep(
            status: statuses[i],
            isCompleted: i < currentIndex,
            isCurrent: i == currentIndex,
            isLast: i == statuses.length - 1,
          ),
      ],
    );
  }

  Widget _buildProgressStep({
    required String status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final active = isCompleted || isCurrent;

    final color = active
        ? _statusColor(status)
        : const Color(0xFFBDBDBD);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? color
                    : const Color(0xFFE0E0E0),
                border: isCurrent
                    ? Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 4,
                      )
                    : null,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : _statusIcon(status),
                size: isCompleted ? 20 : 19,
                color: active
                    ? Colors.white
                    : const Color(0xFF9E9E9E),
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 55,
                color: isCompleted
                    ? _statusColor(status)
                    : const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isCurrent
                        ? color
                        : const Color(0xFF555555),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 5),
                  Text(
                    _statusDescription(status),
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Color(0xFF777777),
                    ),
                  ),
                ],
                if (!isCurrent)
                  const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(String status) {
    final color = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(status),
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId =
        order['order_id']?.toString() ?? 'Unknown Order';

    final status =
        order['status']?.toString() ?? 'Order Received';

    final total =
        (order['total'] as num?)?.toDouble() ?? 0;

    final laundryTotal =
        (order['laundry_total'] as num?)?.toDouble() ?? 0;

    final deliveryFee =
        (order['delivery_fee'] as num?)?.toDouble() ?? 0;

    final deliveryRequired =
        order['delivery_required'] == true;

    final createdAt = DateTime.tryParse(
      order['created_at']?.toString() ?? '',
    );

    final items = Map<String, dynamic>.from(
      order['items'] ?? {},
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    orderId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Created: ${createdAt.toLocal()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                ),
              ),
            ],

            const Divider(height: 28),

            _buildStatusHeader(status),

            const SizedBox(height: 22),

            const Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 14),

            _buildProgress(status),

            const Divider(height: 28),

            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 12),

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
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
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

            const SizedBox(height: 8),
            const Divider(),

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

            const SizedBox(height: 7),

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

            const SizedBox(height: 7),

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

            const Divider(height: 25),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'GHS ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
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
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: loadOrders,
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
        onRefresh: loadOrders,
        child: ListView(
          children: const [
            SizedBox(height: 170),
            Icon(
              Icons.track_changes,
              size: 75,
              color: Color(0xFF90CAF9),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'You do not have any orders yet.',
                style: TextStyle(
                  fontSize: 18,
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
                  'Your laundry order progress will appear here.',
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
      onRefresh: loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Track My Orders'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: isLoading ? null : loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}