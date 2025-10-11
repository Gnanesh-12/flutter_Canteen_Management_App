import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_model.dart';
import '../models/menu_item.dart';
import 'cart_page.dart';

class MenuPage extends StatefulWidget {
  final String canteenName;
  final String canteenId;

  const MenuPage({
    super.key,
    required this.canteenName,
    required this.canteenId,
  });

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.canteenName,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8A1038),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // This StreamBuilder fetches the categories for the selected canteen
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('canteens')
                .doc(widget.canteenId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox(
                    height: 60,
                    child: Center(
                        child: Text('Error: Could not load categories.')));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox(
                    height: 60,
                    child: Center(child: Text('Canteen not found.')));
              }
              final categories =
                  List<String>.from(snapshot.data?['categories'] ?? []);

              // Logic to auto-select the first category
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted &&
                      (_selectedCategory == null ||
                          !categories.contains(_selectedCategory))) {
                    setState(() {
                      _selectedCategory =
                          categories.isNotEmpty ? categories.first : null;
                    });
                  }
                });
              }

              return _buildCategoryTabs(categories);
            },
          ),
          // This StreamBuilder fetches the menu items for the selected category
          Expanded(
            child: _selectedCategory == null
                ? const Center(child: Text('Select a category.'))
                : StreamBuilder<QuerySnapshot>(
                    // *** MAJOR FIX ***
                    // The query is now simplified to fetch all items in a category.
                    // We will filter out "out of stock" items on the device.
                    // This completely avoids the Firestore index error.
                    stream: FirebaseFirestore.instance
                        .collection('canteens')
                        .doc(widget.canteenId)
                        .collection('menu_items')
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading menu items.'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No items in this category.'));
                      }

                      // Filter out items that are out of stock (stock <= 0)
                      final inStockDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['stock'] ?? 0) > 0;
                      }).toList();

                      if (inStockDocs.isEmpty) {
                        return const Center(
                            child: Text(
                                'No items currently available in this category.'));
                      }

                      final menuItems = inStockDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return MenuItem(
                          id: doc.id,
                          name: data['name'] ?? 'No Name',
                          price: (data['price'] as num? ?? 0).toDouble(),
                          category: data['category'] ?? '',
                          imagePath: 'assets/dish_placeholder.png',
                        );
                      }).toList();

                      return _buildMenuItemsGrid(menuItems);
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: cart.totalItemCount > 0 ? _buildCartBottomSheet(cart) : null,
    );
  }

  // Helper widgets remain largely the same, no major changes needed here
  Widget _buildCategoryTabs(List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8A1038)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItemsGrid(List<MenuItem> items) {
    return GridView.builder(
      key: ValueKey<String?>(_selectedCategory),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return MenuItemCard(menuItem: items[index]);
      },
    );
  }

  Widget _buildCartBottomSheet(CartModel cart) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CartPage(canteenId: widget.canteenId))),
      child: Container(
        height: 60,
        color: const Color(0xFF8A1038),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${cart.totalItemCount} ITEM | ₹${cart.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const Row(
              children: [
                Text('PROCEED',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                SizedBox(width: 5),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  const MenuItemCard({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context) {
    var cart = context.watch<CartModel>();
    final quantity = cart.getQuantity(menuItem);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.asset(
                menuItem.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) =>
                    const Icon(Icons.fastfood, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menuItem.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${menuItem.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: quantity == 0
                          ? _buildAddButton(cart)
                          : _buildQuantityController(cart, quantity),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddButton(CartModel cart) {
    return GestureDetector(
      onTap: () => cart.addItem(menuItem),
      child: Container(
        key: const ValueKey('add'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF8A1038)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('ADD',
            style: TextStyle(
                color: Color(0xFF8A1038),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildQuantityController(CartModel cart, int quantity) {
    return Container(
      key: const ValueKey('quantity'),
      decoration: BoxDecoration(
        color: const Color(0xFF8A1038),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              onPressed: () => cart.removeItem(menuItem),
              icon: const Icon(Icons.remove, color: Colors.white, size: 14),
              padding: EdgeInsets.zero,
            ),
          ),
          Text('$quantity',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
              onPressed: () => cart.addItem(menuItem),
              icon: const Icon(Icons.add, color: Colors.white, size: 14),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
