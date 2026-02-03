import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/repositories/cinema_repository.dart';
import 'package:cinematick/providers/navigation_providers.dart';

final repositoryProvider = Provider((ref) => CinemaRepository());

final cinemaChainProvider =
    StateNotifierProvider<CinemaChainNotifier, CinemaChainState>((ref) {
      final region = ref.watch(selectedRegionProvider);
      return CinemaChainNotifier(ref.watch(repositoryProvider), region);
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
  final String _region;

  CinemaChainNotifier(this._repository, this._region)
    : super(CinemaChainState()) {
    fetchCinemaChains();
  }

  Future<void> fetchCinemaChains() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final chains = await _repository.getCinemaChains(region: _region);
      // Check if the notifier is still mounted before updating state
      if (!mounted) return;
      state = state.copyWith(
        chains: chains,
        filteredChains: chains,
        isLoading: false,
      );
    } catch (e) {
      // Check if the notifier is still mounted before updating state
      if (!mounted) return;
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
  (String, String)
>((ref, params) {
  final (chainId, chainName) = params;
  final region = ref.watch(selectedRegionProvider);
  return CinemaLocationNotifier(
    chainId,
    chainName,
    ref.watch(repositoryProvider),
    region,
  );
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
  final String chainName;
  final CinemaRepository _repository;
  final String _region;

  CinemaLocationNotifier(
    this.chainId,
    this.chainName,
    this._repository,
    this._region,
  ) : super(CinemaLocationState()) {
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final allLocations = await _repository.getCinemaLocations(
        chainId,
        region: _region,
      );
      // Check if the notifier is still mounted before updating state
      if (!mounted) return;

      print('=== FETCHED CINEMA LOCATIONS ===');
      print('Chain ID: $chainId');
      print('Chain Name: $chainName');
      print('Region: $_region');
      print('Total locations received: ${allLocations.length}');
      if (allLocations.isNotEmpty) {
        print('First location: ${allLocations.first}');
        print('All locations: $allLocations');
      }
      print('================================');

      // API already filters by chain_id, so use all returned locations directly
      state = state.copyWith(
        locations: allLocations,
        filteredLocations: allLocations,
        isLoading: false,
      );
    } catch (e) {
      // Check if the notifier is still mounted before updating state
      if (!mounted) return;
      print('Error fetching cinema locations: $e');
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
