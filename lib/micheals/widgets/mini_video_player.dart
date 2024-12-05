import 'dart:io';

import 'package:audionotee/micheals/hole_widget.dart';
import 'package:audionotee/micheals/overlay_screen.dart';
import 'package:audionotee/micheals/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MiniVideoPlayer extends StatefulWidget {
  final String filePath;
  final bool autoPlay;
  final bool show;
  final Function()? onPlay;
  final Function()? onPause;
  const MiniVideoPlayer({
    super.key,
    required this.filePath,
    this.autoPlay = false,
    required this.show,
    this.onPlay,
    this.onPause,
  });

  @override
  State<StatefulWidget> createState() {
    return _MiniVideoPlayer();
  }
}

class _MiniVideoPlayer extends State<MiniVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  int _duration = 0;
  final RecordingController _recordingController = RecordingController();

  @override
  void initState() {
    super.initState();

    // getVideoDuration(widget.filePath);
    _recordingController.onDurationExceed = () {
      _recordingController.restart();
      _recordingController.pauseRecording();
    };
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {
          _controller?.setLooping(false);
        });
        if (widget.autoPlay) {
          _controller?.setVolume(0.0);
          _controller?.play();
          _duration = (_controller?.value.duration.inMilliseconds ?? 0);

          _recordingController.startRecording(
              maxT: (_duration / 1000).toDouble());

          setState(() {
            _isPlaying = true;
          });
        }
        _controller?.addListener(playListener);
      });
  }

  void playListener() {
    setState(() {
      _isPlaying = _controller?.value.isPlaying ?? false;
      if (tapped) {
        if (_isPlaying) {
          widget.onPlay?.call();
        } else {
          widget.onPause?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      tapped = true;
      if (_controller!.value.isPlaying) {
        _controller?.pause();
        _recordingController.pauseRecording();
        _isPlaying = false;
      } else {
        _controller?.setVolume(1.0);
        _controller?.play();
        _recordingController.playRecording();
        _isPlaying = true;
      }
    });
  }

  bool tapped = false;

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const HoleWidget(
          child: Center(child: CircularProgressIndicator()));
    }

    return GestureDetector(
      onTap: () {
        if (_isPlaying) {
          _togglePlayPause();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          HoleWidget(
            radius: 185,
            child: Transform.scale(
              scaleY: 0.935,
              scaleX: 0.935,
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          if (widget.show)
            Center(
              child: ValueListenableBuilder<double>(
                valueListenable: _recordingController.recordingDuration,
                builder: (context, duration, child) {
                  return CustomPaint(
                    size: const Size(380, 380),
                    painter: CircularProgressPainter(
                      progress: duration.toDouble(),
                      color: Colors.yellow,
                      radius: 190,
                      max: (_duration / 1000).toDouble(),
                    ),
                  );
                },
              ),
            ),
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
