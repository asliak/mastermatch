import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/profile_request.dart';
import '../models/program.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Helper to format profile request to match Django's UserProfile serializer field names
  Map<String, dynamic> _toDjangoJson(ProfileRequest profile) {
    return {
      'field_of_study': profile.field,
      'gpa': profile.gpa,
      'budget': profile.budget,
      'interests': profile.interests,
      'career_goals': profile.careerGoals,
      'countries': profile.countries,
    };
  }

  Future<List<Program>> match(ProfileRequest profile, {String? token}) async {
    // API endpoint on Django is /api/match/
    final uri = Uri.parse('$baseUrl/api/match/');

    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Token $token';
    }

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw Exception(
        'Unable to reach the server. Check your connection and try again.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Server returned status ${response.statusCode}: ${response.body}',
      );
    }

    final List<dynamic> data;
    try {
      data = jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw Exception('Invalid JSON response from server.');
    }

    return data
        .map((item) => Program.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login/');
    final response = await http.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Login failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<String> register(String username, String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/register/');
    final response = await http.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Registration failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<String> loginWithGoogle(String idToken) async {
    final uri = Uri.parse('$baseUrl/api/auth/google/');
    final response = await http.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Google authentication failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<String> loginWithApple(String identityToken) async {
    final uri = Uri.parse('$baseUrl/api/auth/apple/');
    final response = await http.post(
      uri,
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      body: jsonEncode({'identity_token': identityToken}),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Apple authentication failed');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<ProfileRequest> getProfile(String token) async {
    final uri = Uri.parse('$baseUrl/api/profile/');
    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Token $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile from server');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ProfileRequest.fromJson(data);
  }

  Future<void> saveProfile(String token, ProfileRequest profile) async {
    final uri = Uri.parse('$baseUrl/api/profile/');
    final response = await http.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Token $token',
      },
      body: jsonEncode(_toDjangoJson(profile)),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to save profile to server');
    }
  }

  Future<bool> toggleFavorite(String token, String universityName, String programName) async {
    final uri = Uri.parse('$baseUrl/api/favorites/');
    final response = await http.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Token $token',
      },
      body: jsonEncode({
        'university_name': universityName,
        'program_name': programName,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to toggle favorite');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['favorited'] as bool;
  }

  Future<List<Program>> getFavorites(String token) async {
    final uri = Uri.parse('$baseUrl/api/favorites/');
    final response = await http.get(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Token $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load favorites from server');
    }

    final List<dynamic> data;
    try {
      data = jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw Exception('Invalid JSON response from server.');
    }

    return data
        .map((item) => Program.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> testConnection() async {
    try {
      // Hit the base index url to see if Django is up
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      // Django returns 200 for index
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
