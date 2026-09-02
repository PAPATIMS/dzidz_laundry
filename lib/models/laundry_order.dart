class LaundryOrder {
  final String orderId;
  final Map<String, int> items;
  final double laundryTotal;
  final double deliveryFee;
  final double total;
  final bool deliveryRequired;
  String status;
  final DateTime createdAt;

  LaundryOrder({
    required this.orderId,
    required this.items,
    required this.laundryTotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryRequired,
    required this.status,
    required this.createdAt,
  });
}