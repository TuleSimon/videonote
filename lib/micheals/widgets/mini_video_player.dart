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
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
          showControlsOnInitialize: false
        ),
          autoPlay: true,
          aspectRatio: 6/19,
          fit:BoxFit.cover ,
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
                _recordingController.startRecording(
                    maxT: (_duration.inMilliseconds / 1000).toDouble());
              });
            }
            if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
              setState(() {
                _isPlaying = false;
              });
            }
            if (event.betterPlayerEventType == BetterPlayerEventType.play) {
              setState(() {
                _isPlaying = true;
              });
            }
          }),
      betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.file, widget.filePath),
    )..setMixWithOthers(true);
  }

  void onVisibilityChanged(double visibleFraction) async {
    bool isPlaying = ( _controller!.isPlaying()) == true;
    bool initialized = _controller!.isVideoInitialized()==true;
    if (visibleFraction >= 0.5) {
      if (widget.autoPlay && initialized && !isPlaying ) {
        _controller?.setVolume(0.0);
        _controller?.seekTo(const Duration(seconds: 0));
        _controller!.play();
      }
    } else {
      if (initialized && isPlaying ) {
        _controller!.pause();
      }
    }
  }

  void playListener() {
    setState(() {
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
      if (widget.tapped!=true && widget.tapped!=null) {
        _controller?.setVolume(1.0);
        _controller?.seekTo(const Duration(seconds: 0));
        _controller?.play();
        widget.onPlay?.call();
        return;
      }

      if (_controller!.videoPlayerController!.value.isPlaying) {
        _controller?.pause();
        _recordingController.pauseRecording();
      } else {
        debugPrint("here");


        final isVideoEnded = _controller?.videoPlayerController?.value.position ==
            _controller?.videoPlayerController?.value.duration;
        if( widget.tapped!=null && widget.tapped!=true) {
          _controller?.seekTo(const Duration(seconds: 0));
        }
        else if (isVideoEnded) {
          // Restart the video if it has ended
          _controller?.seekTo(const Duration(seconds: 0));
          _controller?.play();
          _recordingController.restart();
          _recordingController.playRecording();
          _isPlaying = true;
        } else {
          _controller?.play();
          _recordingController.playRecording();
        }

      }
    });
  }

@override
  void didUpdateWidget(covariant MiniVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
  if(widget.tapped!=null && widget.tapped!=true){
    _controller?.setVolume(0.0);
  }

  }


  @override
  Widget build(BuildContext context) {
    if (_controller == null || _controller?.isVideoInitialized() == false) {
      return const FractionallySizedBox( widthFactor:0.5, heightFactor: 0.5,child: CircularProgressIndicator(
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
          if (_controller!.videoPlayerController!.value!.volume<=0.1 && !widget.show)
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
