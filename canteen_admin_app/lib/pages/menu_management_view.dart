import 'package:canteen_admin_app/models/menu_item.dart';
import 'package:canteen_admin_app/services/auth_service.dart';
import 'package:canteen_admin_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  _MenuManagementViewState createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory;
  List<String> _categories = [];

  String getCanteenId(BuildContext context) {
    return Provider.of<AuthService>(context, listen: false).canteenId ?? 'default_canteen';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final canteenId = authService.canteenId;

    if (canteenId == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          _buildCategorySelector(canteenId),
          Expanded(
            child: _selectedCategory == null
                ? const Center(child: Text("Select a category to see items."))
                : _buildMenuItemsList(canteenId, _selectedCategory!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_categories.isNotEmpty) {
            _showAddItemDialog(canteenId, _categories);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add a category first.')));
          }
        },
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildCategorySelector(String canteenId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getCanteenStream(canteenId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        if (!snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                  'Canteen data for "$canteenId" not found. Please set it up in Firebase.'),
            ),
          );
        }

        _categories = List<String>.from(snapshot.data?['categories'] ?? []);

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (_categories.isNotEmpty &&
                  (_selectedCategory == null ||
                      !_categories.contains(_selectedCategory))) {
                setState(() {
                  _selectedCategory = _categories.first;
                });
              } else if (_categories.isEmpty) {
                setState(() {
                  _selectedCategory = null;
                });
              }
            }
          });
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black),
                    ),
                  );
                }).toList(),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Category',
                    onPressed: () => _showAddCategoryDialog(canteenId)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItemsList(String canteenId, String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMenuItemsStream(canteenId, category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No items in "$category".'));
        }

        final items = snapshot.data!.docs
            .map((doc) => AdminMenuItem.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Price: ₹${item.price.toStringAsFixed(2)} | Stock: ${item.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Item',
                      onPressed: () => _showAddItemDialog(
                          canteenId, _categories,
                          item: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Item',
                      onPressed: () =>
                          _showDeleteConfirmationDialog(canteenId, item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String canteenId, AdminMenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
            'Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestoreService.deleteMenuItem(canteenId, item.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('"${item.name}" deleted.'),
                        backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(String canteenId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _firestoreService.addCategory(
                    canteenId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String canteenId, List<String> categories,
      {AdminMenuItem? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');
    final stockController =
        TextEditingController(text: item?.stock.toString() ?? '');
    String selectedCategory =
        item?.category ?? _selectedCategory ?? categories.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Menu Item' : 'Add New Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Item Name'),
                        autofocus: true),
                    TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                    TextField(
                        controller: stockController,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final newItem = AdminMenuItem(
                      id: item?.id,
                      name: nameController.text.trim(),
                      price: double.tryParse(priceController.text) ?? 0.0,
                      stock: int.tryParse(stockController.text) ?? 0,
                      category: selectedCategory,
                    );

                    try {
                      if (isEditing) {
                        await _firestoreService.updateMenuItem(
                            canteenId, newItem);
                      } else {
                        await _firestoreService.addMenuItem(canteenId, newItem);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('${newItem.name} saved successfully!'),
                              backgroundColor: Colors.green),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to save item: $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
