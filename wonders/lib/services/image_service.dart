import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  final String _apiKey =
      "2FMb2uwfFDGZqPtLxO0tKSBz5ZSRZUmCXVxrW0APhNPUskWTsD6HjBi0";

  Future<String> getWonderImage(String wonderName) async {
    try {
      final encodedQuery = Uri.encodeComponent(wonderName);
      final response = await http.get(
        Uri.parse(
          'https://api.pexels.com/v1/search?query=$encodedQuery&per_page=1',
        ),
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['photos'] != null && data['photos'].length > 0) {
          return data['photos'][0]['src']['large'];
        }
      }

      // Fallback to a default image if API call fails
      return 'https://images.unsplash.com/photo-1566438480900-0609be27a4be?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=394&q=80';
    } catch (e) {
      print('Error fetching wonder image: $e');
      return 'https://images.unsplash.com/photo-1566438480900-0609be27a4be?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=394&q=80';
    }
  }
}
