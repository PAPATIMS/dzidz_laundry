import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/laundry_order.dart';
import 'order_tracking_screen.dart';

class CurrentOrdersScreen extends StatefulWidget {
  const CurrentOrdersScreen({super.key});

  @override
  State<CurrentOrdersScreen> createState() => _CurrentOrdersScreenState();
}

class _CurrentOrdersScreenState extends State<CurrentOrdersScreen> {
  final supabase = Supabase.instance.client;

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
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'You are not logged in. Please login again.';
        });
        return;
      }

      final customer = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();

      final customerId = customer['id'];

      final response = await supabase
          .from('laundry_orders')
          .select()
          .eq('customer_id', customerId)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('My Current Orders'),
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
                    Icons.local_laundry_service_outlined,
                    size: 65,
                    color: Color(0xFF90CAF9),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'You currently have no orders.',
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
          final order = orders[index];
          return _orderCard(order);
        },
      ),
    );
  }

  Widget _orderCard(LaundryOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(
                order: order,
              ),
            ),
          );
        },
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              ...order.items.entries.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '${item.key} × ${item.value}',
                  ),
                ),
              ),

              const Divider(height: 25),

              Text(
                order.deliveryRequired
                    ? 'Service: Delivery'
                    : 'Service: Pickup',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Total: GHS ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Tap to track order',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF1976D2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}