// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tick_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TickState {
  List<Map<String, dynamic>> get movies => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get generatedDates =>
      throw _privateConstructorUsedError;
  List<String> get availableLanguages => throw _privateConstructorUsedError;
  List<bool> get langSelected => throw _privateConstructorUsedError;
  List<bool> get xpSelected => throw _privateConstructorUsedError;
  List<bool> get genreSelected => throw _privateConstructorUsedError;
  int get selectedDateIndex => throw _privateConstructorUsedError;
  int get selectedLangIndex => throw _privateConstructorUsedError;
  int get selectedInfoIndex => throw _privateConstructorUsedError;
  String get searchQuery => throw _privateConstructorUsedError;
  bool get showSearchSuggestions => throw _privateConstructorUsedError;
  Position? get userPosition => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get itemsPerPage => throw _privateConstructorUsedError;

  /// Create a copy of TickState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TickStateCopyWith<TickState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TickStateCopyWith<$Res> {
  factory $TickStateCopyWith(TickState value, $Res Function(TickState) then) =
      _$TickStateCopyWithImpl<$Res, TickState>;
  @useResult
  $Res call({
    List<Map<String, dynamic>> movies,
    List<Map<String, dynamic>> generatedDates,
    List<String> availableLanguages,
    List<bool> langSelected,
    List<bool> xpSelected,
    List<bool> genreSelected,
    int selectedDateIndex,
    int selectedLangIndex,
    int selectedInfoIndex,
    String searchQuery,
    bool showSearchSuggestions,
    Position? userPosition,
    bool isLoading,
    String? errorMessage,
    int currentPage,
    int itemsPerPage,
  });
}

