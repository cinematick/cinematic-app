import 'package:cinematick/config/secrets.dart';
import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/views/show_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class CinemaShowtimesScreen extends StatefulWidget {
  final String locationName;
  final String locationAddress;
  final String? cinemaId;
  final VoidCallback? onBackPressed;
  final Function(String movieTitle)? onMovieSelected;

  const CinemaShowtimesScreen({
    super.key,
    required this.locationName,
    required this.locationAddress,
    this.cinemaId,
    this.onBackPressed,
    this.onMovieSelected,
  });

  @override
  State<CinemaShowtimesScreen> createState() => _CinemaShowtimesScreenState();
}

class _CinemaShowtimesScreenState extends State<CinemaShowtimesScreen> {
  late TextEditingController _searchController;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _movies = [];
  List<Map<String, dynamic>> _filteredMovies = [];
  Map<String, dynamic>? _cinemaDetails;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.cinemaId != null) {
      _fetchCinemaShowtimes(widget.cinemaId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCinemaShowtimes(String cinemaId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cinemas/$cinemaId'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _cinemaDetails = data['cinema'];
          _movies = List<Map<String, dynamic>>.from(data['movies'] ?? []);
          _filteredMovies = _movies;
          _isLoading = false;
        });
        print('Loaded ${_movies.length} movies');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load showtimes';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMovies = _movies;
      } else {
        _filteredMovies =
            _movies
                .where(
                  (movie) => (movie['title'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _launchYoutubeUrl(String url) async {
    try {
      if (url.isEmpty) {
        print('YouTube URL is empty');
        return;
      }

      String formattedUrl = url.trim();

      if (!formattedUrl.startsWith('http://') &&
          !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }

      String? videoId = _extractYoutubeVideoId(formattedUrl);

      if (videoId != null) {
        final youtubeAppUri = Uri.parse(
          'youtube://www.youtube.com/watch?v=$videoId',
        );

        try {
          if (await canLaunchUrl(youtubeAppUri)) {
            await launchUrl(
              youtubeAppUri,
              mode: LaunchMode.externalApplication,
            );
            return;
          }
        } catch (e) {
          print('YouTube app not available, trying browser');
        }
      }

      final Uri webUri = Uri.parse(formattedUrl);

      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        try {
          await launchUrl(webUri);
        } catch (e) {
          print('Failed to launch URL: $e');
        }
      }
    } catch (e) {
      print('Error launching YouTube URL: $e');
    }
  }

  String? _extractYoutubeVideoId(String url) {
    try {
      if (url.contains('watch?v=')) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      }
      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          final videoId = parts[1].split('?').first.split('&').first;
          return videoId.isNotEmpty ? videoId : null;
        }
      }
    } catch (e) {
      print('Error extracting video ID: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B1967),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CustomAppBar()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (widget.onBackPressed != null) {
                                widget.onBackPressed!.call();
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.locationName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.locationAddress,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search movies...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 16),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              if (widget.cinemaId != null) {
                                _fetchCinemaShowtimes(widget.cinemaId!);
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredMovies.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_filter_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No movies found',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final movie = _filteredMovies[index];
                      final title = movie['title'] ?? 'Unknown';
                      final posterPath = movie['posterPath'] ?? '';
                      final rating = movie['voteAverage'] ?? 0;
                      final releaseDate = movie['releaseDate'] ?? '';
                      final youtubeUrl = movie['youtubeUrl'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          final movieData = <String, String>{
                            'title': title.toString(),
                            'backdrop': posterPath.toString(),
                            'image': posterPath.toString(),
                            'rating': rating.toString(),
                            'year':
                                releaseDate.isNotEmpty
                                    ? DateTime.parse(
                                      releaseDate,
                                    ).year.toString()
                                    : '',
                          };

                          final tmdbId = (movie['tmdbId'] ?? '').toString();

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => ShowTimeScreen(
                                    movie: movieData,
                                    tmdbId: tmdbId,
                                    backdropPath: posterPath.toString(),
                                    onBackPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Image.network(
                                    posterPath,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) {
                                      return Container(
                                        width: double.infinity,
                                        height: 250,
                                        color: Colors.black26,
                                        child: const Icon(
                                          Icons.movie,
                                          color: Colors.white24,
                                          size: 60,
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child:
                                        rating != null && rating != 0
                                            ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.7,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star_border_outlined,
                                                    color: AppColors.goldStar,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rating.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : const SizedBox.shrink(),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: GestureDetector(
                                      onTap:
                                          youtubeUrl.isNotEmpty
                                              ? () =>
                                                  _launchYoutubeUrl(youtubeUrl)
                                              : null,
                                      child: Container(
                                        width: 40,
                                        height: 40,
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
                                                  .withOpacity(0.5),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          color:
                                              youtubeUrl.isNotEmpty
                                                  ? Colors.white
                                                  : Colors.white54,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              releaseDate.isNotEmpty
                                  ? DateTime.parse(releaseDate).year.toString()
                                  : '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _filteredMovies.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
