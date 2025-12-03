import 'dart:convert';
import 'package:cinematick/config/secrets.dart';
import 'package:http/http.dart' as http;

class MovieService {
  static const String _apiUrl =
      '$baseUrl/movies';

  Future<List<Map<String, dynamic>>> fetchMovies() async {
    try {
      final response = await http
          .get(
            Uri.parse(_apiUrl),
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
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (err) {
      throw Exception('Failed to load movies: $err');
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
