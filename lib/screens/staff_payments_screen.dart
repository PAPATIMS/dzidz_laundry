import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffPaymentsScreen extends StatefulWidget {
  const StaffPaymentsScreen({super.key});

  @override
  State<StaffPaymentsScreen> createState() =>
      _StaffPaymentsScreenState();
}

class _StaffPaymentsScreenState
    extends State<StaffPaymentsScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> orders = [];
  Map<String, double> paidAmounts = {};

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
      final ordersResponse = await supabase
          .from('laundry_orders')
          .select()
          .order('created_at', ascending: false);

      final paymentsResponse = await supabase
          .from('order_payments')
          .select(
            'order_id, amount, payment_status',
          )
          .eq('payment_status', 'Completed');

      final Map<String, double> totals = {};

      for (final payment in paymentsResponse) {
        final orderId =
            payment['order_id']?.toString();

        if (orderId == null) {
          continue;
        }

        final amount =
            (payment['amount'] as num?)?.toDouble() ?? 0;

        totals[orderId] =
            (totals[orderId] ?? 0) + amount;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        orders =
            List<Map<String, dynamic>>.from(
          ordersResponse,
        );

        paidAmounts = totals;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to load payments: $e';
      });
    }
  }

  double _orderTotal(
    Map<String, dynamic> order,
  ) {
    return (order['total'] as num?)?.toDouble() ?? 0;
  }

  double _amountPaid(
    Map<String, dynamic> order,
  ) {
    final orderId =
        order['id']?.toString();

    if (orderId == null) {
      return 0;
    }

    return paidAmounts[orderId] ?? 0;
  }

  double _balance(
    Map<String, dynamic> order,
  ) {
    final balance =
        _orderTotal(order) -
            _amountPaid(order);

    return balance < 0 ? 0 : balance;
  }

  String _paymentStatus(
    Map<String, dynamic> order,
  ) {
    final total = _orderTotal(order);
    final paid = _amountPaid(order);

    if (paid <= 0) {
      return 'Pending';
    }

    if (paid >= total) {
      return 'Fully Paid';
    }

    return 'Partially Paid';
  }

  Future<void> recordPayment(
    Map<String, dynamic> order,
  ) async {
    final orderUuid =
        order['id']?.toString();

    if (orderUuid == null) {
      return;
    }

    final balance =
        _balance(order);

    if (balance <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'This order has already been fully paid.',
          ),
        ),
      );

      return;
    }

    final amountController =
        TextEditingController();

    final referenceController =
        TextEditingController();

    final notesController =
        TextEditingController();

    String? selectedMethod;

    final paymentAmount =
        await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Record Payment',
                style: TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'Order: ${order['order_id'] ?? 'Unknown'}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Align(
                      alignment:
                          Alignment.centerLeft,
                      child: Text(
                        'Balance Due: GHS ${balance.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          color:
                              Color(0xFFE65100),
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextField(
                      controller:
                          amountController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payment Amount',
                        prefixText:
                            'GHS ',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          selectedMethod,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payment Method',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cash',
                          child:
                              Text('Cash'),
                        ),
                        DropdownMenuItem(
                          value:
                              'Mobile Money',
                          child: Text(
                            'Mobile Money',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'Bank Transfer',
                          child: Text(
                            'Bank Transfer',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Card',
                          child:
                              Text('Card'),
                        ),
                      ],
                      onChanged:
                          (value) {
                        setDialogState(() {
                          selectedMethod =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                          referenceController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payment Reference',
                        hintText:
                            'Optional',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                          notesController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText: 'Notes',
                        hintText:
                            'Optional',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(
                      amountController
                          .text
                          .trim(),
                    );

                    if (amount ==
                            null ||
                        amount <= 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid payment amount.',
                          ),
                        ),
                      );

                      return;
                    }

                    if (amount >
                        balance) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment cannot exceed the balance of GHS ${balance.toStringAsFixed(2)}.',
                          ),
                        ),
                      );

                      return;
                    }

                    if (selectedMethod ==
                        null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a payment method.',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      amount,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF42A5F5,
                    ),
                    foregroundColor:
                        Colors.white,
                  ),
                  child: const Text(
                    'Record Payment',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (paymentAmount == null) {
      amountController.dispose();
      referenceController.dispose();
      notesController.dispose();
      return;
    }

    try {
      await supabase
          .from('order_payments')
          .insert({
        'order_id': orderUuid,
        'amount': paymentAmount,
        'payment_method':
            selectedMethod,
        'payment_reference':
            referenceController
                    .text
                    .trim()
                    .isEmpty
                ? null
                : referenceController
                    .text
                    .trim(),
        'payment_status':
            'Completed',
        'notes':
            notesController
                    .text
                    .trim()
                    .isEmpty
                ? null
                : notesController
                    .text
                    .trim(),
        'paid_at':
            DateTime.now()
                .toIso8601String(),
        'recorded_by':
            supabase
                .auth
                .currentUser
                ?.id,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Payment recorded successfully.',
          ),
        ),
      );

      await loadPayments();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to record payment: $e',
          ),
          duration:
              const Duration(seconds: 5),
        ),
      );
    } finally {
      amountController.dispose();
      referenceController.dispose();
      notesController.dispose();
    }
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Fully Paid':
        return const Color(
          0xFF2E7D32,
        );

      case 'Partially Paid':
        return const Color(
          0xFFE65100,
        );

      case 'Pending':
        return const Color(
          0xFFC62828,
        );

      default:
        return const Color(
          0xFF1976D2,
        );
    }
  }

  Widget _paymentStatusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _orderCard(
    Map<String, dynamic> order,
  ) {
    final orderId =
        order['order_id']
                ?.toString() ??
            'Unknown Order';

    final total =
        _orderTotal(order);

    final paid =
        _amountPaid(order);

    final balance =
        _balance(order);

    final status =
        _paymentStatus(order);

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),
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
            Row(
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
                _paymentStatusBadge(
                  status,
                ),
              ],
            ),

            const Divider(
              height: 25,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Order Total',
                  style:
                      TextStyle(
                    color:
                        Color(0xFF666666),
                  ),
                ),
                Text(
                  'GHS ${total.toStringAsFixed(2)}',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Amount Paid',
                  style:
                      TextStyle(
                    color:
                        Color(0xFF666666),
                  ),
                ),
                Text(
                  'GHS ${paid.toStringAsFixed(2)}',
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

            const SizedBox(
              height: 8,
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Balance Due',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  'GHS ${balance.toStringAsFixed(2)}',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 17,
                    color: balance > 0
                        ? const Color(
                            0xFFE65100,
                          )
                        : const Color(
                            0xFF2E7D32,
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 46,
              child:
                  ElevatedButton.icon(
                onPressed:
                    balance > 0
                        ? () =>
                            recordPayment(
                              order,
                            )
                        : null,
                icon:
                    const Icon(
                  Icons
                      .payments_outlined,
                ),
                label: Text(
                  balance > 0
                      ? 'Record Payment'
                      : 'Fully Paid',
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
                        BorderRadius
                            .circular(
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
                    loadPayments,
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
            loadPayments,
        child: ListView(
          children: const [
            SizedBox(
              height: 180,
            ),

            Icon(
              Icons
                  .payments_outlined,
              size: 75,
              color:
                  Color(0xFF90CAF9),
            ),

            SizedBox(
              height: 20,
            ),

            Center(
              child: Text(
                'No orders available.',
                style:
                    TextStyle(
                  fontSize: 19,
                  color:
                      Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          loadPayments,
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text(
          'Payment Management',
        ),
        backgroundColor:
            const Color(0xFF42A5F5),
        foregroundColor:
            Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading
                ? null
                : loadPayments,
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
