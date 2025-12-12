import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cinematick/config/secrets.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Cinema Chains
  Future<List<Map<String, dynamic>>> fetchCinemaChains() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cinemas/chains'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load cinema chains');
    } catch (e) {
      throw Exception('Error fetching cinema chains: $e');
    }
  }

  // Cinema Locations
  Future<List<Map<String, dynamic>>> fetchCinemaLocations(
    String chainId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cinemas?chain_id=$chainId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load cinema locations');
    } catch (e) {
      throw Exception('Error fetching cinema locations: $e');
    }
  }

  // Cinema Showtimes
  Future<Map<String, dynamic>> fetchCinemaShowtimes(String cinemaId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cinemas/$cinemaId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load showtimes');
    } catch (e) {
      throw Exception('Error fetching showtimes: $e');
    }
  }

  // Movie Showtimes (TMDB)
  Future<List<Map<String, dynamic>>> fetchMovieShowtimes(String tmdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$tmdbId/showtimes'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load movie showtimes');
    } catch (e) {
      throw Exception('Error fetching movie showtimes: $e');
    }
  }

  // Fetch all movies (consolidates MovieService.fetchMovies logic)
  Future<List<Map<String, dynamic>>> fetchMovies() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/movies'),
            headers: {'Content-Type': 'application/json'},
          )
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
      throw Exception('Failed to load movies: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load movies: $e');
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
      'backdropPath': movie['backdropPath'] ?? movie['backdrop_path'] ?? '',
      'posterPath': movie['posterPath'] ?? movie['poster_path'] ?? '',
      'image': movie['image'] ?? '',
      'rating': (movie['voteAverage'] ?? 0).toString(),
      'year': _extractYear(
        movie['releaseDate'] ?? movie['release_date'] ?? movie['year'] ?? '',
      ),
      'description': movie['overview'] ?? movie['description'] ?? '',
      'genres': movie['genres'] ?? movie['genre_names'] ?? [],
      'language': langCode,
      'langCode': langCode,
      'original_language': langCode,
      'iso_639_1': langCode,
      'popularity': movie['popularity'] ?? 0,
      'voteAverageNum': movie['voteAverage'] ?? 0,
      'status': movie['status'] ?? 'Released',
      'youtubeUrl':
          movie['youtubeUrl'] ??
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
                'english')
            .toString()
            .toLowerCase()
            .trim();

    return langNameToCodeMap[rawLang] ?? 'en';
  }

  String _extractYear(dynamic dateOrYear) {
    if (dateOrYear == null) return '';
    final str = dateOrYear.toString();
    return str.length >= 4 ? str.substring(0, 4) : str;
  }
}
