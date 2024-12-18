import 'dart:io';
import 'package:videonote/micheals/overlay_screen.dart';
import 'package:videonote/micheals/timer_controller.dart';
import 'package:videonote/micheals/hole_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

class MiniVideoPlayer extends StatefulWidget {
  final String filePath;
  final bool autoPlay;
  final bool? tapped;
  final bool show;
  final double width;
  final double height;
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
    this.width = 200,
    this.height = 200,
    this.tapped,
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
  double _currentProgress = 0.0;

  Duration _duration = const Duration();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    try {
      if (!File(widget.filePath).existsSync()) return;
      if (widget.filePath.isNotEmpty) {
        _controller = VideoPlayerController.file(File(widget.filePath),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true
        ))
          ..addListener(_videoListener)
          ..setLooping(true)
          ..initialize().then((_) {
            setState(() {
              _duration = _controller?.value.duration ?? Duration.zero;
              if (widget.autoPlay) {
                _controller?.play();
                _isPlaying = true;
              }
            });
          });
      } else {
        debugPrint("Invalid file path");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _videoListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    setState(() {
      _currentProgress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;

      _isPlaying = _controller!.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }



  void _togglePlayPause() {
    debugPrint("${_controller!.value.isPlaying}");
    if (_controller == null ||
        _controller?.initialize() == false) return;


      if (widget.tapped != true && widget.tapped != null) {
        _controller?.setVolume(1.0);
        _controller?.seekTo(const Duration(seconds: 1));
        _controller?.play();
        widget.onPlay?.call();
        setState(() {

        });
        return;
      }

      if (_controller!.value.isPlaying) {
        _controller?.pause();
      } else {
        final isVideoEnded =
            (_controller?.value.position ??
                Duration(seconds: 0)) >=
                (Duration(
                    seconds: (_controller?.value.duration
                        ?.inSeconds ??
                        1) -
                        1));
        // debugPrint(
        //     "video $isVideoEnded ${_controller?.videoPlayerController?.value.position} - ${_controller?.videoPlayerController?.value.duration}");
        if (widget.tapped != null && widget.tapped != true) {
          _controller?.seekTo(const Duration(seconds: 1));
        } else if (isVideoEnded) {
          // Restart the video if it has ended
          _controller?.seekTo(const Duration(seconds: 1));
          _controller?.play();
          _isPlaying = true;
          setState(() {

          });
        } else {
          _controller?.play();
        }
      }
  }

  @override
  void didUpdateWidget(covariant MiniVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tapped != null && widget.tapped != true) {
      _controller?.setVolume(0.0);
      setState(() {

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: CircularProgressIndicator(
          color: Colors.amber,
        ),
      );
    }

    return  GestureDetector(
          onTap: _togglePlayPause,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller?.value.size.width ?? 0,
                      height: _controller?.value.size.height ?? 0,
                      child:  Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scale(
                            -1.0, // Flip horizontally
                            1.0, // Flip vertically
                          ),
                        child: VideoPlayer(_controller!)),
                    ),
                  ),
                ),
              ),
              if (!widget.show)
                Positioned(
                  left: -4,
                  right: -4,
                  top: -4,
                  bottom: -4,
                  child: CustomPaint(
                    size:  Size(widget.width, widget.height),
                    painter: CircularProgressPainter(
                      progress: _currentProgress,
                      color: Color(0xFFE1FEC6),
                      backgroundColor: Colors.white,
                      max: 1.0,
                    ),
                  ),
                ),
              if (widget.show)
                Positioned(
                    left: -2,
                    right: -2,
                    top: -2,
                    bottom: -2,
                  child: CustomPaint(
                    size: const Size(380, 380),
                    painter: CircularProgressPainter(
                      progress: _currentProgress,
                      color: Colors.yellow,
                      backgroundColor: Colors.transparent,
                      max: 1.0,
                    ),
                  ),
                ),
              if (!_isPlaying && widget.show)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: SvgPicture.asset(
                      "assets/play.svg",
                      package: "videonote",
                      width: 65,
                    ),
                  ),
                ),
              if (_isPlaying && widget.show)
                Center(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: SvgPicture.asset(
                      "packages/videonote/assets/pause2.svg",
                      width: 65,
                    ),
                  ),
                ),
              if (_controller!.value.volume != null &&
                  _controller!.value.volume <= 0.1 &&
                  !widget.show)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "packages/videonote/assets/audio_no.svg",
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
                ),
              if (_controller!.value.volume != null &&
                  _controller!.value.volume >= 0.1 &&
                  !widget.show)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "packages/videonote/assets/audio_on.svg",
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
