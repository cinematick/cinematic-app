import 'package:flutter/material.dart';
import 'app_colors.dart';

class TrendingCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String year;
  final String rating;
  final String description;

  const TrendingCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.year = '2024',
    this.rating = '7.6',
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: AppColors.cardOverlayGradient,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.cardTitle,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardMetaBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.cardStar, size: 16),
                          const SizedBox(width: 6),
                          Text(rating, style: const TextStyle(color: AppColors.cardMetaText)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardMetaBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(year, style: const TextStyle(color: AppColors.cardDescription)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 320,
                  child: Text(
                    description,
                    style: const TextStyle(color: AppColors.cardDescription),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
