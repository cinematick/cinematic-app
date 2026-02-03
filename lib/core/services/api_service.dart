import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cinematick/config/secrets.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<List<Map<String, dynamic>>> fetchCinemaChains({
    required String region,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cinemas/chains?region=$region'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load cinema chains');
    } catch (e) {
      throw Exception('Error fetching cinema chains');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCinemaLocations(
    String chainId, {
    required String region,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cinemas?chain_id=$chainId&region=$region'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load cinema locations');
    } catch (e) {
      throw Exception('Error fetching cinema locations');
    }
  }

  Future<Map<String, dynamic>> fetchCinemaShowtimes(
    String cinemaId, {
    required String region,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cinemas/$cinemaId?region=$region'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load showtimes');
    } catch (e) {
      throw Exception('Error fetching showtimes');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMovieShowtimes(
    String tmdbId, {
    required String region,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$tmdbId/showtimes?region=$region'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load movie showtimes');
    } catch (e) {
      throw Exception('Error fetching movie showtimes');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMovies({
    required String region,
    String? language,
  }) async {
    try {
      String url = '$baseUrl/movies/region/list?region=$region';
      if (language != null && language.isNotEmpty) {
        url += '&language=$language';
      }
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final movies = _extractMoviesList(jsonData);
        return movies.map<Map<String, dynamic>>((movie) {
          if (movie is Map<String, dynamic>) {
            return _normalizeMovieData(movie);
          }
          return <String, dynamic>{};
        }).toList();
      }
      throw Exception('Failed to load movies');
    } catch (e) {
      throw Exception('Failed to load movies');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUpcomingMovies({
    required String region,
    String? language,
  }) async {
    try {
      String url = '$baseUrl/movies/upcoming?region=$region';
      if (language != null && language.isNotEmpty) {
        url += '&language=$language';
      }
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final movies = _extractMoviesList(jsonData);
        return movies.map<Map<String, dynamic>>((movie) {
          if (movie is Map<String, dynamic>) {
            return _normalizeMovieData(movie);
          }
          return <String, dynamic>{};
        }).toList();
      }
      throw Exception('Failed to load upcoming movies');
    } catch (e) {
      throw Exception('Failed to load upcoming movies');
    }
  }

  List<dynamic> _extractMoviesList(dynamic jsonData) {
    if (jsonData is List) return jsonData;
    if (jsonData is Map) {
      if (jsonData.containsKey('movies')) return jsonData['movies'] ?? [];
      if (jsonData.containsKey('data')) return jsonData['data'] ?? [];
    }
    return [];
  }

  Map<String, dynamic> _normalizeMovieData(Map<String, dynamic> movie) {
    final langCode = _extractLanguageCode(movie);

    return <String, dynamic>{
      'title': movie['title'] ?? movie['name'] ?? 'Unknown',
      'tmdbId': movie['tmdb_id'] ?? movie['tmdbId'] ?? '',
      'backdropPath': _cleanImageUrl(
        movie['backdropPath'] ?? movie['backdrop_path'] ?? '',
      ),
      'posterPath': _cleanImageUrl(
        movie['posterPath'] ?? movie['poster_path'] ?? '',
      ),
      'image': _cleanImageUrl(movie['image'] ?? movie['poster_path'] ?? ''),
      'rating': (movie['voteAverage'] ?? movie['vote_average'] ?? 0).toString(),
      'year': _extractYear(
        movie['releaseDate'] ?? movie['release_date'] ?? movie['year'] ?? '',
      ),
      'description': movie['overview'] ?? movie['description'] ?? '',
      'genres':
          movie['genres'] ?? movie['genre_ids'] ?? movie['genre_names'] ?? [],
      'language': langCode,
      'langCode': langCode,
      'original_language': langCode,
      'iso_639_1': langCode,
      'popularity':
          double.tryParse(movie['popularity']?.toString() ?? '0') ?? 0,
      'voteAverageNum': movie['voteAverage'] ?? movie['vote_average'] ?? 0,
      'status': movie['status'] ?? 'Released',
      'youtubeUrl':
          movie['youtubeUrl'] ??
          movie['youtubeurl'] ??
          movie['trailerUrl'] ??
          movie['youtube_url'] ??
          '',
      ...movie,
    };
  }

  String _extractLanguageCode(Map<String, dynamic> movie) {
    final langNameToCodeMap = {
      'english': 'en',
      'hindi': 'hi',
      'telugu': 'te',
      'tamil': 'ta',
      'kannada': 'kn',
      'malayalam': 'ml',
      'punjabi': 'pa',
      'korean': 'ko',
      'japanese': 'ja',
      'french': 'fr',
      'spanish': 'es',
      'german': 'de',
      'italian': 'it',
      'mandarin': 'zh',
      'portuguese': 'pt',
      'russian': 'ru',
      'chinese': 'zh',
      'thai': 'th',
      'turkish': 'tr',
      'urdu': 'ur',
      'nepali': 'ne',
      'tagalog': 'tl',
      'finnish': 'fi',
    };

    final rawLang =
        (movie['language'] ??
                movie['originalLang'] ??
                movie['original_language'] ??
                'en')
            .toString()
            .toLowerCase()
            .trim();

    if (rawLang.length == 2) {
      return rawLang;
    }

    return langNameToCodeMap[rawLang] ?? 'en';
  }

  String _extractYear(dynamic dateOrYear) {
    if (dateOrYear == null) return '';
    final str = dateOrYear.toString();
    return str.length >= 4 ? str.substring(0, 4) : str;
  }

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';

    const baseUrl1 = 'https://image.tmdb.org/t/p/original';
    const baseUrl2 = 'https://image.tmdb.org/t/p/w500';

    if (url.contains('$baseUrl1$baseUrl1') ||
        url.contains('$baseUrl1$baseUrl2')) {
      return url
          .replaceFirst('$baseUrl1$baseUrl1', baseUrl1)
          .replaceFirst('$baseUrl1$baseUrl2', '$baseUrl2');
    }

    if (url.contains('$baseUrl2$baseUrl1') ||
        url.contains('$baseUrl2$baseUrl2')) {
      return url
          .replaceFirst('$baseUrl2$baseUrl1', '$baseUrl1')
          .replaceFirst('$baseUrl2$baseUrl2', baseUrl2);
    }

    return url;
  }
}
