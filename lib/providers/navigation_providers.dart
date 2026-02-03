import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCinemaChainProvider =
    StateProvider<({String? name, String? id, String? count})?>((ref) => null);

final selectedCinemaLocationProvider =
    StateProvider<({String? name, String? address, String? cinemaId})?>(
      (ref) => null,
    );

final selectedMovieTitleProvider = StateProvider<String?>((ref) => null);

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final selectedRegionProvider = StateProvider<String>((ref) => 'NSW');
