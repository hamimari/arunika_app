import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StoryCard extends StatelessWidget {
  final String title;
  final String ageGroup;
  final String imageUrl;
  final String label;
  final Color labelColor;

  const StoryCard({
    super.key,
    required this.title,
    required this.ageGroup,
    required this.imageUrl,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🖼 Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Image.network(
              imageUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),

          // 📖 Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: labelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E342E),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    ageGroup,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8D6E63),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
