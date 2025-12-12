import 'package:cinematick/core/services/api_service.dart';

class CinemaRepository {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getCinemaChains() =>
      _apiService.fetchCinemaChains();

  Future<List<Map<String, dynamic>>> getCinemaLocations(String chainId) =>
      _apiService.fetchCinemaLocations(chainId);

  Future<Map<String, dynamic>> getCinemaShowtimes(String cinemaId) =>
      _apiService.fetchCinemaShowtimes(cinemaId);

  Future<List<Map<String, dynamic>>> getMovieShowtimes(String tmdbId) =>
      _apiService.fetchMovieShowtimes(tmdbId);
}
