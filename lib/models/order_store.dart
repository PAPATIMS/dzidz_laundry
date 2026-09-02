import 'laundry_order.dart';

class OrderStore {
  static final List<LaundryOrder> orders = [];

  static void addOrder(LaundryOrder order) {
    orders.add(order);
  }
}