import 'package:cinematick/widgets/app_colors.dart';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:cinematick/widgets/info_row_card.dart';
import 'package:cinematick/widgets/theatre_tile.dart';

class ShowTimeScreen extends StatefulWidget {
  final Map<String, String>? movie;
  final VoidCallback? onBackPressed;

  const ShowTimeScreen({super.key, this.movie, this.onBackPressed});
  @override
  State<ShowTimeScreen> createState() => _ShowTimeScreenState();
}

class _ShowTimeScreenState extends State<ShowTimeScreen> {
  int selectedDateIndex = 0;
  int selectedLangIndex = 0;
  int selectedInfoIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    _langSelected = List<bool>.filled(_allLanguages.length, false);
    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);
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
        mv?['backdrop'] ??
        mv?['image'] ??
        'https://picsum.photos/800/500?blur=3';
    final title = mv?['title'] ?? 'Bad Boys: Ride or Die';
    final rating = mv?['rating'] ?? '7.1';

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
                            if (widget.onBackPressed != null) {
                              widget.onBackPressed!.call();
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 26,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                              letterSpacing: 0.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 9),
                          Row(
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                color: AppColors.goldStar,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '$rating/10',
                                style: TextStyle(
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
                  margin: EdgeInsets.only(top: 20, bottom: 3),
                  height: 52,
                  width: double.infinity,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    itemCount: dateList.length,
                    itemBuilder: (context, i) {
                      final selected = i == selectedDateIndex;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: i == 0 ? 14 : 10,
                          right: 0,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedDateIndex = i),
                          child: Container(
                            width: 61,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              // CHANGED: use filter gradient when selected
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
                                  dateList[i]['label']!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.90),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${dateList[i]['num']} ${dateList[i]['month']}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: TheatreTile(theatre: theatres[0], highlight: true),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, idx) {
                  if (idx == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: TheatreTile(theatre: theatres[idx]),
                  );
                }, childCount: theatres.length),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
