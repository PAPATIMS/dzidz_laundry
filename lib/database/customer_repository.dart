import '../models/customer.dart';
import '../models/customer_store.dart';

class CustomerRepository {
  static final CustomerRepository instance =
      CustomerRepository._internal();

  CustomerRepository._internal();

  factory CustomerRepository() {
    return instance;
  }

  Future<void> initialize() async {
    // Database initialization will be connected here.
  }

  Future<void> addCustomer(Customer customer) async {
    CustomerStore.addCustomer(customer);
  }

  Future<Customer?> findByEmail(String email) async {
    return CustomerStore.findByEmail(email);
  }

  Future<bool> emailExists(String email) async {
    return CustomerStore.emailExists(email);
  }

  Future<List<Customer>> getAllCustomers() async {
    return List<Customer>.from(CustomerStore.customers);
  }
}
