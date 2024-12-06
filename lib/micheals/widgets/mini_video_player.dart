import 'dart:io';

import 'package:audionotee/micheals/hole_widget.dart';
import 'package:audionotee/micheals/overlay_screen.dart';
import 'package:audionotee/micheals/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

class MiniVideoPlayer extends StatefulWidget {
  final String filePath;
  final bool autoPlay;
  final bool? isVisible;
  final bool show;
  final double radius;
  final Function()? onPlay;
  final Function()? onPause;
  const MiniVideoPlayer({
    super.key,
    required this.filePath,
    this.autoPlay = false,
    required this.show,
    this.onPlay,
    this.radius = 200,
    this.isVisible,
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
  Duration _duration = const Duration();
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
          if (_controller != null) {
            _duration = (_controller!.value.duration);
          }

          _recordingController.startRecording(
              maxT: (_duration.inMilliseconds / 1000).toDouble());

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
      if (!tapped) {
        _controller?.setVolume(1.0);
        tapped = true;
        return;
      }
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

  @override
  void didUpdateWidget(MiniVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != null && widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible == true && _controller?.value.isPlaying != true) {
        _controller?.setVolume(0.0);
        _controller?.seekTo(const Duration(seconds: 0));
        _controller?.play();
        setState(() {
          tapped = false;
        });
      }
    }
  }

  bool tapped = false;

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return HoleWidget(
          child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.black),
              child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(
                      -1.0, // Flip horizontally
                      1.0, // Flip vertically
                    ),
                  child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox()))));
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
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            bottom: 10,
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(
                    -1.0, // Flip horizontally
                    1.0, // Flip vertically
                  ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: _controller?.value.size.width ?? 0,
                    height: _controller?.value.size.height ?? 0,
                    child: VideoPlayer(_controller!),
                  ),
                ),
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
                      max: (_duration.inMilliseconds / 1000).toDouble(),
                    ),
                  );
                },
              ),
            ),
          if (!_isPlaying)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: SvgPicture.asset(
                  "assets/play.svg",
                  width: 65,
                ),
              ),
            ),
          if (_isPlaying && widget.show)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: SvgPicture.asset(
                  "assets/pause2.svg",
                  width: 65,
                ),
              ),
            ),
          if (!tapped && !widget.show)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/audio_no.svg",
                    width: 15,
                    height: 15,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    ' ${_duration.inMinutes}:${_duration.inSeconds.remainder(60)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}
