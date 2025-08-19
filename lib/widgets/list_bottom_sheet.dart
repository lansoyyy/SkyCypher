import 'package:flutter/material.dart';
import '../../widgets/text_widget.dart';

class ListBottomSheet extends StatelessWidget {
  const ListBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: 'List Name',
                  fontSize: 18,
                  color: Colors.white,
                  isBold: true,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          // List items
          Expanded(
            child: ListView(
              children: [
                Divider(
                  color: Colors.white24,
                ),
                _buildCafeItem(
                  name: 'Daily dose',
                  image: 'assets/images/daily_dose.jpg',
                ),
                Divider(
                  color: Colors.white24,
                ),
                _buildCafeItem(
                  name: 'Hid\'n Cafe',
                  image: 'assets/images/hidn_cafe.jpg',
                ),
                Divider(
                  color: Colors.white24,
                ),
                _buildCafeItem(
                  name: 'Outlook Cafe',
                  image: 'assets/images/outlook_cafe.jpg',
                ),
                Divider(
                  color: Colors.white24,
                ),
                _buildCafeItem(
                  name: 'Fiend Coffee Club',
                  image: 'assets/images/fiend_coffee.jpg',
                ),
                Divider(
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCafeItem({
    required String name,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[800],
            ),
            child: const Center(
              child: Icon(Icons.image, color: Colors.white38, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          TextWidget(
            text: name,
            fontSize: 16,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ListBottomSheet(),
    );
  }
}
