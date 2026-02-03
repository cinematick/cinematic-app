import 'package:cinematick/core/services/api_service.dart';

class CinemaRepository {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getCinemaChains({
    required String region,
  }) => _apiService.fetchCinemaChains(region: region);

  Future<List<Map<String, dynamic>>> getCinemaLocations(
    String chainId, {
    required String region,
  }) => _apiService.fetchCinemaLocations(chainId, region: region);

  Future<Map<String, dynamic>> getCinemaShowtimes(
    String cinemaId, {
    required String region,
  }) => _apiService.fetchCinemaShowtimes(cinemaId, region: region);

  Future<List<Map<String, dynamic>>> getMovieShowtimes(
    String tmdbId, {
    required String region,
  }) => _apiService.fetchMovieShowtimes(tmdbId, region: region);

  Future<List<Map<String, dynamic>>> getMovies({
    required String region,
    String? language,
  }) => _apiService.fetchMovies(region: region, language: language);

  Future<List<Map<String, dynamic>>> getUpcomingMovies({
    required String region,
    String? language,
  }) => _apiService.fetchUpcomingMovies(region: region, language: language);
}