/// @nodoc
class _$TickStateCopyWithImpl<$Res, $Val extends TickState>
    implements $TickStateCopyWith<$Res> {
  _$TickStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TickState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? movies = null,
    Object? generatedDates = null,
    Object? availableLanguages = null,
    Object? langSelected = null,
    Object? xpSelected = null,
    Object? genreSelected = null,
    Object? selectedDateIndex = null,
    Object? selectedLangIndex = null,
    Object? selectedInfoIndex = null,
    Object? searchQuery = null,
    Object? showSearchSuggestions = null,
    Object? userPosition = freezed,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? currentPage = null,
    Object? itemsPerPage = null,
  }) {
    return _then(
      _value.copyWith(
            movies:
                null == movies
                    ? _value.movies
                    : movies // ignore: cast_nullable_to_non_nullable
                        as List<Map<String, dynamic>>,
            generatedDates:
                null == generatedDates
                    ? _value.generatedDates
                    : generatedDates // ignore: cast_nullable_to_non_nullable
                        as List<Map<String, dynamic>>,
            availableLanguages:
                null == availableLanguages
                    ? _value.availableLanguages
                    : availableLanguages // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            langSelected:
                null == langSelected
                    ? _value.langSelected
                    : langSelected // ignore: cast_nullable_to_non_nullable
                        as List<bool>,
            xpSelected:
                null == xpSelected
                    ? _value.xpSelected
                    : xpSelected // ignore: cast_nullable_to_non_nullable
                        as List<bool>,
            genreSelected:
                null == genreSelected
                    ? _value.genreSelected
                    : genreSelected // ignore: cast_nullable_to_non_nullable
                        as List<bool>,
            selectedDateIndex:
                null == selectedDateIndex
                    ? _value.selectedDateIndex
                    : selectedDateIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            selectedLangIndex:
                null == selectedLangIndex
                    ? _value.selectedLangIndex
                    : selectedLangIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            selectedInfoIndex:
                null == selectedInfoIndex
                    ? _value.selectedInfoIndex
                    : selectedInfoIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            searchQuery:
                null == searchQuery
                    ? _value.searchQuery
                    : searchQuery // ignore: cast_nullable_to_non_nullable
                        as String,
            showSearchSuggestions:
                null == showSearchSuggestions
                    ? _value.showSearchSuggestions
                    : showSearchSuggestions // ignore: cast_nullable_to_non_nullable
                        as bool,
            userPosition:
                freezed == userPosition
                    ? _value.userPosition
                    : userPosition // ignore: cast_nullable_to_non_nullable
                        as Position?,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
            currentPage:
                null == currentPage
                    ? _value.currentPage
                    : currentPage // ignore: cast_nullable_to_non_nullable
                        as int,
            itemsPerPage:
                null == itemsPerPage
                    ? _value.itemsPerPage
                    : itemsPerPage // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TickStateImplCopyWith<$Res>
    implements $TickStateCopyWith<$Res> {
  factory _$$TickStateImplCopyWith(
    _$TickStateImpl value,
    $Res Function(_$TickStateImpl) then,
  ) = __$$TickStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Map<String, dynamic>> movies,
    List<Map<String, dynamic>> generatedDates,
    List<String> availableLanguages,
    List<bool> langSelected,
    List<bool> xpSelected,
    List<bool> genreSelected,
    int selectedDateIndex,
    int selectedLangIndex,
    int selectedInfoIndex,
    String searchQuery,
    bool showSearchSuggestions,
    Position? userPosition,
    bool isLoading,
    String? errorMessage,
    int currentPage,
    int itemsPerPage,
  });
}

/// @nodoc
class __$$TickStateImplCopyWithImpl<$Res>
    extends _$TickStateCopyWithImpl<$Res, _$TickStateImpl>
    implements _$$TickStateImplCopyWith<$Res> {
  __$$TickStateImplCopyWithImpl(
    _$TickStateImpl _value,
    $Res Function(_$TickStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TickState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? movies = null,
    Object? generatedDates = null,
    Object? availableLanguages = null,
    Object? langSelected = null,
    Object? xpSelected = null,
    Object? genreSelected = null,
    Object? selectedDateIndex = null,
    Object? selectedLangIndex = null,
    Object? selectedInfoIndex = null,
    Object? searchQuery = null,
    Object? showSearchSuggestions = null,
    Object? userPosition = freezed,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? currentPage = null,
    Object? itemsPerPage = null,
  }) {
    return _then(
      _$TickStateImpl(
        movies:
            null == movies
                ? _value._movies
                : movies // ignore: cast_nullable_to_non_nullable
                    as List<Map<String, dynamic>>,
        generatedDates:
            null == generatedDates
                ? _value._generatedDates
                : generatedDates // ignore: cast_nullable_to_non_nullable
                    as List<Map<String, dynamic>>,
        availableLanguages:
            null == availableLanguages
                ? _value._availableLanguages
                : availableLanguages // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        langSelected:
            null == langSelected
                ? _value._langSelected
                : langSelected // ignore: cast_nullable_to_non_nullable
                    as List<bool>,
        xpSelected:
            null == xpSelected
                ? _value._xpSelected
                : xpSelected // ignore: cast_nullable_to_non_nullable
                    as List<bool>,
        genreSelected:
            null == genreSelected
                ? _value._genreSelected
                : genreSelected // ignore: cast_nullable_to_non_nullable
                    as List<bool>,
        selectedDateIndex:
            null == selectedDateIndex
                ? _value.selectedDateIndex
                : selectedDateIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        selectedLangIndex:
            null == selectedLangIndex
                ? _value.selectedLangIndex
                : selectedLangIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        selectedInfoIndex:
            null == selectedInfoIndex
                ? _value.selectedInfoIndex
                : selectedInfoIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        searchQuery:
            null == searchQuery
                ? _value.searchQuery
                : searchQuery // ignore: cast_nullable_to_non_nullable
                    as String,
        showSearchSuggestions:
            null == showSearchSuggestions
                ? _value.showSearchSuggestions
                : showSearchSuggestions // ignore: cast_nullable_to_non_nullable
                    as bool,
        userPosition:
            freezed == userPosition
                ? _value.userPosition
                : userPosition // ignore: cast_nullable_to_non_nullable
                    as Position?,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
        currentPage:
            null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                    as int,
        itemsPerPage:
            null == itemsPerPage
                ? _value.itemsPerPage
                : itemsPerPage // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc

class _$TickStateImpl implements _TickState {
  const _$TickStateImpl({
    final List<Map<String, dynamic>> movies = const [],
    final List<Map<String, dynamic>> generatedDates = const [],
    final List<String> availableLanguages = const [],
    final List<bool> langSelected = const [],
    final List<bool> xpSelected = const [],
    final List<bool> genreSelected = const [],
    this.selectedDateIndex = 0,
    this.selectedLangIndex = -1,
    this.selectedInfoIndex = 0,
    this.searchQuery = '',
    this.showSearchSuggestions = false,
    this.userPosition,
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 0,
    this.itemsPerPage = 50,
  }) : _movies = movies,
       _generatedDates = generatedDates,
       _availableLanguages = availableLanguages,
       _langSelected = langSelected,
       _xpSelected = xpSelected,
       _genreSelected = genreSelected;

  final List<Map<String, dynamic>> _movies;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get movies {
    if (_movies is EqualUnmodifiableListView) return _movies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_movies);
  }

  final List<Map<String, dynamic>> _generatedDates;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get generatedDates {
    if (_generatedDates is EqualUnmodifiableListView) return _generatedDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_generatedDates);
  }

  final List<String> _availableLanguages;
  @override
  @JsonKey()
  List<String> get availableLanguages {
    if (_availableLanguages is EqualUnmodifiableListView)
      return _availableLanguages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableLanguages);
  }

  final List<bool> _langSelected;
  @override
  @JsonKey()
  List<bool> get langSelected {
    if (_langSelected is EqualUnmodifiableListView) return _langSelected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_langSelected);
  }

  final List<bool> _xpSelected;
  @override
  @JsonKey()
  List<bool> get xpSelected {
    if (_xpSelected is EqualUnmodifiableListView) return _xpSelected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_xpSelected);
  }

  final List<bool> _genreSelected;
  @override
  @JsonKey()
  List<bool> get genreSelected {
    if (_genreSelected is EqualUnmodifiableListView) return _genreSelected;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genreSelected);
  }

  @override
  @JsonKey()
  final int selectedDateIndex;
  @override
  @JsonKey()
  final int selectedLangIndex;
  @override
  @JsonKey()
  final int selectedInfoIndex;
  @override
  @JsonKey()
  final String searchQuery;
  @override
  @JsonKey()
  final bool showSearchSuggestions;
  @override
  final Position? userPosition;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int itemsPerPage;

  @override
  String toString() {
    return 'TickState(movies: $movies, generatedDates: $generatedDates, availableLanguages: $availableLanguages, langSelected: $langSelected, xpSelected: $xpSelected, genreSelected: $genreSelected, selectedDateIndex: $selectedDateIndex, selectedLangIndex: $selectedLangIndex, selectedInfoIndex: $selectedInfoIndex, searchQuery: $searchQuery, showSearchSuggestions: $showSearchSuggestions, userPosition: $userPosition, isLoading: $isLoading, errorMessage: $errorMessage, currentPage: $currentPage, itemsPerPage: $itemsPerPage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TickStateImpl &&
            const DeepCollectionEquality().equals(other._movies, _movies) &&
            const DeepCollectionEquality().equals(
              other._generatedDates,
              _generatedDates,
            ) &&
            const DeepCollectionEquality().equals(
              other._availableLanguages,
              _availableLanguages,
            ) &&
            const DeepCollectionEquality().equals(
              other._langSelected,
              _langSelected,
            ) &&
            const DeepCollectionEquality().equals(
              other._xpSelected,
              _xpSelected,
            ) &&
            const DeepCollectionEquality().equals(
              other._genreSelected,
              _genreSelected,
            ) &&
            (identical(other.selectedDateIndex, selectedDateIndex) ||
                other.selectedDateIndex == selectedDateIndex) &&
            (identical(other.selectedLangIndex, selectedLangIndex) ||
                other.selectedLangIndex == selectedLangIndex) &&
            (identical(other.selectedInfoIndex, selectedInfoIndex) ||
                other.selectedInfoIndex == selectedInfoIndex) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.showSearchSuggestions, showSearchSuggestions) ||
                other.showSearchSuggestions == showSearchSuggestions) &&
            (identical(other.userPosition, userPosition) ||
                other.userPosition == userPosition) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.itemsPerPage, itemsPerPage) ||
                other.itemsPerPage == itemsPerPage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_movies),
    const DeepCollectionEquality().hash(_generatedDates),
    const DeepCollectionEquality().hash(_availableLanguages),
    const DeepCollectionEquality().hash(_langSelected),
    const DeepCollectionEquality().hash(_xpSelected),
    const DeepCollectionEquality().hash(_genreSelected),
    selectedDateIndex,
    selectedLangIndex,
    selectedInfoIndex,
    searchQuery,
    showSearchSuggestions,
    userPosition,
    isLoading,
    errorMessage,
    currentPage,
    itemsPerPage,
  );

  /// Create a copy of TickState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TickStateImplCopyWith<_$TickStateImpl> get copyWith =>
      __$$TickStateImplCopyWithImpl<_$TickStateImpl>(this, _$identity);
}

