import 'package:cinematick/config/secrets.dart';
import 'package:dio/dio.dart';
import 'package:cinematick/models/movie_model.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  Future<List<MovieModel>> getMovies() async {
    try {
      final response = await _dio.get('$baseUrl/movies');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((movie) => MovieModel.fromJson(movie)).toList();
      }
      throw Exception('Failed to load movies');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<MovieModel> getMovieById(String id) async {
    try {
      final response = await _dio.get('$baseUrl/movies/$id');

      if (response.statusCode == 200) {
        return MovieModel.fromJson(response.data);
      }
      throw Exception('Failed to load movie');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      final response = await _dio.get(
        '$baseUrl/movies/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((movie) => MovieModel.fromJson(movie)).toList();
      }
      throw Exception('Failed to search movies');
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    }
  }

  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      final allMovies = await getMovies();
      allMovies.sort((a, b) => b.popularity.compareTo(a.popularity));
      return allMovies.take(10).toList();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<MovieModel>> getMoviesByGenre(String genre) async {
    try {
      final allMovies = await getMovies();
      return allMovies.where((movie) => movie.genres.contains(genre)).toList();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
