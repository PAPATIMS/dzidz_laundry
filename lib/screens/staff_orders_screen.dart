import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() =>
      _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> orders = [];

  // These values MUST match the database CHECK constraint.
  final List<String> statuses = [
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

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> loadOrders() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await supabase
          .from('laundry_orders')
          .select()
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        orders =
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
            'Unable to load orders: $e';
      });
    }
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<void> updateOrderStatus(
    Map<String, dynamic> order,
    String newStatus,
  ) async {
    final orderUuid = order['id'];

    if (orderUuid == null) {
      return;
    }

    final oldStatus =
        order['status']?.toString() ??
            'Order Received';

    if (oldStatus == newStatus) {
      return;
    }

    try {
      // --------------------------------------------------------
      // Update the laundry order first.
      // --------------------------------------------------------

      await supabase
          .from('laundry_orders')
          .update({
        'status': newStatus,
      })
          .eq(
            'id',
            orderUuid,
          );

      // --------------------------------------------------------
      // Update the local screen immediately.
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      setState(() {
        order['status'] = newStatus;
      });

      // --------------------------------------------------------
      // Create customer notification.
      //
      // IMPORTANT:
      // customer_notifications.order_id is UUID,
      // therefore we use order['id'], NOT order['order_id'].
      // --------------------------------------------------------

      await _createCustomerNotification(
        order,
        newStatus,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ${order['order_id'] ?? ''} updated to $newStatus.',
          ),
          backgroundColor:
              const Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update order status: $e',
          ),
          duration:
              const Duration(seconds: 6),
        ),
      );

      // Reload from database so the screen does not
      // remain inconsistent after an error.
      await loadOrders();
    }
  }

  // ============================================================
  // CREATE CUSTOMER NOTIFICATION
  // ============================================================

  Future<void> _createCustomerNotification(
    Map<String, dynamic> order,
    String status,
  ) async {
    final customerId =
        order['customer_id'];

    final orderUuid =
        order['id'];

    if (customerId == null ||
        orderUuid == null) {
      return;
    }

    final orderNumber =
        order['order_id']?.toString() ??
            'Unknown order';

    try {
      await supabase
          .from('customer_notifications')
          .insert({
        'customer_id': customerId,
        'order_id': orderUuid,
        'title': _notificationTitle(status),
        'message': _notificationMessage(
          orderNumber,
          status,
        ),
      });
    } catch (e) {
      // The order status has already been updated.
      // We don't want a notification problem to make
      // the staff member think the order update failed.
      debugPrint(
        'Customer notification could not be created: $e',
      );
    }
  }

  // ============================================================
  // NOTIFICATION TITLE
  // ============================================================

  String _notificationTitle(
    String status,
  ) {
    switch (status) {
      case 'Order Received':
        return 'Order Received';

      case 'Washing/Drying':
        return 'Laundry in Progress';

      case 'Ironing':
        return 'Ironing in Progress';

      case 'Quality Check':
        return 'Quality Check';

      case 'Ready':
        return 'Order Ready';

      case 'Delivered':
        return 'Order Delivered';

      default:
        return 'Order Update';
    }
  }

  // ============================================================
  // NOTIFICATION MESSAGE
  // ============================================================

  String _notificationMessage(
    String orderId,
    String status,
  ) {
    switch (status) {
      case 'Order Received':
        return 'Your laundry order $orderId has been received.';

      case 'Washing/Drying':
        return 'Your laundry order $orderId is currently being washed/dried.';

      case 'Ironing':
        return 'Your laundry order $orderId is currently being ironed.';

      case 'Quality Check':
        return 'Your laundry order $orderId is undergoing quality checks.';

      case 'Ready':
        return 'Your laundry order $orderId is ready for pickup.';

      case 'Delivered':
        return 'Your laundry order $orderId has been delivered.';

      default:
        return 'There has been an update to your laundry order $orderId.';
    }
  }

  // ============================================================
  // STATUS SELECTOR
  // ============================================================

  void showStatusSelector(
    BuildContext context,
    Map<String, dynamic> order,
  ) {
    final currentStatus =
        order['status']?.toString() ??
            'Order Received';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Order Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Order: ${order['order_id'] ?? 'Unknown'}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 16),

                ...statuses.map(
                  (status) {
                    final isCurrent =
                        status == currentStatus;

                    return ListTile(
                      leading: Icon(
                        isCurrent
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            const Color(0xFF1976D2),
                      ),

                      title: Text(
                        status,
                        style: TextStyle(
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),

                      trailing: isCurrent
                          ? const Icon(
                              Icons.check,
                              color:
                                  Color(0xFF1976D2),
                            )
                          : null,

                      onTap: isCurrent
                          ? null
                          : () async {
                              Navigator.pop(
                                sheetContext,
                              );

                              await updateOrderStatus(
                                order,
                                status,
                              );
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _orderCard(
    Map<String, dynamic> order,
  ) {
    final orderId =
        order['order_id']?.toString() ??
            'Unknown Order';

    final status =
        order['status']?.toString() ??
            'Order Received';

    final laundryTotal =
        (order['laundry_total'] as num?)
                ?.toDouble() ??
            0;

    final deliveryFee =
        (order['delivery_fee'] as num?)
                ?.toDouble() ??
            0;

    final total =
        (order['total'] as num?)
                ?.toDouble() ??
            0;

    final deliveryRequired =
        order['delivery_required'] == true;

    final createdAt =
        DateTime.tryParse(
      order['created_at']?.toString() ??
          '',
    );

    Map<String, dynamic> items = {};

    final rawItems = order['items'];

    if (rawItems is Map) {
      items = Map<String, dynamic>.from(
        rawItems,
      );
    }

    return Card(
      margin:
          const EdgeInsets.only(bottom: 18),
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // ORDER NUMBER + STATUS
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    orderId,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF1976D2),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                _statusBadge(status),
              ],
            ),

            const Divider(
              height: 25,
            ),

            // --------------------------------------------------
            // CUSTOMER
            // --------------------------------------------------

            const Text(
              'Customer',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF1976D2),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Customer ID: '
              '${order['customer_id'] ?? 'Unknown'}',
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF666666),
              ),
            ),

            const Divider(
              height: 25,
            ),

            // --------------------------------------------------
            // ITEMS
            // --------------------------------------------------

            const Text(
              'Items',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF1976D2),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            if (items.isEmpty)
              const Text(
                'No item details available.',
                style:
                    TextStyle(
                  color:
                      Color(0xFF777777),
                ),
              )
            else
              ...items.entries.map(
                (item) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 4,
                    ),
                    child: Text(
                      '${item.key} × ${item.value}',
                    ),
                  );
                },
              ),

            const Divider(
              height: 25,
            ),

            // --------------------------------------------------
            // SERVICE
            // --------------------------------------------------

            Text(
              deliveryRequired
                  ? 'Service: Delivery'
                  : 'Service: Pickup',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w500,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Laundry: GHS '
              '${laundryTotal.toStringAsFixed(2)}',
            ),

            Text(
              'Delivery: GHS '
              '${deliveryFee.toStringAsFixed(2)}',
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Total: GHS '
              '${total.toStringAsFixed(2)}',
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            // --------------------------------------------------
            // CREATED DATE
            // --------------------------------------------------

            if (createdAt != null) ...[
              const SizedBox(
                height: 8,
              ),

              Text(
                'Created: '
                '${_formatDateTime(
                  createdAt.toLocal(),
                )}',
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      Color(0xFF777777),
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            // --------------------------------------------------
            // UPDATE STATUS BUTTON
            // --------------------------------------------------

            SizedBox(
              width:
                  double.infinity,
              height: 48,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  showStatusSelector(
                    context,
                    order,
                  );
                },

                icon:
                    const Icon(
                  Icons.sync,
                ),

                label:
                    const Text(
                  'Update Status',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF42A5F5,
                  ),
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
    String status,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            _statusBackgroundColor(
          status,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style:
            TextStyle(
          color:
              _statusTextColor(
            status,
          ),
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BACKGROUND COLOR
  // ============================================================

  Color _statusBackgroundColor(
    String status,
  ) {
    switch (status) {
      case 'Order Received':
        return const Color(
          0xFFE3F2FD,
        );

      case 'Washing/Drying':
        return const Color(
          0xFFE8F5E9,
        );

      case 'Ironing':
        return const Color(
          0xFFFFF3E0,
        );

      case 'Quality Check':
        return const Color(
          0xFFF3E5F5,
        );

      case 'Ready':
        return const Color(
          0xFFE0F2F1,
        );

      case 'Delivered':
        return const Color(
          0xFFE8F5E9,
        );

      default:
        return const Color(
          0xFFE3F2FD,
        );
    }
  }

  // ============================================================
  // STATUS TEXT COLOR
  // ============================================================

  Color _statusTextColor(
    String status,
  ) {
    switch (status) {
      case 'Order Received':
        return const Color(
          0xFF1976D2,
        );

      case 'Washing/Drying':
        return const Color(
          0xFF2E7D32,
        );

      case 'Ironing':
        return const Color(
          0xFFE65100,
        );

      case 'Quality Check':
        return const Color(
          0xFF7B1FA2,
        );

      case 'Ready':
        return const Color(
          0xFF00695C,
        );

      case 'Delivered':
        return const Color(
          0xFF2E7D32,
        );

      default:
        return const Color(
          0xFF1976D2,
        );
    }
  }

  // ============================================================
  // FORMAT DATE/TIME
  // ============================================================

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final day =
        dateTime.day
            .toString()
            .padLeft(2, '0');

    final month =
        dateTime.month
            .toString()
            .padLeft(2, '0');

    final year =
        dateTime.year.toString();

    final hour =
        dateTime.hour == 0
            ? 12
            : dateTime.hour > 12
                ? dateTime.hour - 12
                : dateTime.hour;

    final minute =
        dateTime.minute
            .toString()
            .padLeft(2, '0');

    final period =
        dateTime.hour >= 12
            ? 'PM'
            : 'AM';

    return '$day/$month/$year '
        '$hour:$minute $period';
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFF42A5F5),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color:
                    Colors.redAccent,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton.icon(
                onPressed:
                    loadOrders,
                icon:
                    const Icon(
                  Icons.refresh,
                ),
                label:
                    const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh:
            loadOrders,
        child:
            ListView(
          children: const [
            SizedBox(
              height: 180,
            ),

            Icon(
              Icons.inventory_2_outlined,
              size: 75,
              color:
                  Color(0xFF90CAF9),
            ),

            SizedBox(
              height: 20,
            ),

            Center(
              child: Text(
                'No orders yet.',
                style:
                    TextStyle(
                  fontSize: 19,
                  color:
                      Color(0xFF666666),
                ),
              ),
            ),

            SizedBox(
              height: 10,
            ),

            Center(
              child: Text(
                'Customer orders will appear here.',
                style:
                    TextStyle(
                  color:
                      Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          loadOrders,
      child:
          ListView.builder(
        padding:
            const EdgeInsets.all(20),
        itemCount:
            orders.length,
        itemBuilder:
            (context, index) {
          return _orderCard(
            orders[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF9F9F4),

      appBar:
          AppBar(
        title:
            const Text(
          'Manage Orders',
        ),

        backgroundColor:
            const Color(
          0xFF42A5F5,
        ),

        foregroundColor:
            Colors.white,

        elevation: 0,

        actions: [
          IconButton(
            tooltip:
                'Refresh',
            onPressed:
                isLoading
                    ? null
                    : loadOrders,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          _buildBody(),
    );
  }
}