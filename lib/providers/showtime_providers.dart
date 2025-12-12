import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/repositories/cinema_repository.dart';

// Cinema Showtimes Provider
final cinemaShowtimeProvider = StateNotifierProvider.family<
  CinemaShowtimeNotifier,
  CinemaShowtimeState,
  String
>((ref, cinemaId) {
  return CinemaShowtimeNotifier(cinemaId, ref.watch(repositoryProvider));
});

final repositoryProvider = Provider((ref) => CinemaRepository());

class CinemaShowtimeState {
  final List<Map<String, dynamic>> movies;
  final List<Map<String, dynamic>> filteredMovies;
  final Map<String, dynamic>? cinemaDetails;
  final bool isLoading;
  final String? errorMessage;

  CinemaShowtimeState({
    this.movies = const [],
    this.filteredMovies = const [],
    this.cinemaDetails,
    this.isLoading = true,
    this.errorMessage,
  });

  CinemaShowtimeState copyWith({
    List<Map<String, dynamic>>? movies,
    List<Map<String, dynamic>>? filteredMovies,
    Map<String, dynamic>? cinemaDetails,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CinemaShowtimeState(
      movies: movies ?? this.movies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      cinemaDetails: cinemaDetails ?? this.cinemaDetails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CinemaShowtimeNotifier extends StateNotifier<CinemaShowtimeState> {
  final String cinemaId;
  final CinemaRepository _repository;

  CinemaShowtimeNotifier(this.cinemaId, this._repository)
    : super(CinemaShowtimeState()) {
    fetchShowtimes();
  }

  Future<void> fetchShowtimes() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.getCinemaShowtimes(cinemaId);
      final movies = List<Map<String, dynamic>>.from(response['movies'] ?? []);
      state = state.copyWith(
        cinemaDetails: response['cinema'],
        movies: movies,
        filteredMovies: movies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void searchMovies(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredMovies: state.movies);
    } else {
      final filtered =
          state.movies
              .where(
                (movie) => (movie['title'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
      state = state.copyWith(filteredMovies: filtered);
    }
  }
}
