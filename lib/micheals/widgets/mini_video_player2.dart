import 'dart:io';
import 'package:videonote/micheals/overlay_screen.dart';
import 'package:videonote/micheals/timer_controller.dart';
import 'package:videonote/micheals/hole_widget.dart';
import 'package:collection/collection.dart';
import 'package:native_video_player/native_video_player.dart';
import 'package:videonote/micheals/provider/player_provider.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VideoWidget extends ConsumerStatefulWidget {
  final String filePath;
  final double width;
  final double height;
  final bool shouldHide;
  final bool tapped;
  final bool show;
  final int currentId;
  final Function()? onPlay;
  final Function()? onVisible;
  final Function()? oninvisible;
  final Function()? onPause;

  const VideoWidget({
    required this.filePath,
    required this.width,
    this.onPause,
    this.onPlay,
    this.onVisible,
    this.oninvisible,
    this.currentId=-1,
    required this.height,
    required this.shouldHide,
    required this.tapped,
    required this.show,
    Key? key,
  }) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends ConsumerState<VideoWidget> with WidgetsBindingObserver{
  BetterPlayerController? _controller;
  NativeVideoPlayerController? controller;
  ControllerData? _controllerData;
  Duration _duration = Duration.zero;
  double _currentProgress = 0.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App is back in the foreground
      debugPrint('App resumed');
      if (visibility >= 0.2) {
        controller?.play();
        widget.onVisible?.call();
      }
    } else if (state == AppLifecycleState.paused) {
      // App is going to the background
      debugPrint('App paused');
      controller?.pause();
      widget.oninvisible?.call();
    }
  }

  init(NativeVideoPlayerController controllerr) async {
    controller = controllerr;
    controller!.onPlaybackReady.addListener(() {
      // Emitted when the video loaded successfully and it's ready to play.
      // At this point, videoInfo is available.

      _duration = Duration(seconds: controllerr.videoInfo?.duration??0);
      setState(() {

      });
    });
    controller!.onPlaybackStatusChanged.addListener(playbackStatus);
    controller!.onPlaybackPositionChanged.addListener(positionListener);
    controller!.onPlaybackEnded.addListener(endlistener);
  }

  void endlistener() {
    if(widget.tapped==true) {
      widget.onPause?.call();
    }
    if(visibility>0.2) {
      controller?.play();
    }
  }

  void positionListener() async{
    if(widget.tapped==true) {
      final playbackPosition = controller?.playbackInfo?.positionFraction ??
          0.0;
      debugPrint("duration: "+playbackPosition.toString());
      final isVideoEnded = (controller?.playbackInfo?.positionFraction ?? 0) >=
          0.99;
      if (isVideoEnded) {
        widget.onPause?.call();
      }
      _currentProgress = playbackPosition;
      setState(() {

      });
    }
    else{
      final isVideoEnded = (controller?.playbackInfo?.positionFraction ?? 0) >=
          0.99;
      if (isVideoEnded) {
        await controller?.seekTo(0);
        await controller?.play();
      }
      if(_currentProgress!=0){
      _currentProgress=0;
      setState(() {

      });
      }
    }
  }

  void playbackStatus() {
    final playbackStatus = controller?.playbackInfo?.status??PlaybackStatus.stopped;
    _isPlaying = playbackStatus==PlaybackStatus.playing;
    setState(() {

    });

  }

  @override
  void dispose() {
    // _controller?.videoPlayerController?.removeListener(_onVideoProgress);
    // ref.read(videoControllerProvider.notifier).disposeControllerById(_controllerData?.id??"");
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    disposee();
    super.dispose();
  }

  double visibility = 1;
  void onVisibilityChanged(double visibleFraction) async {
    setState(() {
      visibility = visibleFraction;
    });
    if (!mounted) return;

    if (visibleFraction >= 0.2) {
      controller?.seekTo(0);
      controller?.play();
      widget.onVisible?.call();
    } else {
      // Widget is not visible
      widget.oninvisible?.call();
      disposee();
    }
  }

  void disposee()async{
    await controller?.pause();
   // controller?.onPlaybackEnded.removeListener(endlistener);
   // controller?.onPlaybackStatusChanged.removeListener(playbackStatus);
   // controller?.onPlaybackPositionChanged.removeListener(positionListener);
   // await controller?.stop();
  }

  void _togglePlayPause() async{
    if (controller == null ||
       controller?.videoInfo==null) return;

      if (widget.tapped != true && widget.tapped != null) {
        controller?.setVolume(1.0);
        controller?.seekTo(0);
        controller?.play();
        widget.onPlay?.call();
        return;
      }

      if (( await controller!.isPlaying())==true) {
        controller?.pause();
      } else {
     final isVideoEnded =  (controller?.playbackInfo?.positionFraction??0)>=0.9;
        // debugPrint(
        //     "video $isVideoEnded ${_controller?.videoPlayerController?.value.position} - ${_controller?.videoPlayerController?.value.duration}");
        if (widget.tapped != null && widget.tapped != true) {
          controller?.seekTo(0);
        } else if (isVideoEnded) {
          // Restart the video if it has ended
          controller?.seekTo(0);
          controller?.play();
        } else {
          controller?.play();
        }
      }
  }


  @override
  void didUpdateWidget(VideoWidget oldWidget) {
    if(widget.tapped!=true && widget.tapped!=null){
      if((controller?.playbackInfo?.volume??0)>0) {
        controller?.setVolume(0);
      }
    }
    else if(widget.tapped==true){
      if (visibility >= 0.2) {
        controller?.setVolume(1);
        controller?.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.filePath),
      onVisibilityChanged: (visibilityInfo) {
        onVisibilityChanged(visibilityInfo.visibleFraction);
      },
      child: GestureDetector(
        onTap: () {
          _togglePlayPause();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              width: widget.width,
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(400),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: widget.width,
                      height: widget.height,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scale(
                            1.0,
                            // Flip horizontally
                            1.0, // Flip vertically
                          ),
                        child: widget.shouldHide
                            ? Container(color: Colors.black)
                            : AspectRatio(
                                aspectRatio: 16 / 9,
                                child: NativeVideoPlayerView(
                                  onViewReady: (controller) async {
                                    final videoSource = await VideoSource.init(
                                      path: widget.filePath,
                                      type: VideoSourceType.file,
                                    );
                                    init(controller);
                                    await controller
                                        .loadVideoSource(videoSource);
                                    await controller.play();
                                    await controller.setVolume(0);

                                  },
                                )),
                      ),
                    ),
                  ),
                ),
            ),
            if (!widget.show)
              SizedBox(
                width: widget.width + 15,
                height: widget.height + 15,
                child: CustomPaint(
                  size: Size(600, 1200),
                  painter: CircularProgressPainter(
                    progress: _currentProgress,
                    color: Color(0xFFE1FEC6),
                    backgroundColor: Colors.white,
                    max: 1.0,
                  ),
                ),
              ),
            if (controller != null &&
                (controller!.playbackInfo?.volume??0) <= 0.1 &&
                !widget.show)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    controller?.setVolume(1);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "packages/videonote/assets/audio_no.svg",
                        width: 15,
                        height: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        ' ${_duration.inMinutes}:${_duration.inSeconds.remainder(60)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (controller != null &&
                (controller!.playbackInfo?.volume??0) > 0.1 &&
                !widget.show)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    controller?.setVolume(0);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "packages/videonote/assets/audio_on.svg",
                        width: 15,
                        height: 15,
                      ),
                      SizedBox(width: 5),
                      Text(
                        ' ${_duration.inMinutes}:${_duration.inSeconds.remainder(60)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
