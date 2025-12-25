import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final showtimeProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      movieId,
    ) async {
      if (movieId.isEmpty) {
        return [];
      }

      try {
        final response = await http.get(
          Uri.parse('baseUrl/movies/$movieId/showtimes'),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception('Failed to load showtimes');
        }
      } catch (e) {
        throw Exception('Error: $e');
      }
    });
