import 'package:flutter/foundation.dart';
import 'cart_item.dart';
import 'menu_item.dart';

class CartModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get totalItemCount =>
      _items.fold(0, (total, item) => total + item.quantity);
  double get totalPrice => _items.fold(
      0.0, (sum, item) => sum + (item.menuItem.price * item.quantity));

  int getQuantity(MenuItem menuItem) {
    final item = _items.firstWhere(
        (item) => item.menuItem.id == menuItem.id, // Switched to ID for accuracy
        orElse: () => CartItem(menuItem: menuItem, quantity: 0));
    return item.quantity;
  }

  void addItem(MenuItem menuItem) {
    for (var item in _items) {
      if (item.menuItem.id == menuItem.id) { // Switched to ID for accuracy
        item.quantity++;
        notifyListeners();
        return;
      }
    }
    _items.add(CartItem(menuItem: menuItem));
    notifyListeners();
  }

  void removeItem(MenuItem menuItem) {
    for (var item in _items) {
      if (item.menuItem.id == menuItem.id) { // Switched to ID for accuracy
        item.quantity--;
        if (item.quantity == 0) {
          _items.remove(item);
        }
        notifyListeners();
        return;
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
