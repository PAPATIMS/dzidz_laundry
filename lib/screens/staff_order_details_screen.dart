import 'package:flutter/material.dart';

class StaffOrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const StaffOrderDetailsScreen({
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

  @override
  Widget build(BuildContext context) {
    final customer = order['customer'];

    final customerName = customer == null
        ? 'Unknown customer'
        : '${customer['first_name'] ?? ''} '
              '${customer['last_name'] ?? ''}'.trim();

    final customerEmail =
        customer?['email']?.toString() ?? 'No email';

    final customerPhone =
        customer?['phone']?.toString() ?? 'No phone';

    final customerAddress =
        customer?['address']?.toString() ?? 'No address provided';

    final orderId =
        order['order_id']?.toString() ?? 'Unknown order';

    final status =
        order['status']?.toString() ?? 'Order Received';

    final items = Map<String, dynamic>.from(
      order['items'] ?? {},
    );

    final laundryTotal =
        (order['laundry_total'] as num?)?.toDouble() ?? 0;

    final deliveryFee =
        (order['delivery_fee'] as num?)?.toDouble() ?? 0;

    final total =
        (order['total'] as num?)?.toDouble() ?? 0;

    final deliveryRequired =
        order['delivery_required'] == true;

    final createdAt = DateTime.tryParse(
      order['created_at']?.toString() ?? '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F4),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderHeader(orderId, status),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Customer Information',
              icon: Icons.person,
              children: [
                _infoRow(
                  Icons.person_outline,
                  'Name',
                  customerName.isEmpty
                      ? 'Unknown customer'
                      : customerName,
                ),
                _infoRow(
                  Icons.email_outlined,
                  'Email',
                  customerEmail,
                ),
                _infoRow(
                  Icons.phone_outlined,
                  'Phone',
                  customerPhone,
                ),
                _infoRow(
                  Icons.location_on_outlined,
                  'Address',
                  customerAddress,
                ),
              ],
            ),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Laundry Items',
              icon: Icons.local_laundry_service,
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No laundry items recorded.',
                      style: TextStyle(
                        color: Color(0xFF666666),
                      ),
                    ),
                  )
                else
                  ...items.entries.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.key,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              '× ${item.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Order Summary',
              icon: Icons.receipt_long,
              children: [
                _amountRow(
                  'Laundry',
                  laundryTotal,
                ),
                _amountRow(
                  'Delivery',
                  deliveryFee,
                ),
                const Divider(height: 24),
                _amountRow(
                  'Total',
                  total,
                  isTotal: true,
                ),
              ],
            ),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Service Information',
              icon: Icons.local_shipping_outlined,
              children: [
                _infoRow(
                  deliveryRequired
                      ? Icons.delivery_dining
                      : Icons.store,
                  'Service',
                  deliveryRequired
                      ? 'Delivery'
                      : 'Customer Pickup',
                ),
                if (createdAt != null)
                  _infoRow(
                    Icons.calendar_today_outlined,
                    'Created',
                    _formatDateTime(createdAt),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Order Progress',
              icon: Icons.timeline,
              children: [
                _buildProgressTimeline(status),
              ],
            ),

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Item / Quality Photos',
              icon: Icons.photo_camera_outlined,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 45,
                        color: Color(0xFF888888),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No photos attached',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Photo capture will be added here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _orderHeader(
    String orderId,
    String status,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Color(0xFF1976D2),
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Number',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    orderId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
            _statusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF1976D2),
                  size: 22,
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF777777),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight:
                  isTotal
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          Text(
            'GHS ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 19 : 15,
              fontWeight:
                  isTotal
                      ? FontWeight.bold
                      : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
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

  Widget _buildProgressTimeline(String currentStatus) {
    final currentIndex =
        statuses.indexOf(currentStatus);

    return Column(
      children: List.generate(
        statuses.length,
        (index) {
          final isCompleted =
              currentIndex >= 0 &&
              index <= currentIndex;

          final isCurrent =
              currentIndex == index;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF42A5F5)
                          : const Color(0xFFE0E0E0),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : Icons.circle,
                      size: isCompleted ? 17 : 8,
                      color: isCompleted
                          ? Colors.white
                          : const Color(0xFF999999),
                    ),
                  ),
                  if (index <
                      statuses.length - 1)
                    Container(
                      width: 2,
                      height: 35,
                      color: index < currentIndex
                          ? const Color(0xFF42A5F5)
                          : const Color(0xFFE0E0E0),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Padding(
                padding:
                    const EdgeInsets.only(top: 4),
                child: Text(
                  statuses[index],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isCurrent
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCompleted
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF777777),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${local.day}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}