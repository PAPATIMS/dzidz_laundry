import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> orders = [];

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
        if (!mounted) return;

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
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = 'Customer profile not found.';
        });

        return;
      }

      final customerId = customer['id'];

      final response = await supabase
          .from('laundry_orders')
          .select()
          .eq('customer_id', customerId)
          .eq('status', 'Delivered')
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

  Future<Map<String, dynamic>> getPaymentSummary(
    String orderUuid,
    double orderTotal,
  ) async {
    try {
      final response = await supabase
          .from('order_payments')
          .select(
            'id, amount, payment_method, payment_reference, '
            'payment_status, notes, paid_at, created_at',
          )
          .eq('order_id', orderUuid)
          .order('paid_at', ascending: false);

      final payments =
          List<Map<String, dynamic>>.from(response);

      double totalPaid = 0;

      for (final payment in payments) {
        final paymentStatus =
            payment['payment_status']?.toString() ?? '';

        if (paymentStatus == 'Completed') {
          totalPaid +=
              (payment['amount'] as num?)?.toDouble() ?? 0;
        }
      }

      final balance = orderTotal - totalPaid;

      return {
        'payments': payments,
        'totalPaid': totalPaid,
        'balance': balance < 0 ? 0 : balance,
      };
    } catch (e) {
      return {
        'payments': <Map<String, dynamic>>[],
        'totalPaid': 0.0,
        'balance': orderTotal,
      };
    }
  }

  void openOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _HistoryOrderDetailsDialog(
          order: order,
          getPaymentSummary: getPaymentSummary,
        );
      },
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
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadOrderHistory,
            icon: const Icon(Icons.refresh),
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
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.history,
              size: 70,
              color: Color(0xFF90CAF9),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No completed orders yet.',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Your delivered orders will appear here.',
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
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _orderCard(orders[index]);
        },
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final orderUuid =
        order['id']?.toString() ?? '';

    final orderId =
        order['order_id']?.toString() ?? 'Unknown Order';

    final status =
        order['status']?.toString() ?? 'Delivered';

    final total =
        (order['total'] as num?)?.toDouble() ?? 0;

    final deliveryRequired =
        order['delivery_required'] == true;

    final createdAt = DateTime.tryParse(
      order['created_at']?.toString() ?? '',
    );

    final items = Map<String, dynamic>.from(
      order['items'] ?? {},
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: getPaymentSummary(orderUuid, total),
      builder: (context, snapshot) {
        final summary =
            snapshot.data ??
            {
              'totalPaid': 0.0,
              'balance': total,
              'payments': <Map<String, dynamic>>[],
            };

        final totalPaid =
            (summary['totalPaid'] as num?)?.toDouble() ?? 0;

        final balance =
            (summary['balance'] as num?)?.toDouble() ?? total;

        final fullyPaid = balance <= 0.01;

        return Card(
          margin: const EdgeInsets.only(bottom: 18),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openOrderDetails(order),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          orderId,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),

                  const Divider(height: 25),

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
                            const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${item.key} × ${item.value}',
                        ),
                      ),
                    ),

                  const Divider(height: 25),

                  Text(
                    deliveryRequired
                        ? 'Service: Delivery'
                        : 'Service: Pickup',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Order Total: GHS '
                    '${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fullyPaid
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _paymentRow(
                          'Total Paid',
                          'GHS ${totalPaid.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 6),
                        _paymentRow(
                          'Balance',
                          'GHS ${balance.toStringAsFixed(2)}',
                          valueColor: fullyPaid
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                        const SizedBox(height: 6),
                        _paymentRow(
                          'Payment Status',
                          fullyPaid
                              ? 'FULLY PAID'
                              : 'PARTIALLY PAID',
                          valueColor: fullyPaid
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                      ],
                    ),
                  ),

                  if (createdAt != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Created: ${_formatDateTime(createdAt.toLocal())}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 18,
                        color: Color(0xFF777777),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Tap order to view payment details',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _paymentRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF333333),
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF555555),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day =
        dateTime.day.toString().padLeft(2, '0');

    final month =
        dateTime.month.toString().padLeft(2, '0');

    final year = dateTime.year.toString();

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }
}

class _HistoryOrderDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> order;

  final Future<Map<String, dynamic>> Function(
    String,
    double,
  ) getPaymentSummary;

  const _HistoryOrderDetailsDialog({
    required this.order,
    required this.getPaymentSummary,
  });

  @override
  State<_HistoryOrderDetailsDialog> createState() =>
      _HistoryOrderDetailsDialogState();
}

