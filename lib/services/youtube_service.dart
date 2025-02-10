import 'dart:convert';

import 'package:http/http.dart' as http;

class YouTubeService {
  final String apiKey;

  YouTubeService(this.apiKey);

  Future<List<dynamic>> fetchPlaylistItems(String playlistId) async {
    final String url =
        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=$playlistId&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to load playlist');
    }
  }
}
