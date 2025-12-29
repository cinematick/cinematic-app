import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/repositories/cinema_repository.dart';

final repositoryProvider = Provider((ref) => CinemaRepository());

final cinemaChainProvider =
    StateNotifierProvider<CinemaChainNotifier, CinemaChainState>((ref) {
      return CinemaChainNotifier(ref.watch(repositoryProvider));
    });

class CinemaChainState {
  final List<Map<String, dynamic>> chains;
  final List<Map<String, dynamic>> filteredChains;
  final bool isLoading;
  final String? errorMessage;

  CinemaChainState({
    this.chains = const [],
    this.filteredChains = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  CinemaChainState copyWith({
    List<Map<String, dynamic>>? chains,
    List<Map<String, dynamic>>? filteredChains,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CinemaChainState(
      chains: chains ?? this.chains,
      filteredChains: filteredChains ?? this.filteredChains,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CinemaChainNotifier extends StateNotifier<CinemaChainState> {
  final CinemaRepository _repository;

  CinemaChainNotifier(this._repository) : super(CinemaChainState()) {
    fetchCinemaChains();
  }

  Future<void> fetchCinemaChains() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final chains = await _repository.getCinemaChains();
      state = state.copyWith(
        chains: chains,
        filteredChains: chains,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void searchChains(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredChains: state.chains);
    } else {
      final filtered =
          state.chains
              .where(
                (chain) => (chain['chain_name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
      state = state.copyWith(filteredChains: filtered);
    }
  }
}

final cinemaLocationProvider = StateNotifierProvider.family<
  CinemaLocationNotifier,
  CinemaLocationState,
  String
>((ref, chainId) {
  return CinemaLocationNotifier(chainId, ref.watch(repositoryProvider));
});

class CinemaLocationState {
  final List<Map<String, dynamic>> locations;
  final List<Map<String, dynamic>> filteredLocations;
  final bool isLoading;
  final String? errorMessage;

  CinemaLocationState({
    this.locations = const [],
    this.filteredLocations = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  CinemaLocationState copyWith({
    List<Map<String, dynamic>>? locations,
    List<Map<String, dynamic>>? filteredLocations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CinemaLocationState(
      locations: locations ?? this.locations,
      filteredLocations: filteredLocations ?? this.filteredLocations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CinemaLocationNotifier extends StateNotifier<CinemaLocationState> {
  final String chainId;
  final CinemaRepository _repository;

  CinemaLocationNotifier(this.chainId, this._repository)
    : super(CinemaLocationState()) {
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final locations = await _repository.getCinemaLocations(chainId);
      state = state.copyWith(
        locations: locations,
        filteredLocations: locations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void searchLocations(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredLocations: state.locations);
    } else {
      final filtered =
          state.locations
              .where(
                (location) => (location['cinema_name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()),
              )
              .toList();
      state = state.copyWith(filteredLocations: filtered);
    }
  }
}
