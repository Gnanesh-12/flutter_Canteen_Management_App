class MenuItem {
  final String id; // Added to uniquely identify items
  final String name;
  final double price;
  final String imagePath;
  final String category;

  MenuItem({
    required this.id, // Added
    required this.name,
    required this.price,
    required this.imagePath,
    required this.category,
  });
}
