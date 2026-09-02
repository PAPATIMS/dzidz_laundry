import 'customer.dart';

class CustomerStore {
  static final List<Customer> customers = [];

  static void addCustomer(Customer customer) {
    customers.add(customer);
  }

  static Customer? findByEmail(String email) {
    for (final customer in customers) {
      if (customer.email.toLowerCase() == email.toLowerCase()) {
        return customer;
      }
    }

    return null;
  }

  static bool emailExists(String email) {
    return findByEmail(email) != null;
  }
}
