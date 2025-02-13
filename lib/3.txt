// 1- final green screen + home screen video preview + pause in every five second
// 2- + pause (interval) screen with continue button (finish)" {code in github}+ hide KP Video Player app bar double tap
// 3 - + add next video button to final screen

import 'dart:async';

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
      debugShowCheckedModeBanner: false,
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
        title: Text('kp YouTube Playlist'),
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
                          builder: (context) => VideoPlayerScreen(
                            videoId: videoId,
                            playlistItems: _playlistItems,
                            currentIndex: index,
                          ),
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
  final List<dynamic> playlistItems;
  final int currentIndex;

  VideoPlayerScreen({
    required this.videoId,
    required this.playlistItems,
    required this.currentIndex,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isVideoEnded = false;
  bool _showIntervalScreen = false;
  late Timer _timer;
  int _intervalCount = 0;
  int _lastIntervalTime = 0;
  bool _isAppBarVisible = true;

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
    )..addListener(_onControllerUpdate);

    _timer = Timer.periodic(Duration(seconds: 1), _onTimerTick);
  }

  void _onControllerUpdate() {
    if (_controller.value.playerState == PlayerState.ended) {
      setState(() {
        _isVideoEnded = true;
      });
    }
  }

  void _onTimerTick(Timer timer) {
    if (!_controller.value.isPlaying) return;

    final currentTime = _controller.value.position.inSeconds;
    if (currentTime % 5 == 0 &&
        currentTime != 0 &&
        currentTime != _lastIntervalTime) {
      _lastIntervalTime = currentTime;
      _controller.pause();
      setState(() {
        _showIntervalScreen = true;
        _intervalCount++;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _onFinishPressed() {
    setState(() {
      _showIntervalScreen = false;
    });
    _controller.play();
  }

  void _toggleAppBar() {
    setState(() {
      _isAppBarVisible = !_isAppBarVisible;
    });
  }

  void _playNextVideo() {
    final nextIndex = widget.currentIndex + 1;
    if (nextIndex < widget.playlistItems.length) {
      final nextVideoId =
          widget.playlistItems[nextIndex]['snippet']['resourceId']['videoId'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoId: nextVideoId,
            playlistItems: widget.playlistItems,
            currentIndex: nextIndex,
          ),
        ),
      );
    } else {
      // If there are no more videos, go back to the home screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isAppBarVisible
          ? AppBar(
              title: Text('KP Video Player'),
            )
          : null,
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _playNextVideo,
                    child: Text('Next Video'),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onDoubleTap: _toggleAppBar,
              child: Stack(
                children: [
                  Center(
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
                  if (_showIntervalScreen)
                    Container(
                      color: Colors.red.withOpacity(0.8),
                      width: double.infinity,
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Interval ${_intervalCount}',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _onFinishPressed,
                            child: Text('Finish'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
