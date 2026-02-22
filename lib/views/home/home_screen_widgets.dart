import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/app_colors.dart';
import 'home_controller.dart';

class HomeScreenWidgets {
  static Widget tabChip(
    String label,
    int index,
    IconData icon,
    int selectedIndex,
    VoidCallback onTap,
  ) {
    final selected = selectedIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.tabUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: AppColors.borderWhite10),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: AppColors.accentOrange.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.white : AppColors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget filterButton() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Colors.white.withOpacity(0.11),
      ),
      child: const Icon(
        Icons.filter_alt_outlined,
        color: Colors.white,
        size: 19,
      ),
    );
  }

  static Widget languageChip(String label, bool selected) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: selected ? AppColors.chipSelectedBg : AppColors.chipUnselectedBg,
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: TextStyle(
          height: 1,
          color:
              selected
                  ? AppColors.chipSelectedText
                  : AppColors.chipUnselectedText,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  static Widget sectionHeader(
    String title,
    IconData icon, {
    VoidCallback? onButtonPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        double fontSize;
        double iconSize;

        if (screenWidth > 1200) {
          fontSize = 18;
          iconSize = 23;
        } else if (screenWidth > 800) {
          fontSize = 17;
          iconSize = 22;
        } else {
          fontSize = 16;
          iconSize = 21;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                title == 'Trending'
                    ? Text('🔥', style: TextStyle(fontSize: iconSize))
                    : Icon(icon, color: Colors.white, size: iconSize),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
          ],
        );
      },
    );
  }

  static Widget buildTrendingCarouselOrList(
    BuildContext context,
    HomeScreenController controller,
    Function(int) onPageChanged,
    Function(Map<String, dynamic>) onMovieTap,
  ) {
    final width = MediaQuery.of(context).size.width;
    final data = controller.trendingTop10;
    final useCarousel = data.length <= 20;

    if (useCarousel) {
      return SizedBox(
        height: 200,
        child: PageView.builder(
          controller: controller.trendingController,
          itemCount: data.length,
          onPageChanged: onPageChanged,
          itemBuilder:
              (context, i) => _buildTrendingCard(
                context,
                data[i],
                i,
                useCarousel,
                controller.trendingPage,
                onMovieTap,
              ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child:
          data.isEmpty
              ? const Center(
                child: Text(
                  'No movies match filters',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              : ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: data.length,
                itemBuilder:
                    (context, i) => SizedBox(
                      width: width * 0.98,
                      child: _buildTrendingCard(
                        context,
                        data[i],
                        i,
                        useCarousel,
                        controller.trendingPage,
                        onMovieTap,
                      ),
                    ),
              ),
    );
  }

  static Widget _buildTrendingCard(
    BuildContext context,
    Map<String, dynamic> movie,
    int i,
    bool useCarousel,
    int trendingPage,
    Function(Map<String, dynamic>) onMovieTap,
  ) {
    final thumb = _backdropOrImage(movie).trim();
    final title = (movie['title'] ?? '').toString();
    final year = (movie['year'] ?? '').toString();
    final description = (movie['description'] ?? '').toString();
    final rating = (double.tryParse(movie['rating']?.toString() ?? '0') ?? 0.0)
        .toStringAsFixed(1);
    final youtubeUrl =
        (movie['youtubeUrl'] ?? movie['trailerUrl'] ?? '').toString();

    return GestureDetector(
      onTap: () => onMovieTap(movie),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        margin: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: useCarousel && trendingPage == i ? 0 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                useCarousel && trendingPage == i ? 0.21 : 0.10,
              ),
              blurRadius: 5,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              posterWithBackground(thumb),
              Positioned(
                right: 16,
                top: 16,
                child: GestureDetector(
                  onTap:
                      youtubeUrl.isNotEmpty
                          ? () => _launchYoutubeUrl(youtubeUrl)
                          : null,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color:
                          youtubeUrl.isNotEmpty
                              ? const Color(0xFFE63946)
                              : Colors.grey[700],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (youtubeUrl.isNotEmpty
                                  ? const Color(0xFFE63946)
                                  : Colors.grey[700]!)
                              .withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color:
                          youtubeUrl.isNotEmpty ? Colors.white : Colors.white54,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(17, 15, 18, 13),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.53),
                        Colors.black.withOpacity(0.93),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.1, 0.67, 1],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ratingBadge(rating),
                          const SizedBox(width: 10),
                          Text(
                            year,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.97),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          height: 1.125,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchYoutubeUrl(String url) async {
    try {
      String formattedUrl = url.trim();
      if (!formattedUrl.startsWith('http')) {
        formattedUrl = 'https://$formattedUrl';
      }

      final videoId = _extractYoutubeVideoId(formattedUrl);
      if (videoId != null) {
        final appUri = Uri.parse('youtube://www.youtube.com/watch?v=$videoId');
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final webUri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri);
      }
    } catch (_) {}
  }

  static String? _extractYoutubeVideoId(String url) {
    try {
      if (url.contains('watch?v=')) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      }
      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          return parts[1].split('?').first.split('&').first;
        }
      }
    } catch (_) {}
    return null;
  }

  static Widget buildTrendingIndicators(HomeScreenController controller) {
    final total = controller.trendingTop10.length;
    final useCarousel = total <= 20;
    const maxDots = 12;

    if (!useCarousel || total == 0) return const SizedBox.shrink();

    if (total <= maxDots) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == controller.trendingPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 8 : 7,
            height: active ? 8 : 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color:
                  active
                      ? const Color.fromARGB(255, 184, 99, 215)
                      : const Color.fromARGB(44, 218, 216, 218),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    }

    int start = controller.trendingPage - (maxDots ~/ 2);
    if (start < 0) start = 0;
    int end = start + maxDots;
    if (end > total) {
      end = total;
      start = end - maxDots;
    }

    final window = List<int>.generate(end - start, (i) => start + i);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (start > 0) _ellipsisDot(),
        ...window.map((i) {
          final active = i == controller.trendingPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 9 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFB64B) : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        if (end < total) _ellipsisDot(),
      ],
    );
  }

  static Widget _ellipsisDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('…', style: TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }

  static Widget buildGenericMovieGrid(
    List<Map<String, dynamic>> movies,
    Function(Map<String, dynamic>) onMovieTap, {
    String? errorMessage,
  }) {
    if (movies.isEmpty) {
      if (errorMessage != null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white30, size: 48),
                SizedBox(height: 16),
                Text(
                  'Check your connectivity',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No movies match filters',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        int crossAxis;
        double aspect;
        double mainSpace;
        double crossSpace;

        if (screenWidth > 1200) {
          crossAxis = 4;
          aspect = 0.68;
          mainSpace = 18;
          crossSpace = 16;
        } else if (screenWidth > 800) {
          crossAxis = 3;
          aspect = 0.67;
          mainSpace = 16;
          crossSpace = 14;
        } else if (screenWidth > 480) {
          crossAxis = 2;
          aspect = 0.66;
          mainSpace = 16;
          crossSpace = 14;
        } else {
          crossAxis = 2;
          aspect = 0.63;
          mainSpace = 12;
          crossSpace = 10;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            mainAxisSpacing: mainSpace,
            crossAxisSpacing: crossSpace,
            childAspectRatio: aspect,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            final rating =
                (double.tryParse(movie['rating']?.toString() ?? '0') ?? 0.0)
                    .toStringAsFixed(1);
            return buildMovieGridItem(movie, rating, onMovieTap);
          },
        );
      },
    );
  }

  static Widget buildMovieGridItem(
    Map<String, dynamic> movie,
    String rating,
    Function(Map<String, dynamic>) onMovieTap,
  ) {
    return GestureDetector(
      onTap: () => onMovieTap(movie),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    posterWithBackground(_posterOrImage(movie)),
                    Positioned(top: 8, right: 8, child: ratingBadge(rating)),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          final youtubeUrl =
                              (movie['youtubeUrl'] ??
                                      movie['trailerUrl'] ??
                                      movie['youtube'] ??
                                      '')
                                  .toString()
                                  .trim();

                          if (youtubeUrl.isNotEmpty) {
                            try {
                              if (await canLaunchUrl(Uri.parse(youtubeUrl))) {
                                await launchUrl(
                                  Uri.parse(youtubeUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (_) {}
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (movie['title'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.16,
                      letterSpacing: 0.02,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${movie['year'] ?? ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget ratingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardMetaBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_border_rounded,
            size: 12,
            color: AppColors.cardStar,
          ),
          const SizedBox(width: 3),
          Text(
            rating,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  static Widget posterWithBackground(String url, {BoxFit fit = BoxFit.cover}) {
    final safeUrl = url.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child:
              safeUrl.isEmpty
                  ? Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.movie, size: 48, color: Colors.white24),
                    ),
                  )
                  : Image.network(
                    safeUrl,
                    fit: fit,
                    filterQuality: FilterQuality.low,
                    loadingBuilder:
                        (c, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                  color: Colors.black26,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                  ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _posterOrImage(Map<String, dynamic> m) {
    final poster = (m['posterPath'] ?? '').toString().trim();
    if (poster.isNotEmpty) return poster;
    final image = (m['image'] ?? '').toString().trim();
    return image;
  }

  static String _backdropOrImage(Map<String, dynamic> m) {
    final backdrop = (m['backdropPath'] ?? m['posterPath']).toString().trim();
    if (backdrop.isNotEmpty) return backdrop;
    final image = (m['image'] ?? '').toString().trim();
    return image;
  }
}