abstract class _TickState implements TickState {
  const factory _TickState({
    final List<Map<String, dynamic>> movies,
    final List<Map<String, dynamic>> generatedDates,
    final List<String> availableLanguages,
    final List<bool> langSelected,
    final List<bool> xpSelected,
    final List<bool> genreSelected,
    final int selectedDateIndex,
    final int selectedLangIndex,
    final int selectedInfoIndex,
    final String searchQuery,
    final bool showSearchSuggestions,
    final Position? userPosition,
    final bool isLoading,
    final String? errorMessage,
    final int currentPage,
    final int itemsPerPage,
  }) = _$TickStateImpl;

  @override
  List<Map<String, dynamic>> get movies;
  @override
  List<Map<String, dynamic>> get generatedDates;
  @override
  List<String> get availableLanguages;
  @override
  List<bool> get langSelected;
  @override
  List<bool> get xpSelected;
  @override
  List<bool> get genreSelected;
  @override
  int get selectedDateIndex;
  @override
  int get selectedLangIndex;
  @override
  int get selectedInfoIndex;
  @override
  String get searchQuery;
  @override
  bool get showSearchSuggestions;
  @override
  Position? get userPosition;
  @override
  bool get isLoading;
  @override
  String? get errorMessage;
  @override
  int get currentPage;
  @override
  int get itemsPerPage;

  /// Create a copy of TickState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TickStateImplCopyWith<_$TickStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
