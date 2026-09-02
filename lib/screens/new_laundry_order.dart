import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewLaundryOrder extends StatefulWidget {
  const NewLaundryOrder({super.key});

  @override
  State<NewLaundryOrder> createState() => _NewLaundryOrderState();
}

class _NewLaundryOrderState extends State<NewLaundryOrder> {
  final supabase = Supabase.instance.client;

  final Map<String, int> quantities = {
    'Long Sleeve Shirt': 0,
    'Short Sleeve Shirt': 0,
    'T-Shirt': 0,
    'Dress': 0,
    'Suit': 0,
    'Bedsheet': 0,
    'Duvet': 0,
    'Curtain': 0,
    'Blanket': 0,
    'Socks': 0,
    'Singlet': 0,
    'Pants': 0,
    'Carpet': 0,
  };

  final Map<String, double> prices = {
    'Long Sleeve Shirt': 15,
    'Short Sleeve Shirt': 12,
    'T-Shirt': 10,
    'Dress': 25,
    'Suit': 40,
    'Bedsheet': 30,
    'Duvet': 50,
    'Curtain': 35,
    'Blanket': 40,
    'Socks': 8,
    'Singlet': 8,
    'Pants': 15,
    'Carpet': 60,
  };

  bool deliveryRequired = false;
  bool isSaving = false;

  double get laundryTotal {
    double total = 0;

    quantities.forEach((item, quantity) {
      total += prices[item]! * quantity;
    });

    return total;
  }

  double get deliveryFee {
    return deliveryRequired ? 20 : 0;
  }

  double get grandTotal {
    return laundryTotal + deliveryFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('New Laundry Order'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Laundry',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the items you want Dzidz Laundry to process.',
              style: TextStyle(
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 20),
            ...quantities.keys.map(_laundryItem),
            const SizedBox(height: 20),
            const Text(
              'Service Option',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Delivery Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  deliveryRequired
                      ? 'Delivery fee: GHS 20.00'
                      : 'Pickup is currently free',
                ),
                value: deliveryRequired,
                activeThumbColor: const Color(0xFF42A5F5),
                onChanged: (value) {
                  setState(() {
                    deliveryRequired = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 25),
            _orderSummary(),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _reviewOrder,
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  isSaving ? 'Saving Order...' : 'Review Order',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _laundryItem(String item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GHS ${prices[item]!.toStringAsFixed(2)} per item',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: quantities[item]! > 0
                  ? () {
                      setState(() {
                        quantities[item] = quantities[item]! - 1;
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: const Color(0xFF1976D2),
            ),
            Text(
              '${quantities[item]}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  quantities[item] = quantities[item]! + 1;
                });
              },
              icon: const Icon(Icons.add_circle_outline),
              color: const Color(0xFF1976D2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 15),
            _summaryRow('Laundry', laundryTotal),
            _summaryRow('Delivery', deliveryFee),
            const Divider(height: 25),
            _summaryRow(
              'Total',
              grandTotal,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String title,
    double amount, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 15,
            ),
          ),
          Text(
            'GHS ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }

  void _reviewOrder() {
    if (laundryTotal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one laundry item.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Order Review'),
          content: Text(
            'Laundry Total: GHS ${laundryTotal.toStringAsFixed(2)}\n'
            'Delivery: GHS ${deliveryFee.toStringAsFixed(2)}\n'
            'Total: GHS ${grandTotal.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      await _saveOrder();
                    },
              child: const Text('Confirm Order'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveOrder() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are not logged in. Please login again.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final customer = await supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', user.id)
          .single();

      final timestamp =
          DateTime.now().millisecondsSinceEpoch.toString();

      final orderId =
          'DZ-${timestamp.substring(timestamp.length - 6)}';

      final selectedItems = Map<String, int>.from(quantities)
        ..removeWhere(
          (key, value) => value == 0,
        );

      final insertedOrder = await supabase
          .from('laundry_orders')
          .insert({
            'customer_id': customer['id'],
            'order_id': orderId,
            'items': selectedItems,
            'laundry_total': laundryTotal,
            'delivery_fee': deliveryFee,
            'total': grandTotal,
            'delivery_required': deliveryRequired,
            'status': 'Order Received',
          })
          .select()
          .single();

      if (!mounted) return;

      final savedOrderId = insertedOrder['order_id'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order $savedOrderId saved successfully to Supabase.',
          ),
        ),
      );

      Navigator.pop(context);
    } on PostgrestException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Database error: ${error.message}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create order: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }
}
