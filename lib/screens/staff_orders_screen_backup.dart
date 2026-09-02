import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/laundry_order.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  final supabase = Supabase.instance.client;

  static const List<String> statuses = [
    'Order Received',
    'Washing/Drying',
    'Ironing',
    'Quality Check',
    'Ready',
    'Out for Delivery',
    'Delivered',
  ];

  bool isLoading = true;
  String? errorMessage;
  List<LaundryOrder> orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await supabase
          .from('laundry_orders')
          .select()
          .order('created_at', ascending: false);

      final loadedOrders = (response as List)
          .map(
            (row) => LaundryOrder(
              orderId: row['order_id'].toString(),
              items: Map<String, int>.from(
                (row['items'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    (value as num).toInt(),
                  ),
                ),
              ),
              laundryTotal:
                  (row['laundry_total'] as num).toDouble(),
              deliveryFee:
                  (row['delivery_fee'] as num).toDouble(),
              total: (row['total'] as num).toDouble(),
              deliveryRequired:
                  row['delivery_required'] as bool,
              status: row['status'].toString(),
              createdAt: DateTime.parse(
                row['created_at'].toString(),
              ),
            ),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        orders = loadedOrders;
        isLoading = false;
        errorMessage = null;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Database error: ${error.message}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load orders: $error';
      });
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await _loadOrders();
  }

  Future<void> _updateOrderStatus(
    LaundryOrder order,
    String newStatus,
  ) async {
    final oldStatus = order.status;

    setState(() {
      order.status = newStatus;
    });

    try {
      await supabase
          .from('laundry_orders')
          .update({
            'status': newStatus,
          })
          .eq('order_id', order.orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${order.orderId} updated to $newStatus.',
          ),
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      setState(() {
        order.status = oldStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Database error: ${error.message}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        order.status = oldStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update order: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Staff - Orders'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isLoading ? null : _refreshOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh orders',
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
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 15),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refreshOrders,
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
        onRefresh: _refreshOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 65,
                    color: Color(0xFF90CAF9),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No orders available.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _orderCard(orders[index]);
        },
      ),
    );
  }

  Widget _orderCard(LaundryOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.orderId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _statusBadge(order.status),
              ],
            ),

            const SizedBox(height: 15),

            const Text(
              'Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            ...order.items.entries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${item.key} × ${item.value}',
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              order.deliveryRequired
                  ? 'Service: Delivery'
                  : 'Service: Pickup',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Laundry: GHS ${order.laundryTotal.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 4),

            Text(
              'Delivery: GHS ${order.deliveryFee.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 6),

            Text(
              'Total: GHS ${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Update Order Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: statuses.contains(order.status)
                  ? order.status
                  : statuses.first,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: statuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (newStatus) {
                if (newStatus == null ||
                    newStatus == order.status) {
                  return;
                }

                _updateOrderStatus(
                  order,
                  newStatus,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
