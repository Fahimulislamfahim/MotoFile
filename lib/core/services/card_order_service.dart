import 'package:shared_preferences/shared_preferences.dart';

class CardOrderService {
  static const String _orderKey = 'card_order';

  // Default card types in default order
  static const List<String> defaultOrder = [
    'Driving License',
    'Registration',
    'Tax Token',
    'Insurance',
  ];

  // Get saved card order
  Future<List<String>> getCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(_orderKey);
    
    if (savedOrder == null || savedOrder.isEmpty) {
      return List.from(defaultOrder);
    }
    
    // Merge saved order with any new default types
    final mergedOrder = <String>[];
    
    // Add saved items first (in saved order)
    for (final item in savedOrder) {
      if (defaultOrder.contains(item)) {
        mergedOrder.add(item);
      }
    }
    
    // Add any new default items that weren't in saved order
    for (final item in defaultOrder) {
      if (!mergedOrder.contains(item)) {
        mergedOrder.add(item);
      }
    }
    
    return mergedOrder;
  }

  // Save card order
  Future<void> saveCardOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_orderKey, order);
  }

  // Reset to default order
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orderKey);
  }

  // Sort a list of types according to saved order
  List<String> sortByOrder(List<String> types, List<String> savedOrder) {
    final sorted = <String>[];
    
    // Add items in saved order first
    for (final item in savedOrder) {
      if (types.contains(item)) {
        sorted.add(item);
      }
    }
    
    // Add any remaining items that weren't in saved order
    for (final item in types) {
      if (!sorted.contains(item)) {
        sorted.add(item);
      }
    }
    
    return sorted;
  }
}
