import 'dart:io';
import 'package:videonote/micheals/overlay_screen.dart';
import 'package:videonote/micheals/timer_controller.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MiniVideoPlayer extends StatefulWidget {
  final String filePath;
  final bool autoPlay;
  final bool? tapped;
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
    this.tapped,
    this.onPause,
  });

  @override
  State<StatefulWidget> createState() {
    return _MiniVideoPlayer();
  }
}

class _MiniVideoPlayer extends State<MiniVideoPlayer> {
  BetterPlayerController? _controller;
  bool _isPlaying = false;
  double _currentProgress = 0.0;

  Duration _duration = const Duration();

  @override
  void initState() {
    super.initState();
    try {
      // getVideoDuration(widget.filePath);
      debugPrint("File Path: ${widget.filePath}");
      if(!File(widget.filePath).existsSync()) return;
      if (widget.filePath.isNotEmpty) {
      _controller = BetterPlayerController(
        BetterPlayerConfiguration(
            controlsConfiguration: const BetterPlayerControlsConfiguration(
                showControls: false, showControlsOnInitialize: false),
            autoPlay: true,
            looping: true,
            aspectRatio: 6 / 19,
            fit: BoxFit.cover,
            playerVisibilityChangedBehavior: (visibility) {
              onVisibilityChanged(visibility);
            },
            eventListener: (event) {
              if (event.betterPlayerEventType ==
                  BetterPlayerEventType.initialized) {
                setState(() {
                  _duration =
                      _controller?.videoPlayerController?.value.duration ??
                          const Duration();
                  _controller?.videoPlayerController?.addListener(playListener);
                  if (widget.tapped != null && widget.tapped != true) {
                    _controller?.setVolume(0.0);
                  } else {
                    _controller?.setVolume(1.0);
                  }
                });
              }

              if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
                setState(() {
                  _isPlaying = false;
                });
              }
              if (event.betterPlayerEventType ==
                  BetterPlayerEventType.progress) {
                final progress = event.parameters?['progress'] as Duration?;
                final totalDuration =
                    event.parameters?['duration'] as Duration?;

                if (progress != null && totalDuration != null) {
                  setState(() {
                    _currentProgress =
                        progress.inMilliseconds / totalDuration.inMilliseconds;
                  });
                } else {
                  debugPrint("Progress or duration is null");
                }
              }
              if (event.betterPlayerEventType == BetterPlayerEventType.play) {
                setState(() {
                  _isPlaying = true;
                });
              }
            }),
        betterPlayerDataSource: BetterPlayerDataSource(
            BetterPlayerDataSourceType.file, widget.filePath),
      );

      } else {
        debugPrint("Invalid file path");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void onVisibilityChanged(double visibleFraction) async {
    bool isPlaying = (_controller!.isPlaying()) == true;
    bool initialized = _controller!.isVideoInitialized() == true;
    if (visibleFraction >= 0.5) {
      if (widget.autoPlay && initialized && !isPlaying) {
        if (widget.tapped != null && widget.tapped != true) {
          _controller?.setVolume(0.0);
        }
        _controller?.seekTo(const Duration(seconds: 0));
        _controller!.play();
      }
    } else {
      if (initialized && isPlaying) {
        _controller!.pause();
      }
    }
  }

  void playListener() {
    setState(() {
      if (_currentProgress > 0.5) {
        final isVideoEnded =
            (_controller?.videoPlayerController?.value.position ??
                    Duration(seconds: 0)) >=
                (Duration(
                    milliseconds: (_controller?.videoPlayerController?.value
                                .duration?.inMilliseconds ??
                            1) -
                        100));
        // debugPrint("Video edned " + isVideoEnded.toString());
        if (isVideoEnded) {
          _currentProgress = 0;
        }
      }

      _isPlaying = _controller?.videoPlayerController?.value.isPlaying ?? false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null ||
        _controller?.videoPlayerController?.value.initialized == false) return;

    setState(() {
      if (widget.tapped != true && widget.tapped != null) {
        _controller?.setVolume(1.0);
        _controller?.seekTo(const Duration(seconds: 0));
        _controller?.play();
        widget.onPlay?.call();
        return;
      }

      if (_controller!.videoPlayerController!.value.isPlaying) {
        _controller?.pause();
      } else {
        final isVideoEnded =
            (_controller?.videoPlayerController?.value.position ??
                    Duration(seconds: 0)) >=
                (Duration(
                    seconds: (_controller?.videoPlayerController?.value.duration
                                ?.inSeconds ??
                            1) -
                        1));
        // debugPrint(
        //     "video $isVideoEnded ${_controller?.videoPlayerController?.value.position} - ${_controller?.videoPlayerController?.value.duration}");
        if (widget.tapped != null && widget.tapped != true) {
          _controller?.seekTo(const Duration(seconds: 0));
        } else if (isVideoEnded) {
          // Restart the video if it has ended
          _controller?.seekTo(const Duration(seconds: 0));
          _controller?.play();
          _isPlaying = true;
        } else {
          _controller?.play();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant MiniVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tapped != null && widget.tapped != true) {
      _controller?.setVolume(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _controller?.isVideoInitialized() != true) {
      return const FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: CircularProgressIndicator(
            color: Colors.amber,
          ));
    }

    return GestureDetector(
      onTap: () {
        _togglePlayPause();
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
                    width: _controller
                            ?.videoPlayerController?.value?.size?.width ??
                        0,
                    height: _controller
                            ?.videoPlayerController?.value?.size?.height ??
                        0,
                    child: BetterPlayer(controller: _controller!),
                  ),
                ),
              ),
            ),
          ),
          if (!widget.show)
            Positioned(
                left: 8,
                right: 8,
                top: 8,
                bottom: 8,
                child: CustomPaint(
                  size: const Size(380, 380),
                  painter: CircularProgressPainter(
                    progress: _currentProgress,
                    color: Color(0xFFE1FEC6),
                    backgroundColor: Colors.white,
                    max: 1.0,
                  ),
                )),
          if (widget.show)
            Center(
                child: CustomPaint(
              size: const Size(380, 380),
              painter: CircularProgressPainter(
                progress: _currentProgress,
                color: Colors.yellow,
                backgroundColor: Colors.transparent,
                max: 1.0,
              ),
            )),
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
          if (_controller?.videoPlayerController?.value.volume != null &&
              _controller!.videoPlayerController!.value.volume <= 0.1 &&
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
          if (_controller?.videoPlayerController?.value.volume != null &&
              _controller!.videoPlayerController!.value.volume >= 0.1 &&
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
