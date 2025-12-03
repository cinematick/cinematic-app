class MovieModel {
  final String id;
  final String title;
  final String posterPath;
  final String? backdropPath;
  final String? overview;
  final double voteAverage;
  final List<String> genres;
  final String releaseDate;
  final double popularity;
  final String language;

  MovieModel({
    required this.id,
    required this.title,
    required this.posterPath,
    this.backdropPath,
    this.overview,
    required this.voteAverage,
    required this.genres,
    required this.releaseDate,
    required this.popularity,
    required this.language,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      posterPath: json['posterPath'] ?? 'https://picsum.photos/200/300?blur=2',
      backdropPath: json['backdropPath'],
      overview: json['overview'] ?? '',
      voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0.0,
      genres: List<String>.from(json['genres'] ?? []),
      releaseDate: json['releaseDate'] ?? '',
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      language: json['language'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'overview': overview,
      'voteAverage': voteAverage,
      'genres': genres,
      'releaseDate': releaseDate,
      'popularity': popularity,
      'language': language,
    };
  }

  String get rating => voteAverage.toStringAsFixed(1);

  String get year {
    if (releaseDate.isEmpty) return '';
    return releaseDate.split('-').first;
  }
}
