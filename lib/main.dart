import 'dart:async'; // Import for Timer

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'services/youtube_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Playlist App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: PlaylistScreen(),
    );
  }
}

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final YouTubeService _youTubeService =
      YouTubeService('AIzaSyC9qNLF_jY4GCMaE3TlaNFbbShq7LqWOiM');
  List<dynamic> _playlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylist();
  }

  Future<void> _fetchPlaylist() async {
    try {
      final items = await _youTubeService
          .fetchPlaylistItems('PLDTDd3RCBOMWEEdjJw81ynqG0xSaikwaY');
      setState(() {
        _playlistItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My YouTube Playlist'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _playlistItems.length,
              itemBuilder: (context, index) {
                final item = _playlistItems[index];
                final title = item['snippet']['title'];
                final videoId = item['snippet']['resourceId']['videoId'];
                final thumbnailUrl =
                    item['snippet']['thumbnails']['medium']['url'];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: Image.network(
                      thumbnailUrl,
                      width: 100,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerScreen(videoId: videoId),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  VideoPlayerScreen({required this.videoId});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isVideoEnded = false;
  late Timer _timer; // Timer to periodically check the video time

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        forceHD: true,
        enableCaption: false,
        isLive: false,
        loop: false,
        controlsVisibleAtStart: true,
      ),
    )..addListener(() {
        if (_controller.value.playerState == PlayerState.ended) {
          setState(() {
            _isVideoEnded = true;
          });
        }
      });

    // Start the timer to check the video time every 1 second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final currentTime = _controller.value.position.inSeconds;
      if (currentTime % 5 == 0 && currentTime != 0) {
        _controller.pause(); // Pause video every 5 seconds
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer when the screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: _isVideoEnded
          ? Container(
              color: Colors.green,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'End Video',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Home'),
                  ),
                ],
              ),
            )
          : Center(
              child: YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                ),
                builder: (context, player) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: player,
                  );
                },
              ),
            ),
    );
  }
}
