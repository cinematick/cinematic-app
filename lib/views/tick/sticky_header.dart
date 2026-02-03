import 'package:flutter/material.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'tick_controller.dart';
import 'tick_state.dart';
import 'package:cinematick/widgets/info_row_card.dart';

class StickyHeader extends SliverPersistentHeaderDelegate {
  final TickState state;
  final TickController controller;
  final String? movieTitle;
  final String? rating;
  final String selectedRegion;
  final FocusNode _searchFocusNode;
  final TextEditingController _searchTextController;

  StickyHeader({
    required this.state,
    required this.controller,
    this.movieTitle,
    this.rating,
    this.selectedRegion = 'NSW',
    FocusNode? searchFocusNode,
    TextEditingController? searchTextController,
  }) : _searchFocusNode = searchFocusNode ?? FocusNode(),
       _searchTextController =
           searchTextController ??
           TextEditingController(text: state.searchQuery);

  @override
  double get maxExtent => 250;

  @override
  double get minExtent => 250;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieHeader(),
              _buildDateSelector(),
              _buildLanguageChips(),
              _buildInfoRow(),
            ],
          ),
          if (state.searchQuery.isNotEmpty && state.showSearchSuggestions)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: _buildSearchSuggestions(),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: TextField(
        controller: _searchTextController,
        focusNode: _searchFocusNode,
        onChanged: (query) {
          controller.updateSearch(query);
        },
        onTap: () {
          controller.openSearchSuggestions();
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search movies or theaters...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        cursorColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final query = state.searchQuery.toLowerCase();
    final suggestions = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    // Get the FILTERED movies using the same logic as the main list
    final filteredMovies = controller.filteredMovies();

    // Extract unique movie titles and cinema names from ALREADY FILTERED movies
    for (var i = 0; i < filteredMovies.length; i++) {
      final movie = filteredMovies[i];
      // Use the EXACT same field names as filteredMovies() in controller
      final title = (movie['movieTitle'] ?? '').toString();
      final cinemaName =
          (movie['cinemaName'] ??
                  movie['cinema']?['name'] ??
                  movie['theatreName'] ??
                  '')
              .toString();

      // Add movie title suggestion if it contains the search query
      if (title.isNotEmpty && title.toLowerCase().contains(query)) {
        final key = 'movie_$title';
        if (!seenKeys.contains(key)) {
          suggestions.add({
            'type': 'movie',
            'title': title,
            'icon': Icons.movie,
            'key': key,
          });
          seenKeys.add(key);
        }
      }

      // Add cinema name suggestion if it contains the search query
      if (cinemaName.isNotEmpty && cinemaName.toLowerCase().contains(query)) {
        final key = 'cinema_$cinemaName';
        if (!seenKeys.contains(key)) {
          suggestions.add({
            'type': 'cinema',
            'title': cinemaName,
            'icon': Icons.location_on,
            'key': key,
          });
          seenKeys.add(key);
        }
      }
    }

    if (suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          'No movies or theaters found',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: suggestions.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          final isMovie = suggestion['type'] == 'movie';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Update the text in the search bar
                _searchTextController.text = suggestion['title'];
                // Update the controller's search state
                controller.updateSearch(suggestion['title']);
                // Close suggestions
                controller.closeSearchSuggestions();
                // Unfocus the search bar
                _searchFocusNode.unfocus();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      suggestion['icon'],
                      size: 18,
                      color:
                          isMovie
                              ? const Color(0xFFB863D7)
                              : const Color(0xFF64B5F6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            isMovie ? 'Movie' : 'Theater',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child:
            state.generatedDates.isEmpty
                ? const Center(
                  child: Text(
                    'Loading dates...',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : Builder(
                  builder: (context) {
                    // Check if today (first date) has showtimes
                    final hasShowtimesToday =
                        state.generatedDates.isNotEmpty &&
                        controller.hasShowtimesForDate(0, selectedRegion);

                    // Determine starting index
                    final startIndex = hasShowtimesToday ? 0 : 1;
                    final availableDates =
                        state.generatedDates.sublist(startIndex).toList();

                    if (availableDates.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: availableDates.length,
                      itemBuilder: (context, listIndex) {
                        final actualDateIndex = startIndex + listIndex;
                        final selected =
                            actualDateIndex == state.selectedDateIndex;
                        final date = availableDates[listIndex];

                        return Padding(
                          padding: EdgeInsets.only(
                            left: listIndex == 0 ? 10 : 6,
                          ),
                          child: GestureDetector(
                            onTap:
                                () => controller.updateSelectedDate(
                                  actualDateIndex,
                                ),
                            child: Container(
                              width: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient:
                                    selected ? AppColors.filterGradient : null,
                                color:
                                    selected
                                        ? null
                                        : Colors.white.withOpacity(0.09),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date['label'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.90),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 9,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    date['num'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    date['month'],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildLanguageChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 10),
      child: SizedBox(
        height: 28,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: state.availableLanguages.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              final isAll = state.selectedLangIndex == -1;
              return _chip(
                label: "All",
                selected: isAll,
                onTap: () => controller.updateSelectedLanguage(-1),
              );
            }

            final index = i - 1;
            final lang = state.availableLanguages[index];
            final selected = index == state.selectedLangIndex;

            return _chip(
              label: lang[0].toUpperCase() + lang.substring(1),
              selected: selected,
              onTap: () => controller.updateSelectedLanguage(index),
            );
          },
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color:
                selected
                    ? AppColors.chipSelectedBg
                    : AppColors.chipUnselectedBg,
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected
                      ? AppColors.chipSelectedText
                      : AppColors.chipUnselectedText,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return InfoRowCard(
      selected: state.selectedInfoIndex,
      onChanged: controller.updateSelectedInfoIndex,
      cheapestPrice: controller.getCheapestPrice(),
      availabilityPercentage: controller.getMaxAvailability(
        region: selectedRegion,
      ),
    );
  }

  @override
  bool shouldRebuild(StickyHeader oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.movieTitle != movieTitle ||
      oldDelegate.selectedRegion != selectedRegion;
}
