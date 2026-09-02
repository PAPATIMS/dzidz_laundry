import 'package:flutter/material.dart';
import '../models/laundry_order.dart';

class OrderTrackingScreen extends StatelessWidget {
  final LaundryOrder order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

    static const List<String> statuses = [
    'Order Received',
    'Washing/Drying',
    'Ironing',
    'Quality Check',
    'Ready',
    'Out for Delivery',
    'Delivered',
  ];

  int get currentStep {
    final index = statuses.indexOf(order.status);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderHeader(),

            const SizedBox(height: 25),

            const Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(
              statuses.length,
              (index) => _statusStep(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderHeader() {
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
            Text(
              order.orderId,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Current Status: ${order.status}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              order.deliveryRequired
                  ? 'Service: Delivery'
                  : 'Service: Pickup',
              style: const TextStyle(
                color: Color(0xFF666666),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Total: GHS ${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusStep(int index) {
    final bool completed = index <= currentStep;
    final bool current = index == currentStep;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF42A5F5)
                    : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed
                    ? Icons.check
                    : Icons.circle_outlined,
                color: completed
                    ? Colors.white
                    : const Color(0xFF888888),
              ),
            ),

            if (index < statuses.length - 1)
              Container(
                width: 3,
                height: 55,
                color: index < currentStep
                    ? const Color(0xFF42A5F5)
                    : const Color(0xFFE0E0E0),
              ),
          ],
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statuses[index],
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: current || completed
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: completed
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF888888),
                  ),
                ),

                if (current)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Current stage',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF42A5F5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}