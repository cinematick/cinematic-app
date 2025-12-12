import 'dart:convert';

class MovieFilterService {
  static const Map<String, String> langCodeMap = {
    'English': 'en',
    'Hindi': 'hi',
    'Telugu': 'te',
    'Tamil': 'ta',
    'Kannada': 'kn',
    'Malayalam': 'ml',
    'Punjabi': 'pa',
    'Korean': 'ko',
    'Japanese': 'ja',
    'Italian': 'it',
    'Mandarin': 'zh',
  };

  static const Set<String> supportedLangCodes = {
    'en',
    'hi',
    'te',
    'ta',
    'kn',
    'ml',
    'pa',
    'ko',
    'ja',
    'it',
    'zh',
  };

  List<Map<String, dynamic>> filterMovies(
    List<Map<String, dynamic>> movies,
    List<bool> langSelected,
    List<bool> genreSelected,
    String status,
  ) {
    return filterMoviesByStatus(movies, langSelected, genreSelected, [status]);
  }

  List<Map<String, dynamic>> filterMoviesByStatus(
    List<Map<String, dynamic>> movies,
    List<bool> langSelected,
    List<bool> genreSelected,
    List<String> statuses,
  ) {
    final activeLangCodes = _getActiveLangCodes(langSelected);
    final activeGenres = _getActiveGenres(genreSelected);
    final statusesLower = statuses.map((s) => s.toLowerCase()).toSet();

    return movies.where((movie) {
      final movieStatus =
          (movie['status'] ?? '').toString().toLowerCase().trim();
      if (!statusesLower.contains(movieStatus)) return false;

      if (activeLangCodes.isNotEmpty) {
        final langCode =
            (movie['langCode'] ?? movie['language'] ?? 'en')
                .toString()
                .toLowerCase()
                .trim();
        if (!activeLangCodes.contains(langCode)) return false;
      }

      if (activeGenres.isNotEmpty) {
        if (!_matchesGenres(movie['genres'] ?? [], activeGenres)) return false;
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> sortAndLimitTrendingMovies(
    List<Map<String, dynamic>> movies,
    int limit,
  ) {
    final sorted = List<Map<String, dynamic>>.from(movies);
    sorted.sort((a, b) {
      final va = _getVoteAverage(a);
      final vb = _getVoteAverage(b);
      final cmp = vb.compareTo(va);
      if (cmp != 0) return cmp;

      final pa = _getPopularity(a);
      final pb = _getPopularity(b);
      return pb.compareTo(pa);
    });
    return sorted.length > limit ? sorted.sublist(0, limit) : sorted;
  }

  Set<String> _getActiveLangCodes(List<bool> langSelected) {
    final codes = <String>{};
    final allLanguages = langCodeMap.keys.toList();
    for (int i = 0; i < langSelected.length && i < allLanguages.length; i++) {
      if (langSelected[i]) {
        final code = langCodeMap[allLanguages[i]];
        if (code != null) codes.add(code.toLowerCase());
      }
    }
    return codes;
  }

  Set<String> _getActiveGenres(List<bool> genreSelected) {
    final allGenres = [
      'Action',
      'Comedy',
      'Drama',
      'Sci-Fi',
      'Horror',
      'Romance',
      'Thriller',
    ];
    final genres = <String>{};
    for (int i = 0; i < genreSelected.length && i < allGenres.length; i++) {
      if (genreSelected[i]) {
        genres.add(_normGenre(allGenres[i]));
      }
    }
    return genres;
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

  bool _matchesGenres(dynamic rawGenres, Set<String> activeGenres) {
    final tokens = _genreTokens(rawGenres).map(_normGenre);
    return tokens.any((g) => activeGenres.contains(g));
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

  double _getVoteAverage(Map<String, dynamic> movie) {
    if (movie['voteAverageNum'] is num)
      return (movie['voteAverageNum'] as num).toDouble();
    return double.tryParse('${movie['rating']}') ?? 0.0;
  }

  double _getPopularity(Map<String, dynamic> movie) {
    if (movie['popularity'] is num)
      return (movie['popularity'] as num).toDouble();
    return double.tryParse('${movie['popularity']}') ?? 0.0;
  }
}
