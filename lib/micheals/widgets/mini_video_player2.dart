import 'dart:io';
import 'package:videonote/micheals/overlay_screen.dart';
import 'package:videonote/micheals/timer_controller.dart';
import 'package:videonote/micheals/hole_widget.dart';
import 'package:collection/collection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:native_video_player/native_video_player.dart';
import 'package:videonote/micheals/provider/player_provider.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  final bool isLoading;
  final int currentId;
  final Function()? onPlay;
  final Future<bool> Function()? isLastVideo;
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
    this.currentId = -1,
    required this.height,
    required this.shouldHide,
    required this.tapped,
    required this.show,
     this.isLoading=false,
    this.isLastVideo,
    Key? key,
  }) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends ConsumerState<VideoWidget>
    with WidgetsBindingObserver {
  BetterPlayerController? _controller;
  NativeVideoPlayerController? controller;
  Duration _duration = Duration.zero;
  double _currentProgress = 0.0;
  bool _isPlaying = false;
  String? thumbNail;

  void init2()async{
    thumbNail = await VideoThumbnail.thumbnailFile(
      video: widget.filePath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 145, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
      quality: 90,
    );
    setState(() {

    });
  }
  @override
  void initState() {
    super.initState();
    init2();
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
    try {
      final oldcontrol = controller;
      oldcontrol?.stop();
      oldcontrol?.dispose();
    } catch (e) {
      debugPrint(e.toString());
    }
    controller = controllerr;
    controller!.onPlaybackReady.addListener(() {
      _duration = Duration(seconds: controllerr.videoInfo?.duration ?? 0);
      if (_duration!.inSeconds < 1) {
        controller?.onPlaybackEnded.removeListener(endlistener);
        controller?.onPlaybackStatusChanged.removeListener(playbackStatus);
        controller?.onPlaybackPositionChanged.removeListener(positionListener);
      }
    });
    controller!.onPlaybackStatusChanged.addListener(playbackStatus);
    controller!.onPlaybackPositionChanged.addListener(positionListener);
    controller!.onPlaybackEnded.addListener(endlistener);
  }

  void endlistener() async {
    if (!mounted) return;
    if (widget.tapped == true) {
      if (visibility > 0.2) {
        widget.onPause?.call();
      }
    }
    if (visibility > 0.2) {
      final lastVideo = await widget.isLastVideo?.call();
      if (lastVideo == true || leftview>=0) {
        leftview -= 1;
        controller?.play();
      }
    }
  }

  void positionListener() async {
    if (!mounted) return;
    if (widget.tapped == true) {
      final playbackPosition =
          controller?.playbackInfo?.positionFraction ?? 0.0;
      debugPrint("duration: " + playbackPosition.toString());
      final isVideoEnded =
          (controller?.playbackInfo?.positionFraction ?? 0) >= 0.99;
      if (isVideoEnded && _duration!.inSeconds > 1) {
        widget.onPause?.call();
      }
      _currentProgress = playbackPosition;
      setState(() {});
    } else {
      final isVideoEnded =
          (controller?.playbackInfo?.positionFraction ?? 0) >= 0.99;
      // if (isVideoEnded) {
      //   await controller?.play();
      // }
      if (_currentProgress != 0) {
        _currentProgress = 0;
        setState(() {});
      }
    }
  }

  void playbackStatus() {
    if (!mounted) return;
    final playbackStatus =
        controller?.playbackInfo?.status ?? PlaybackStatus.stopped;
    _isPlaying = playbackStatus == PlaybackStatus.playing;
    setState(() {});
  }

  @override
  void dispose() {
     controller?.stop();
     controller?.dispose();
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    debugPrint("Disposed");
    super.dispose();
  }

  double visibility = 1;
  int leftview = 2;
  bool wasInvisible = true;

  void onVisibilityChanged(double visibleFraction) async {
    if (!mounted) return;
    setState(() {
      visibility = visibleFraction;
    });

    if (visibleFraction >= 0.2) {
      if (wasInvisible) {
        wasInvisible = false;
        controller?.play();
        widget.onVisible?.call();
      }
    } else {
      if (!wasInvisible) {
        leftview = 2;
        wasInvisible = true;
        // Widget is not visible
        widget.oninvisible?.call();
        debugPrint("curently invisible");
        disposee2();
      }

    }
  }

  void disposee() async {
    await controller?.pause();
    controller?.onPlaybackEnded.removeListener(endlistener);
    controller?.onPlaybackStatusChanged.removeListener(playbackStatus);
    controller?.onPlaybackPositionChanged.removeListener(positionListener);
    controller?.stop();
  }

  void disposee2() async {
    try {
      await controller?.stop();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _togglePlayPause() async {
    if (controller == null || controller?.videoInfo == null) return;

    if (widget.tapped != true && widget.tapped != null) {
      controller?.setVolume(1.0);
      controller?.seekTo(0);
      controller?.play();
      FocusScope.of(context).unfocus();
      widget.onPlay?.call();
      return;
    }

    if ((await controller!.isPlaying()) == true) {
      controller?.pause();
    } else {
      final isVideoEnded =
          (controller?.playbackInfo?.positionFraction ?? 0) >= 0.9;

      // debugPrint(
      //     "video $isVideoEnded ${_controller?.videoPlayerController?.value.position} - ${_controller?.videoPlayerController?.value.duration}");
      if (widget.tapped != null && widget.tapped != true) {
       await controller?.seekTo(0);
      } else if (isVideoEnded) {
        // Restart the video if it has ended
        await controller?.seekTo(0);
        controller?.play();
      } else {
        controller?.play();
      }
    }
  }

  @override
  void didUpdateWidget(VideoWidget oldWidget) {
    if (widget.tapped != true && widget.tapped != null) {
      controller?.setVolume(0);
    } else if (widget.tapped == true && oldWidget.tapped!=true) {
        controller?.seekTo(0).then((onValue) {
          controller?.setVolume(1);
          controller?.play();
        });
    }
     if (widget.tapped != true && oldWidget.tapped==true) {
      if (visibility > 0.1 ) {
        controller?.seekTo(0).then((onValue) {
          controller?.play();
        });
      }
    }
    if(widget.tapped==true && (controller?.playbackInfo?.volume??0)<1){
      controller?.setVolume(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.filePath),
      onVisibilityChanged: (visibilityInfo) {
        debugPrint("visibility changed ${visibilityInfo.visibleFraction}");
        onVisibilityChanged(visibilityInfo.visibleFraction);
      },
      child: GestureDetector(
        onTap: () {
          _togglePlayPause();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if(thumbNail!=null)
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                    shape: BoxShape.circle
                ),
                width: widget.width,
                height: widget.height,
                child: Image.file(File(thumbNail!),
                  fit: BoxFit.cover,),
              ),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              width: widget.width,
              height: widget.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(800),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child:
                          AspectRatio(
                              aspectRatio: 16 / 9,
                              child: NativeVideoPlayerView(
                                onViewReady: (controller) async {
                                  final videoSource = await VideoSource.init(
                                    path: widget.filePath,
                                    type: VideoSourceType.file,
                                  );
                                  init(controller);
                                  await controller.setVolume(0);
                                  await controller.loadVideoSource(videoSource);
                                  await controller.play();
                                },
                              )),
                    ),
                ),
              ),
            ),
            if (leftview<0 && controller?.playbackInfo?.status!=PlaybackStatus.playing && widget.tapped != true)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                top: 0,
                child: UnconstrainedBox(
                    child: GestureDetector(
                  onTap: _togglePlayPause,
                  child:  Icon(Icons.play_circle_rounded,size: 65,
                      color:Color(0xFFE1FEC6) ),
                )),
              ),
            if (!widget.show)
              SizedBox(
                width: widget.width + 12,
                height: widget.height + 12,
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
                (controller!.playbackInfo?.volume ?? 0) <= 0.1 &&
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
                (controller!.playbackInfo?.volume ?? 0) > 0.1 &&
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
