import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/info_row_card.dart';
import 'package:cinematick/widgets/theatre_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShowTimeScreen extends StatefulWidget {
  final Map<String, String>? movie;
  final String tmdbId;
  final VoidCallback? onBackPressed;
  final String? backdropPath;

  const ShowTimeScreen({
    super.key,
    this.movie,
    required this.tmdbId,
    this.onBackPressed,
    this.backdropPath,
  });
  @override
  State<ShowTimeScreen> createState() => _ShowTimeScreenState();
}

class _ShowTimeScreenState extends State<ShowTimeScreen> {
  int selectedDateIndex = 0;
  int selectedLangIndex = 0;
  int selectedInfoIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _showtimes = [];
  String? _errorMessage;
  List<Map<String, dynamic>> _generatedDates = [];

  final List<String> _allLanguages = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Korean',
    'Japanese',
  ];
  final List<String> _allExperiences = ['2D', '3D', 'IMAX', 'Dolby'];
  final List<String> _allGenres = [
    'Action',
    'Comedy',
    'Drama',
    'Sci‑Fi',
    'Horror',
    'Romance',
    'Thriller',
  ];
  List<bool> _langSelected = [];
  List<bool> _xpSelected = [];
  List<bool> _genreSelected = [];

  @override
  void initState() {
    super.initState();
    print('TMDB ID: ${widget.tmdbId}');
    _langSelected = List<bool>.filled(_allLanguages.length, false);
    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);
    _fetchShowtimes();
  }

  Future<void> _fetchShowtimes() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://shark-app-t9il5.ondigitalocean.app/v1/movies/${widget.tmdbId}/showtimes',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _showtimes = List<Map<String, dynamic>>.from(data);
          _generatedDates = _generateDates();
          print(
            'Loaded ${_showtimes.length} showtimes with ${_generatedDates.length} unique dates',
          );
          for (var date in _generatedDates) {
            print(
              'Date: ${date['label']} ${date['num']} ${date['month']} (${date['dateStr']})',
            );
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load showtimes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchShowtimesForDate(String dateStr) async {
    try {
      print('Fetching showtimes for date: $dateStr');
      final response = await http.get(
        Uri.parse(
          'https://shark-app-t9il5.ondigitalocean.app/v1/movies/${widget.tmdbId}/showtimes',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final allShowtimes = List<Map<String, dynamic>>.from(data);

        final filteredShowtimes =
            allShowtimes.where((showtime) {
              String showtimeDateStr = showtime['start_time']
                  .toString()
                  .substring(0, 10);
              bool matches = showtimeDateStr == dateStr;
              print(
                'Showtime date: $showtimeDateStr, Selected: $dateStr, Match: $matches',
              );
              return matches;
            }).toList();

        setState(() {
          _showtimes = allShowtimes; 
          print('Total showtimes: ${allShowtimes.length}');
          print('Found ${filteredShowtimes.length} showtimes for $dateStr');
          print(
            'Filtered showtimes cinema names: ${filteredShowtimes.map((s) => s['cinema']['name']).toList()}',
          );
        });
      } else {
        print('Failed to load showtimes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching showtimes for date: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupShowtimesByTheater() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var showtime in _showtimes) {
      String theaterName = showtime['cinema']['name'] ?? 'Unknown';
      if (!grouped.containsKey(theaterName)) {
        grouped[theaterName] = [];
      }
      grouped[theaterName]!.add(showtime);
    }
    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> _groupShowtimesByDate(
    List<Map<String, dynamic>> showtimes,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var showtime in showtimes) {
      String dateStr = showtime['start_time'].toString().substring(0, 10);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(showtime);
    }
    return grouped;
  }

  List<Map<String, dynamic>> _generateDates() {
    if (_showtimes.isEmpty) {
      List<Map<String, dynamic>> dates = [];
      final now = DateTime.now();
      for (int i = 0; i < 6; i++) {
        final date = now.add(Duration(days: i));
        final dayName =
            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(date.weekday %
                7)];
        final monthName =
            [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ][date.month - 1];

        dates.add({
          'label': dayName,
          'num': date.day.toString(),
          'month': monthName,
          'dateStr':
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        });
      }
      return dates;
    }

    Set<String> uniqueDates = {};
    for (var showtime in _showtimes) {
      String dateStr = showtime['start_time'].toString().substring(0, 10);
      uniqueDates.add(dateStr);
    }

    List<String> sortedDates = uniqueDates.toList()..sort();
    List<Map<String, dynamic>> dates = [];

    for (var dateStr in sortedDates) {
      try {
        final dateObj = DateTime.parse(dateStr);
        final dayName =
            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][(dateObj.weekday %
                7)];
        final monthName =
            [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ][dateObj.month - 1];

        dates.add({
          'label': dayName,
          'num': dateObj.day.toString(),
          'month': monthName,
          'dateStr': dateStr,
        });
      } catch (e) {
        print('Error parsing date: $dateStr - $e');
      }
    }

    print(
      'Generated dates from API: ${dates.map((d) => d['dateStr']).toList()}',
    );
    return dates;
  }

  void _ensureFiltersReady() {
    if (_langSelected.length != _allLanguages.length) {
      _langSelected = List<bool>.filled(_allLanguages.length, false);
    }
    if (_xpSelected.length != _allExperiences.length) {
      _xpSelected = List<bool>.filled(_allExperiences.length, false);
    }
    if (_genreSelected.length != _allGenres.length) {
      _genreSelected = List<bool>.filled(_allGenres.length, false);
    }
  }

  final List<Map<String, dynamic>> theatres = [
    {
      'name': 'The Roxy Movie House',
      'address': '789 Picture Rd, Sydney',
      'distance': '8.3km',
      'rating': '4.2',
      'shows': [
        {'time': '21:00', 'price': 16, 'highlight': false},
      ],
    },
    {
      'name': 'Cineplex Grand Central',
      'address': '123 Movie Lane, Sydney',
      'distance': '2.5km',
      'rating': '4.5',
      'shows': [
        {'time': '19:15', 'price': 19, 'highlight': false},
      ],
    },
    {
      'name': 'Starlight Cinemas Downtown',
      'address': '456 Film Ave, Sydney',
      'distance': '5.1km',
      'rating': '4.8',
      'shows': [
        {'time': '20:00', 'price': 26, 'highlight': true},
      ],
    },
  ];

  final dateList = [
    {'label': 'Sun', 'num': '2', 'month': 'Nov'},
    {'label': 'Mon', 'num': '3', 'month': 'Nov'},
    {'label': 'Tue', 'num': '4', 'month': 'Nov'},
    {'label': 'Wed', 'num': '5', 'month': 'Nov'},
    {'label': 'Thu', 'num': '6', 'month': 'Nov'},
    {'label': 'Fri', 'num': '7', 'month': 'Nov'},
  ];

  final langList = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
  ];

  @override
  Widget build(BuildContext context) {
    final mv = widget.movie;
    final bannerImage =
        widget.backdropPath?.isNotEmpty == true
            ? widget.backdropPath!
            : (mv?['backdrop'] ??
                mv?['image'] ??
                'https://picsum.photos/800/500?blur=3');
    final title = mv?['title'] ?? 'Unknown Movie';
    final rating = mv?['rating'] ?? '0.0';

    _ensureFiltersReady();
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: FilterSheetWidget(
          allLanguages: _allLanguages,
          allExperiences: _allExperiences,
          allGenres: _allGenres,
          langSelected: _langSelected,
          xpSelected: _xpSelected,
          genreSelected: _genreSelected,
          onApply: () {
            Navigator.of(context).maybePop();
            setState(() {});
          },
          onClear: () {
            setState(() {
              for (var i = 0; i < _langSelected.length; i++)
                _langSelected[i] = false;
              for (var i = 0; i < _xpSelected.length; i++)
                _xpSelected[i] = false;
              for (var i = 0; i < _genreSelected.length; i++)
                _genreSelected[i] = false;
            });
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CustomAppBar()),
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: ClipRRect(
                        child: Image.network(
                          bannerImage,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey[800],
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color.fromARGB(
                              255,
                              58,
                              22,
                              103,
                            ).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(179, 47, 46, 46),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 26,
                      bottom: 24,
                      right: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 0.1,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                color: AppColors.goldStar,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$rating/10',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 3),
                  height: 70,
                  width: double.infinity,
                  child:
                      _generatedDates.isEmpty
                          ? const Center(
                            child: Text(
                              'Loading dates...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                          : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _generatedDates.length,
                            itemBuilder: (context, i) {
                              final selected = i == selectedDateIndex;
                              final dateData = _generatedDates[i];
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: i == 0 ? 14 : 10,
                                  right: 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    print(
                                      'Selected date index: $i, Date: ${dateData['dateStr']}',
                                    );
                                    setState(() => selectedDateIndex = i);
                                    _fetchShowtimesForDate(dateData['dateStr']);
                                  },
                                  child: Container(
                                    width: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient:
                                          selected
                                              ? AppColors.filterGradient
                                              : null,
                                      color:
                                          selected
                                              ? null
                                              : Colors.white.withOpacity(0.09),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dateData['label']!,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.90,
                                            ),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateData['num']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateData['month']!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ),
              SliverToBoxAdapter(
                child: Builder(
                  builder:
                      (context) => Container(
                        margin: EdgeInsets.only(top: 14, bottom: 10),
                        height: 32,
                        width: double.infinity,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          itemCount: langList.length + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  left: 18,
                                  right: 8,
                                ),
                                child: GestureDetector(
                                  onTap:
                                      () =>
                                          _scaffoldKey.currentState
                                              ?.openDrawer(),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(13),
                                      color: Colors.white.withOpacity(0.11),
                                    ),
                                    child: Icon(
                                      Icons.filter_alt,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final langIdx = i - 1;
                            final selected = langIdx == selectedLangIndex;
                            return Padding(
                              padding: EdgeInsets.only(left: 0, right: 8),
                              child: GestureDetector(
                                onTap:
                                    () => setState(
                                      () => selectedLangIndex = langIdx,
                                    ),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(horizontal: 18),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13),
                                    color:
                                        selected
                                            ? AppColors.white
                                            : Colors.white.withOpacity(0.11),
                                  ),
                                  child: Text(
                                    langList[langIdx],
                                    strutStyle: const StrutStyle(
                                      forceStrutHeight: true,
                                      height: 1.0,
                                      leading: 0,
                                    ),
                                    textHeightBehavior:
                                        const TextHeightBehavior(
                                          applyHeightToFirstAscent: false,
                                          applyHeightToLastDescent: false,
                                        ),
                                    style: TextStyle(
                                      height: 1.0,
                                      color:
                                          selected
                                              ? Colors.black
                                              : Colors.white60,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: InfoRowCard(
                    selected: selectedInfoIndex,
                    onChanged: (idx) => setState(() => selectedInfoIndex = idx),
                  ),
                ),
              ),
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                )
              else if (_showtimes.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No showtimes available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_generatedDates.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No dates available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      }

                      final safeIndex =
                          selectedDateIndex >= _generatedDates.length
                              ? 0
                              : selectedDateIndex;
                      final selectedDate =
                          _generatedDates[safeIndex]['dateStr'];

                      final groupedByDate = _groupShowtimesByDate(_showtimes);
                      final showtimesForDate =
                          groupedByDate[selectedDate] ?? [];

                      final selectedLanguage = _allLanguages[selectedLangIndex];
                      final filteredShowtimes =
                          showtimesForDate.where((showtime) {
                            final language = showtime['language'] ?? '';
                            return language.toString().toLowerCase().contains(
                              selectedLanguage.toLowerCase(),
                            );
                          }).toList();

                      final groupedByTheatre =
                          <String, List<Map<String, dynamic>>>{};
                      for (var showtime in filteredShowtimes) {
                        final theatreName =
                            showtime['cinema']['name'] ?? 'Unknown';
                        if (!groupedByTheatre.containsKey(theatreName)) {
                          groupedByTheatre[theatreName] = [];
                        }
                        groupedByTheatre[theatreName]!.add(showtime);
                      }

                      if (index == 0 && filteredShowtimes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white30,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No showtimes in $selectedLanguage on ${_generatedDates[safeIndex]['label']} ${_generatedDates[safeIndex]['num']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (index >= groupedByTheatre.length) {
                        return const SizedBox.shrink();
                      }

                      final theatreName = groupedByTheatre.keys.toList()[index];
                      final theatreShowtimes = groupedByTheatre[theatreName]!;
                      final firstShowtime = theatreShowtimes.first;
                      final cinema = firstShowtime['cinema'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF5A1EA9), Color(0xFF3A0E68)],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name + address
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              theatreName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    cinema['address'] ??
                                                        cinema['city'] ??
                                                        'Unknown location',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFA726),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  '4.2',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E88E5),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              '8.3km',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.25),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(22),
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: SizedBox(
                                    height: 70,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: theatreShowtimes.length,
                                      itemBuilder: (context, idx) {
                                        final showtime = theatreShowtimes[idx];
                                        final seats =
                                            (showtime['seats'] as List?)
                                                ?.cast<
                                                  Map<String, dynamic>
                                                >() ??
                                            [];
                                        final minPrice =
                                            seats.isNotEmpty
                                                ? seats
                                                    .map(
                                                      (s) => s['price'] as num,
                                                    )
                                                    .reduce(
                                                      (a, b) => a < b ? a : b,
                                                    )
                                                : 0;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            right:
                                                idx ==
                                                        theatreShowtimes
                                                                .length -
                                                            1
                                                    ? 0
                                                    : 10,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                width: 0.7,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _formatTime(
                                                    showtime['start_time'],
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '\$$minPrice',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
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
                          ),
                        ),
                        );
                      },
                    childCount:
                        _generatedDates.isEmpty
                            ? 0
                            : (() {
                              final safeIndex =
                                  selectedDateIndex >= _generatedDates.length
                                      ? 0
                                      : selectedDateIndex;
                              final selectedDate =
                                  _generatedDates[safeIndex]['dateStr'];
                              final selectedLanguage =
                                  _allLanguages[selectedLangIndex];

                              final groupedByDate = _groupShowtimesByDate(
                                _showtimes,
                              );
                              final showtimesForDate =
                                  groupedByDate[selectedDate] ?? [];
                              final filteredShowtimes =
                                  showtimesForDate.where((showtime) {
                                    final language = showtime['language'] ?? '';
                                    return language
                                        .toString()
                                        .toLowerCase()
                                        .contains(
                                          selectedLanguage.toLowerCase(),
                                        );
                                  }).toList();

                              final groupedByTheatre =
                                  <String, List<Map<String, dynamic>>>{};
                              for (var showtime in filteredShowtimes) {
                                final theatreName =
                                    showtime['cinema']['name'] ?? 'Unknown';
                                if (!groupedByTheatre.containsKey(
                                  theatreName,
                                )) {
                                  groupedByTheatre[theatreName] = [];
                                }
                                groupedByTheatre[theatreName]!.add(showtime);
                              }

                              return groupedByTheatre.length;
                            }()),
                  ),
                ),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
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
}
