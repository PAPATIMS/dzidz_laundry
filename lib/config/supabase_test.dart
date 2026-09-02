import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTest {
  static Future<String> testConnection() async {
    try {
      final response = await Supabase.instance.client
          .from('connection_test')
          .select()
          .limit(1);

      return 'SUCCESS: Supabase connected. Rows: ${response.length}';
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}