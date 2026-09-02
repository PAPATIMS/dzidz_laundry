import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> orders = [];
  Map<String, List<Map<String, dynamic>>> paymentHistory = {};

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
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

      final customer = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (customer == null) {
        throw Exception('Customer profile not found.');
      }

      final customerId = customer['id'];

      final orderResponse = await supabase
          .from('laundry_orders')
          .select(
            'id, order_id, total, payment_status, '
            'payment_method, payment_reference, paid_at, created_at',
          )
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final loadedOrders =
          List<Map<String, dynamic>>.from(orderResponse);

      final orderIds = loadedOrders
          .map((order) => order['id'])
          .where((id) => id != null)
          .toList();

      Map<String, List<Map<String, dynamic>>> loadedHistory = {};

      if (orderIds.isNotEmpty) {
        final paymentResponse = await supabase
            .from('order_payments')
            .select(
              'id, order_id, amount, payment_method, '
              'payment_reference, payment_status, notes, '
              'paid_at, created_at',
            )
            .inFilter('order_id', orderIds)
            .order('paid_at', ascending: false);

        final payments =
            List<Map<String, dynamic>>.from(paymentResponse);

        for (final payment in payments) {
          final orderId = payment['order_id']?.toString();

          if (orderId == null) {
            continue;
          }

          loadedHistory.putIfAbsent(
            orderId,
            () => [],
          );

          loadedHistory[orderId]!.add(payment);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        orders = loadedOrders;
        paymentHistory = loadedHistory;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load payment information: $e';
      });
    }
  }

  double _orderTotal(Map<String, dynamic> order) {
    return (order['total'] as num?)?.toDouble() ?? 0;
  }

  double _totalPaid(Map<String, dynamic> order) {
    final orderUuid = order['id']?.toString();

    if (orderUuid == null) {
      return 0;
    }

    final payments = paymentHistory[orderUuid] ?? [];

    double totalPaid = 0;

    for (final payment in payments) {
      final status =
          payment['payment_status']?.toString() ?? '';

      if (status == 'Completed') {
        totalPaid +=
            (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return totalPaid;
  }

  double _balanceDue(Map<String, dynamic> order) {
    final balance =
        _orderTotal(order) - _totalPaid(order);

    if (balance < 0) {
      return 0;
    }

    return balance;
  }

  String _displayPaymentStatus(
    Map<String, dynamic> order,
  ) {
    final total = _orderTotal(order);
    final paid = _totalPaid(order);

    if (paid >= total && total > 0) {
      return 'Paid';
    }

    if (paid > 0 && paid < total) {
      return 'Partially Paid';
    }

    final originalStatus =
        order['payment_status']?.toString() ?? 'Pending';

    if (originalStatus == 'Failed') {
      return 'Failed';
    }

    if (originalStatus == 'Refunded') {
      return 'Refunded';
    }

    return 'Pending';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFF2E7D32);

      case 'Partially Paid':
        return const Color(0xFFEF6C00);

      case 'Failed':
        return const Color(0xFFC62828);

      case 'Refunded':
        return const Color(0xFF6A1B9A);

      case 'Pending':
      default:
        return const Color(0xFF757575);
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status) {
      case 'Paid':
        return const Color(0xFFE8F5E9);

      case 'Partially Paid':
        return const Color(0xFFFFF3E0);

      case 'Failed':
        return const Color(0xFFFFEBEE);

      case 'Refunded':
        return const Color(0xFFF3E5F5);

      case 'Pending':
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Paid':
        return Icons.check_circle;

      case 'Partially Paid':
        return Icons.account_balance_wallet;

      case 'Failed':
        return Icons.cancel;

      case 'Refunded':
        return Icons.replay;

      case 'Pending':
      default:
        return Icons.pending;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    final background = _statusBackgroundColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
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

  Widget _paymentHistorySection(
    Map<String, dynamic> order,
  ) {
    final orderUuid = order['id']?.toString();

    if (orderUuid == null) {
      return const SizedBox.shrink();
    }

    final payments = paymentHistory[orderUuid] ?? [];

    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text(
          'No payment transactions recorded yet.',
          style: TextStyle(
            color: Color(0xFF777777),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 10),
        ...payments.map(
          (payment) => _paymentTransaction(payment),
        ),
      ],
    );
  }

  Widget _paymentTransaction(
    Map<String, dynamic> payment,
  ) {
    final amount =
        (payment['amount'] as num?)?.toDouble() ?? 0;

    final method =
        payment['payment_method']?.toString() ?? '';

    final reference =
        payment['payment_reference']?.toString() ?? '';

    final status =
        payment['payment_status']?.toString() ?? 'Completed';

    final notes =
        payment['notes']?.toString() ?? '';

    final paidAt = DateTime.tryParse(
      payment['paid_at']?.toString() ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                size: 18,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'GHS ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: status == 'Completed'
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),

          if (method.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              'Method: $method',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          ],

          if (reference.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reference: $reference',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          ],

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: $notes',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          ],

          if (paidAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Paid: ${_formatDateTime(paidAt.toLocal())}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentCard(
    Map<String, dynamic> order,
  ) {
    final orderId =
        order['order_id']?.toString() ?? 'Unknown Order';

    final total = _orderTotal(order);
    final paid = _totalPaid(order);
    final balance = _balanceDue(order);

    final paymentStatus =
        _displayPaymentStatus(order);

    final createdAt = DateTime.tryParse(
      order['created_at']?.toString() ?? '',
    );

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
                _statusBadge(paymentStatus),
              ],
            ),

            const Divider(height: 26),

            const Text(
              'Payment Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 12),

            _amountRow(
              'Order Total',
              total,
            ),

            const SizedBox(height: 7),

            _amountRow(
              'Total Paid',
              paid,
              valueColor: const Color(0xFF2E7D32),
            ),

            const SizedBox(height: 7),

            _amountRow(
              'Balance Due',
              balance,
              valueColor: balance > 0
                  ? const Color(0xFFEF6C00)
                  : const Color(0xFF2E7D32),
              bold: true,
            ),

            const SizedBox(height: 14),

            if (balance <= 0 && total > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This order has been fully paid.',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (paid > 0 && balance > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFEF6C00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Part payment received. '
                        'Balance remaining: '
                        'GHS ${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFEF6C00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 28),

            _paymentHistorySection(order),

            if (createdAt != null) ...[
              const Divider(height: 28),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Date',
                    style: TextStyle(
                      color: Color(0xFF666666),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _formatDateTime(
                        createdAt.toLocal(),
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
    String label,
    double amount, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          'GHS ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF333333),
          ),
        ),
      ],
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
                onPressed: loadPayments,
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
        onRefresh: loadPayments,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.payment_outlined,
              size: 75,
              color: Color(0xFF90CAF9),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No payment records yet.',
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
                  'Payment information for your laundry orders will appear here.',
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
      onRefresh: loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _paymentCard(orders[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}