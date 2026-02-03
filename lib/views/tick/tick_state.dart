import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';

part 'tick_state.freezed.dart';

@freezed
class TickState with _$TickState {
  const factory TickState({
    @Default([]) List<Map<String, dynamic>> movies,
    @Default([]) List<Map<String, dynamic>> generatedDates,
    @Default([]) List<String> availableLanguages,

    @Default([]) List<bool> langSelected,
    @Default([]) List<bool> xpSelected,
    @Default([]) List<bool> genreSelected,

    @Default(0) int selectedDateIndex,
    @Default(-1) int selectedLangIndex,
    @Default(0) int selectedInfoIndex,

    @Default('') String searchQuery,
    @Default(false) bool showSearchSuggestions,

    Position? userPosition,

    @Default(false) bool isLoading,
    String? errorMessage,
    @Default(0) int currentPage,
    @Default(25) int itemsPerPage,
  }) = _TickState;
}