class _HistoryOrderDetailsDialogState
    extends State<_HistoryOrderDetailsDialog> {
  bool isLoading = true;

  List<Map<String, dynamic>> payments = [];

  double totalPaid = 0;

  double balance = 0;

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    final orderUuid =
        widget.order['id']?.toString() ?? '';

    final total =
        (widget.order['total'] as num?)?.toDouble() ?? 0;

    final summary =
        await widget.getPaymentSummary(
      orderUuid,
      total,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      payments =
          List<Map<String, dynamic>>.from(
        summary['payments'] ?? [],
      );

      totalPaid =
          (summary['totalPaid'] as num?)?.toDouble() ?? 0;

      balance =
          (summary['balance'] as num?)?.toDouble() ?? total;

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderId =
        widget.order['order_id']?.toString() ??
            'Unknown Order';

    final status =
        widget.order['status']?.toString() ??
            'Delivered';

    final total =
        (widget.order['total'] as num?)?.toDouble() ?? 0;

    final laundryTotal =
        (widget.order['laundry_total'] as num?)
                ?.toDouble() ??
            0;

    final deliveryFee =
        (widget.order['delivery_fee'] as num?)
                ?.toDouble() ??
            0;

    final deliveryRequired =
        widget.order['delivery_required'] == true;

    final items = Map<String, dynamic>.from(
      widget.order['items'] ?? {},
    );

    final fullyPaid = balance <= 0.01;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.receipt_long,
            color: Color(0xFF1976D2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              orderId,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _sectionTitle('Order Status'),

              const SizedBox(height: 7),

              _statusPill(status),

              const SizedBox(height: 20),

              _sectionTitle('Items'),

              const SizedBox(height: 8),

              if (items.isEmpty)
                const Text(
                  'No item details available.',
                )
              else
                ...items.entries.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 5),
                    child: Text(
                      '${item.key} × ${item.value}',
                    ),
                  ),
                ),

              const Divider(height: 25),

              _sectionTitle('Service'),

              const SizedBox(height: 8),

              Text(
                deliveryRequired
                    ? 'Delivery'
                    : 'Pickup',
              ),

              const SizedBox(height: 18),

              _sectionTitle('Payment Summary'),

              const SizedBox(height: 10),

              _summaryRow(
                'Order Total',
                'GHS ${total.toStringAsFixed(2)}',
              ),

              _summaryRow(
                'Laundry',
                'GHS ${laundryTotal.toStringAsFixed(2)}',
              ),

              _summaryRow(
                'Delivery',
                'GHS ${deliveryFee.toStringAsFixed(2)}',
              ),

              const Divider(height: 20),

              _summaryRow(
                'Total Paid',
                'GHS ${totalPaid.toStringAsFixed(2)}',
                valueColor:
                    const Color(0xFF2E7D32),
              ),

              _summaryRow(
                'Balance',
                'GHS ${balance.toStringAsFixed(2)}',
                valueColor: fullyPaid
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFE65100),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: fullyPaid
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  fullyPaid
                      ? 'FULLY PAID'
                      : 'PARTIALLY PAID',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fullyPaid
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _sectionTitle('Payment History'),

              const SizedBox(height: 10),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                )
              else if (payments.isEmpty)
                const Text(
                  'No payment records found.',
                  style: TextStyle(
                    color: Color(0xFF777777),
                  ),
                )
              else
                ...payments.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final payment = entry.value;

                    final amount =
                        (payment['amount'] as num?)
                                ?.toDouble() ??
                            0;

                    final method =
                        payment['payment_method']
                                ?.toString() ??
                            'Not specified';

                    final reference =
                        payment['payment_reference']
                                ?.toString() ??
                            '';

                    final paidAt =
                        DateTime.tryParse(
                      payment['paid_at']
                              ?.toString() ??
                          '',
                    );

                    return Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF5F9FC),
                        borderRadius:
                            BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                'Payment ${payments.length - index}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF1976D2),
                                ),
                              ),
                              Text(
                                'GHS ${amount.toStringAsFixed(2)}',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Method: $method',
                            style:
                                const TextStyle(
                              fontSize: 13,
                            ),
                          ),

                          if (reference.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reference: $reference',
                              style:
                                  const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],

                          if (paidAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Paid: ${_formatDateTime(paidAt.toLocal())}',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color:
                                    Color(0xFF777777),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1976D2),
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color valueColor =
        const Color(0xFF333333),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555555),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day =
        dateTime.day.toString().padLeft(2, '0');

    final month =
        dateTime.month.toString().padLeft(2, '0');

    final year = dateTime.year.toString();

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }
}