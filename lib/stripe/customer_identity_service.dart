import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerIdentityService {
  static const _storageKey = 'stripe_customer_key';

  Future<String> getOrCreateCustomerKey() async {
    final authenticatedUser = FirebaseAuth.instance.currentUser;
    if (authenticatedUser != null && authenticatedUser.uid.isNotEmpty) {
      return 'firebase_${authenticatedUser.uid}';
    }

    final preferences = await SharedPreferences.getInstance();
    final existingKey = preferences.getString(_storageKey);
    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }

    final random = Random();
    final generatedKey =
        'guest_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1 << 32)}';

    await preferences.setString(_storageKey, generatedKey);
    return generatedKey;
  }
}
