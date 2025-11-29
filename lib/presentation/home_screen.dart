import 'dart:convert';
import 'package:cinematick/widgets/custom_app_bar.dart';
import 'package:cinematick/widgets/filter_sheet.dart';
import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import 'package:cinematick/presentation/show_time_screen.dart';
import 'dart:async';
import 'package:cinematick/widgets/search_bar.dart';
import 'package:cinematick/data/trending_movies_json.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tabIndex = 0;
  int trendingPage = 0;
  String selectedLanguage = 'English';
  int selectedLangIndex = 0;
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
    'Sci-Fi',
    'Horror',
    'Romance',
    'Thriller',
  ];
  List<bool> _langSelected = [];
  List<bool> _xpSelected = [];
  List<bool> _genreSelected = [];

  PageController? _trendingController;
  Timer? _autoScrollTimer;

  final List<String> _searchHints = const [
    'Find premium theatres',
    'Search movies & shows',
    'Discover IMAX & 3D',
    'Browse by language',
  ];
  int _hintIndex = 0;
  Timer? _hintTimer;

  List<Map<String, dynamic>> trendingMovies = [];

  static const Map<String, String> _langCodeMap = {
    'English': 'en',
    'Hindi': 'hi',
    'Telugu': 'te',
    'Tamil': 'ta',
    'Kannada': 'kn',
    'Malayalam': 'ml',
    'Punjabi': 'pa',
    'Korean': 'ko',
    'Japanese': 'ja',
  };

  static const Set<String> _supportedLangCodes = {
    'en',
    'hi',
    'te',
    'ta',
    'kn',
    'ml',
    'pa',
    'ko',
    'ja',
  };

  static const Map<String, String> _langNameToCode = {
    'english': 'en',
    'hindi': 'hi',
    'telugu': 'te',
    'tamil': 'ta',
    'kannada': 'kn',
    'malayalam': 'ml',
    'punjabi': 'pa',
    'korean': 'ko',
    'japanese': 'ja',
    'eng': 'en',
    'hin': 'hi',
    'tel': 'te',
    'tam': 'ta',
    'kan': 'kn',
    'mal': 'ml',
    'pan': 'pa',
    'kor': 'ko',
    'jpn': 'ja',
  };

  String? _extractLangCode(Map<String, dynamic> m) {
    String? _normalizeCandidate(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return _normalizeCandidate(v.first);
      if (v is Map) {
        if (v.containsKey('code')) return _normalizeCandidate(v['code']);
        if (v.containsKey('iso') || v.containsKey('iso_639_1')) {
          return _normalizeCandidate(v['iso'] ?? v['iso_639_1']);
        }
        if (v.containsKey('name')) return _normalizeCandidate(v['name']);
        return null;
      }
      final s = v.toString().trim().toLowerCase();
      if (s.isEmpty) return null;
      final tokens = s
          .split(RegExp(r'[,\|/]+'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty);
      for (var t in tokens) {
        if (t.contains('-') || t.contains('_')) {
          t = t.split(RegExp(r'[-_]')).first.trim();
        }
        if (_supportedLangCodes.contains(t)) return t;
        final mapped = _langNameToCode[t];
        if (mapped != null) return mapped;
      }
      return null;
    }

    final candidates = <dynamic>[
      m['langCode'],
      m['original_language'],
      m['originalLang'],
      m['lang'],
      m['language'],
      m['originalLanguage'],
      m['iso_639_1'],
      m['iso'],
      m['code'],
      m['spoken_languages'],
      m['spokenLanguage'],
    ];

    for (final c in candidates) {
      final code = _normalizeCandidate(c);
      if (code != null) return code;
    }
    return null;
  }

  String _normGenre(String g) {
    var s = g.toLowerCase().trim();
    s = s.replaceAll('science fiction', 'sci-fi');
    s = s.replaceAll(
      RegExp(r'sci[\s\u00A0\u2009\u2011\u2012\u2013\u2014\u2212]*fi'),
      'sci-fi',
    );
    s = s.replaceAll(RegExp(r'[^a-z0-9\-\s]+'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll('sci fi', 'sci-fi');
    return s.trim();
  }

  List<Map<String, dynamic>> get _filteredTrendingMovies {
    final Set<String> activeLangCodes = <String>{};
    final anySelected = _langSelected.contains(true);
    if (anySelected) {
      for (int i = 0; i < _allLanguages.length; i++) {
        if (_langSelected[i]) {
          final code = _langCodeMap[_allLanguages[i]];
          if (code != null && code.isNotEmpty) {
            activeLangCodes.add(code.toLowerCase());
          }
        }
      }
    } else {
      final fallbackLang = langList[selectedLangIndex];
      final code = _langCodeMap[fallbackLang];
      if (code != null && code.isNotEmpty) {
        activeLangCodes.add(code.toLowerCase());
      }
    }

    final bool anyGenreSelected = _genreSelected.contains(true);
    final Set<String> activeGenres = <String>{};
    if (anyGenreSelected) {
      for (int i = 0; i < _allGenres.length; i++) {
        if (_genreSelected[i]) activeGenres.add(_normGenre(_allGenres[i]));
      }
    }

    String? _normalizeLang(dynamic raw) {
      if (raw == null) return null;
      if (raw is List && raw.isNotEmpty) return _normalizeLang(raw.first);
      if (raw is Map) {
        if (raw.containsKey('code')) return _normalizeLang(raw['code']);
        if (raw.containsKey('iso') || raw.containsKey('iso_639_1')) {
          return _normalizeLang(raw['iso'] ?? raw['iso_639_1']);
        }
        if (raw.containsKey('name')) return _normalizeLang(raw['name']);
        raw = raw.toString();
      }
      var s = raw.toString().trim().toLowerCase();
      if (s.isEmpty) return null;
      if (s.contains('-') || s.contains('_')) {
        s = s.split(RegExp(r'[-_]')).first.trim();
      }
      if (_supportedLangCodes.contains(s)) return s;
      final mapped = _langNameToCode[s];
      if (mapped != null) return mapped;
      final alpha = s.replaceAll(RegExp(r'[^a-z]'), '');
      return _langNameToCode[alpha] ?? (s.length == 2 ? s : null);
    }

    Iterable<String> _genreTokens(dynamic raw) sync* {
      if (raw == null) return;
      if (raw is List) {
        for (final e in raw) {
          final s = (e ?? '').toString().trim();
          if (s.isNotEmpty) yield s;
        }
        return;
      }
      final s = raw.toString().trim();
      if (s.isEmpty) return;
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            for (final e in decoded) {
              final t = (e ?? '').toString().trim();
              if (t.isNotEmpty) yield t;
            }
            return;
          }
        } catch (_) {}
      }
      for (final part in s.split(RegExp(r'[,\|/]'))) {
        final t = part.trim();
        if (t.isNotEmpty) yield t;
      }
    }

    bool _matchesGenres(dynamic rawGenres) {
      if (!anyGenreSelected) return true;
      for (final g in _genreTokens(rawGenres).map(_normGenre)) {
        if (activeGenres.contains(g)) return true;
      }
      return false;
    }

    final out = <Map<String, dynamic>>[];
    for (final item in trendingMovies) {
      if (item is! Map<String, dynamic>) continue;
      final m = item;
      final langCode = _normalizeLang(
        m['langCode'] ??
            _extractLangCode(m) ??
            m['original_language'] ??
            m['originalLang'] ??
            m['lang'] ??
            m['language'] ??
            m['spoken_languages'] ??
            m['iso_639_1'] ??
            m['iso'] ??
            m['code'],
      );

      if (langCode == null || !activeLangCodes.contains(langCode)) continue;
      if (!_matchesGenres(m['genres'] ?? m['genre'] ?? m['genreList']))
        continue;

      out.add(m);
    }
    return out;
  }

  List<Map<String, dynamic>> get _trendingTop10 =>
      (() {
        final data = List<Map<String, dynamic>>.from(_filteredTrendingMovies);
        data.sort((a, b) {
          final va =
              (a['voteAverageNum'] is num)
                  ? (a['voteAverageNum'] as num).toDouble()
                  : double.tryParse('${a['rating']}') ?? 0.0;
          final vb =
              (b['voteAverageNum'] is num)
                  ? (b['voteAverageNum'] as num).toDouble()
                  : double.tryParse('${b['rating']}') ?? 0.0;

          final cmp = vb.compareTo(va);
          if (cmp != 0) return cmp;

          final pa =
              (a['popularity'] is num)
                  ? (a['popularity'] as num).toDouble()
                  : double.tryParse('${a['popularity']}') ?? 0.0;
          final pb =
              (b['popularity'] is num)
                  ? (b['popularity'] as num).toDouble()
                  : double.tryParse('${b['popularity']}') ?? 0.0;
          return pb.compareTo(pa);
        });
        return data.length > 10 ? data.sublist(0, 10) : data;
      })();

  List<Map<String, dynamic>> get _filteredNowPlayingMovies =>
      _filteredTrendingMovies;

  void _toggleChip(int idx) {
    if (idx < 0 || idx >= _langSelected.length) return;
    setState(() {
      _langSelected[idx] = !_langSelected[idx];
      if (!_langSelected.contains(true)) {
        selectedLangIndex = idx;
      } else if (!_langSelected[selectedLangIndex]) {
        final first = _langSelected.indexWhere((e) => e);
        if (first != -1) selectedLangIndex = first;
      }
      trendingPage = 0;
    });
  }

  void _syncChipFromDrawer() {
    if (_langSelected.contains(true)) {
      final first = _langSelected.indexWhere((e) => e);
      if (first != -1) selectedLangIndex = first;
    } else {}
  }

  @override
  void initState() {
    super.initState();
    _langSelected = List<bool>.filled(_allLanguages.length, false);
    _xpSelected = List<bool>.filled(_allExperiences.length, false);
    _genreSelected = List<bool>.filled(_allGenres.length, false);

    try {
      final parsed = parseTrendingMovies();
      if (parsed is List) {
        trendingMovies =
            parsed.map<Map<String, dynamic>>((e) {
              if (e is Map<String, dynamic>) return e;
              if (e is Map) return Map<String, dynamic>.from(e);
              return <String, dynamic>{};
            }).toList();
      } else {
        trendingMovies = <Map<String, dynamic>>[];
      }
    } catch (err) {
      trendingMovies = <Map<String, dynamic>>[];
    }

    _trendingController = PageController(
      viewportFraction: 0.93,
      initialPage: trendingPage,
    );
    _startAutoScroll();
    _startHintCycle();
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

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final count = _trendingTop10.length;
      if (count <= 1) return;

      if (_trendingController == null || !_trendingController!.hasClients)
        return;

      final nextPage = (trendingPage + 1) % count;
      try {
        _trendingController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
        if (mounted) setState(() => trendingPage = nextPage);
      } catch (e) {}
    });
  }

  void _startHintCycle() {
    _hintTimer?.cancel();
    if (_searchHints.isEmpty) return;
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _hintIndex = (_hintIndex + 1) % _searchHints.length;
      });
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _trendingController?.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  final nowPlayingMovies = [
    {
      'title': 'Bad Boys: Ride or Die',
      'image': 'https://picsum.photos/800/500?blur=3',
      'rating': '7.1',
      'year': '2024',
    },
    {
      'title': 'A Quiet Place: Day One',
      'image': 'https://picsum.photos/800/500?blur=3',
      'rating': '6.9',
      'year': '2024',
    },
    {
      'title': 'Gladiator II',
      'image': 'https://picsum.photos/800/500?blur=4',
      'rating': '7.3',
      'year': '2024',
    },
    {
      'title': 'Moana 2',
      'image': 'https://picsum.photos/800/500?blur=2',
      'rating': '7.5',
      'year': '2024',
    },
  ];

  final List<String> languages = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
  ];
  final langList = [
    'English',
    'Hindi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Malayalam',
  ];
  Widget _tabChip(String label, int index, IconData icon) {
    final bool selected = tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.tabUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border:
              selected
                  ? null
                  : Border.all(color: AppColors.borderWhite10, width: 1),
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

  void _openShowTime([Map<String, dynamic>? movie]) {
    Map<String, String>? safe;
    if (movie != null) {
      safe = Map<String, String>.fromEntries(
        movie.entries.map((e) => MapEntry(e.key, e.value?.toString() ?? '')),
      );
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ShowTimeScreen(movie: safe)));
  }

  bool get _useCarousel => _trendingTop10.length <= 20;

  String _posterOrImage(Map<String, dynamic> m) {
    final poster = (m['poster'] ?? '').toString().trim();
    if (poster.isNotEmpty) return poster;
    return (m['image'] ?? '').toString();
  }

  Widget _PosterWithBackground(String url, {BoxFit fit = BoxFit.cover}) {
    final safeUrl = (url ?? '').toString().trim();
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
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.white24,
                          ),
                        ),
                      );
                    },
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

  Widget _ratingBadge(String rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardMetaBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border_rounded, size: 12, color: AppColors.cardStar),
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

  Widget _buildTrendingCard(Map<String, dynamic> movie, int i) {
    final thumb = (movie['image'] ?? '').toString();
    final safeThumb =
        thumb.isEmpty
            ? 'https://via.placeholder.com/300x450?text=No+Image'
            : thumb;
    final title = (movie['title'] ?? '').toString();
    final year = (movie['year'] ?? '').toString();
    final description = (movie['description'] ?? '').toString();
    final rating = (movie['rating'] ?? '0').toString();

    return GestureDetector(
      onTap: () => _openShowTime(movie),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        margin: EdgeInsets.symmetric(
          horizontal: 6,
          vertical: _useCarousel && trendingPage == i ? 0 : 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                _useCarousel && trendingPage == i ? 0.21 : 0.10,
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
              _PosterWithBackground(safeThumb),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // NEW: rating + year in a single row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardMetaBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
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
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      const SizedBox(height: 8),
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

  Widget _buildTrendingCarouselOrList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final data = _trendingTop10;
    _ensureTrendingPageValid();
    if (_useCarousel && data.length <= 20) {
      return Container(
        height: 250,
        child: PageView.builder(
          controller: _trendingController,
          itemCount: data.length,
          onPageChanged: (index) => setState(() => trendingPage = index),
          itemBuilder: (context, i) => _buildTrendingCard(data[i], i),
        ),
      );
    }
    return SizedBox(
      height: 250,
      child:
          data.isEmpty
              ? Center(
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
                itemBuilder: (context, i) {
                  return SizedBox(
                    width: width * 0.93,
                    child: _buildTrendingCard(data[i], i),
                  );
                },
              ),
    );
  }

  final int _maxIndicatorDots = 12;

  Widget _buildTrendingIndicators() {
    final total = _trendingTop10.length;
    if (!_useCarousel || total == 0) return const SizedBox.shrink();
    if (total <= _maxIndicatorDots) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == trendingPage;
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
    int start = trendingPage - (_maxIndicatorDots ~/ 2);
    if (start < 0) start = 0;
    int end = start + _maxIndicatorDots;
    if (end > total) {
      end = total;
      start = end - _maxIndicatorDots;
    }
    final window = List<int>.generate(end - start, (i) => start + i);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (start > 0) ...[_ellipsisDot()],
        ...window.map((i) {
          final active = i == trendingPage;
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
        }).toList(),
        if (end < total) ...[_ellipsisDot()],
      ],
    );
  }

  Widget _ellipsisDot() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: const Text(
        '…',
        style: TextStyle(color: Colors.white38, fontSize: 12, height: 1),
      ),
    );
  }

  void _ensureTrendingPageValid() {
    final len = _trendingTop10.length;
    if (len == 0)
      trendingPage = 0;
    else if (trendingPage >= len)
      trendingPage = 0;
  }

  void _onFiltersApplied() {
    setState(() {
      _syncChipFromDrawer();
      trendingPage = 0;
      _ensureTrendingPageValid();
    });
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    _ensureFiltersReady();
    _trendingController ??= PageController(
      viewportFraction: 0.93,
      initialPage: trendingPage,
    );
    if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
      _startAutoScroll();
    }
    if (_hintTimer == null || !_hintTimer!.isActive) {
      _startHintCycle();
    }

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
            setState(() {
              _syncChipFromDrawer();
              trendingPage = 0;
            });
            Navigator.of(context).maybePop();
            _onFiltersApplied();
          },
          onClear: () {
            setState(() {
              for (var i = 0; i < _langSelected.length; i++)
                _langSelected[i] = false;
              for (var i = 0; i < _xpSelected.length; i++)
                _xpSelected[i] = false;
              for (var i = 0; i < _genreSelected.length; i++)
                _genreSelected[i] = false;
              selectedLangIndex = 0;
              trendingPage = 0;
            });
            _startAutoScroll();
          },
        ),
      ),
      backgroundColor: const Color(0xFF2B1967),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),

          child: Column(
            children: [
              CustomAppBar(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 7,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: SearchBarWidget(hint: _searchHints[_hintIndex]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 0, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _tabChip('Trending', 0, Icons.trending_up),
                          _tabChip(
                            'Now Playing',
                            1,
                            Icons.local_movies_outlined,
                          ),
                          _tabChip('Coming Soon', 2, Icons.schedule),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: langList.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap:
                                    () =>
                                        _scaffoldKey.currentState?.openDrawer(),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13),
                                    color: Colors.white.withOpacity(0.11),
                                  ),
                                  child: const Icon(
                                    Icons.filter_alt_outlined,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                            );
                          }
                          final langIdx = i - 1;
                          final anySelected = _langSelected.contains(true);
                          final selected =
                              anySelected
                                  ? _langSelected[langIdx]
                                  : (langIdx == selectedLangIndex);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _toggleChip(langIdx),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  color:
                                      selected
                                          ? AppColors.chipSelectedBg
                                          : AppColors.chipUnselectedBg,
                                ),
                                child: Text(
                                  langList[langIdx],
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  strutStyle: const StrutStyle(
                                    forceStrutHeight: true,
                                    height: 1.0,
                                    leading: 0,
                                  ),
                                  textHeightBehavior: const TextHeightBehavior(
                                    applyHeightToFirstAscent: false,
                                    applyHeightToLastDescent: false,
                                  ),
                                  style: TextStyle(
                                    height: 1.0,
                                    color:
                                        selected
                                            ? AppColors.chipSelectedText
                                            : AppColors.chipUnselectedText,
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
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tabIndex == 0) ...[
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: AppColors.white,
                                size: 21,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Trending Movies',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildTrendingCarouselOrList(context),
                          const SizedBox(height: 14),
                          _buildTrendingIndicators(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.local_movies_outlined,
                                color: AppColors.white,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'Now Playing',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (_filteredNowPlayingMovies.isEmpty)
                            Center(
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
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.66,
                                  ),
                              itemCount: _filteredNowPlayingMovies.length,
                              itemBuilder: (context, index) {
                                final movie = _filteredNowPlayingMovies[index];
                                final rating =
                                    (movie['rating'] ?? '0').toString();
                                return GestureDetector(
                                  onTap:
                                      () => _openShowTime(
                                        movie as Map<String, dynamic>?,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(14),
                                                  topRight: Radius.circular(14),
                                                ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                _PosterWithBackground(
                                                  _posterOrImage(movie),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: _ratingBadge(rating),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(9.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (movie['title'] ?? '')
                                                    .toString(),
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
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 14),
                        ] else if (tabIndex == 1) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Icon(
                                Icons.local_movies_outlined,
                                color: AppColors.white,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'Now Playing',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_filteredNowPlayingMovies.isEmpty)
                            Center(
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
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.66,
                                  ),
                              itemCount: _filteredNowPlayingMovies.length,
                              itemBuilder: (context, index) {
                                final movie = _filteredNowPlayingMovies[index];
                                final rating =
                                    (movie['rating'] ?? '0').toString();
                                return GestureDetector(
                                  onTap:
                                      () => _openShowTime(
                                        movie as Map<String, dynamic>?,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(14),
                                                  topRight: Radius.circular(14),
                                                ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                _PosterWithBackground(
                                                  _posterOrImage(movie),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: _ratingBadge(rating),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(9.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (movie['title'] ?? '')
                                                    .toString(),
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
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 14),
                        ] else ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: AppColors.white,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'Coming Soon',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_filteredNowPlayingMovies.isEmpty)
                            Center(
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
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.66,
                                  ),
                              itemCount: _filteredNowPlayingMovies.length,
                              itemBuilder: (context, index) {
                                final movie = _filteredNowPlayingMovies[index];
                                final rating =
                                    (movie['rating'] ?? '0').toString();
                                return GestureDetector(
                                  onTap:
                                      () => _openShowTime(
                                        movie as Map<String, dynamic>?,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(14),
                                                  topRight: Radius.circular(14),
                                                ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                _PosterWithBackground(
                                                  _posterOrImage(movie),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: _ratingBadge(rating),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(9.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (movie['title'] ?? '')
                                                    .toString(),
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
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
