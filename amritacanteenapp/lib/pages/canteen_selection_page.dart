import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'menu_page.dart';

class CanteenSelectionPage extends StatelessWidget {
  const CanteenSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
            child: Center(
              child: Image.asset('assets/amrita_logo.png',
                  height: 50,
                  errorBuilder: (ctx, err, st) => const Text('Amrita Logo',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFF8A1038),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('canteens')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("Couldn't load canteens.",
                            style: TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No canteens found.",
                            style: TextStyle(color: Colors.white)));
                  }

                  // Map Firestore documents to CanteenCard widgets
                  final canteenDocs = snapshot.data!.docs;
                  final canteenCards = canteenDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final canteenId = doc.id;

                    // Use a default name if 'name' field doesn't exist
                    final canteenName =
                        data['name'] as String? ?? 'Unnamed Canteen';

                    // Default to 'false' (closed) if 'isOpen' field doesn't exist
                    final isOpen = data['isOpen'] as bool? ?? false;

                    String imagePath =
                        'assets/main_canteen.png'; // Default image
                    if (canteenId == 'it_canteen')
                      imagePath = 'assets/it_canteen.png';
                    if (canteenId == 'mba_canteen')
                      imagePath = 'assets/mba_canteen.png';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: CanteenCard(
                        canteenName: canteenName.toUpperCase(),
                        isOpen: isOpen,
                        imagePath: imagePath,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuPage(
                                canteenName: canteenName,
                                canteenId: canteenId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList();

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'CHOOSE CANTEEN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ...canteenCards, // Display the dynamic list of canteens
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CanteenCard extends StatefulWidget {
  final String canteenName;
  final bool isOpen;
  final String imagePath;
  final VoidCallback onTap;

  const CanteenCard({
    super.key,
    required this.canteenName,
    required this.isOpen,
    required this.imagePath,
    required this.onTap,
  });

  @override
  _CanteenCardState createState() => _CanteenCardState();
}

class _CanteenCardState extends State<CanteenCard> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.isOpen) setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isOpen) {
      setState(() => _scale = 1.0);
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (widget.isOpen) setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.isOpen ? 'OPEN' : 'CLOSED';
    final Color statusColor =
        widget.isOpen ? Colors.green.shade600 : Colors.red.shade600;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Opacity(
          opacity: widget.isOpen ? 1.0 : 0.6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: AssetImage(widget.imagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    color: Colors.white,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.canteenName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 10.0, color: Colors.black)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
