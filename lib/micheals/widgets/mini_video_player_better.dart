import 'dart:io';
import 'dart:async';
import 'package:videonote/micheals/provider/player_provider.dart';
import 'package:videonote/micheals/overlay_screen.dart';
import 'package:videonote/micheals/timer_controller.dart';
import 'package:videonote/micheals/hole_widget.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MiniVideoPlayerBetter extends ConsumerStatefulWidget {
  final String filePath;
  final bool autoPlay;
  final bool? tapped;
  final double width;
  final double height;
  final bool show;
  final bool canBuild;
  final bool shouldHide;
  final double radius;
  final Function()? onPlay;
  final Future<bool> Function()? isLastVideo;
  final Function()? onPause;
  final Function(Duration)? onDuration;
  final Function(BetterPlayerController)? onController;

  const MiniVideoPlayerBetter({
    super.key,
    required this.filePath,
    this.autoPlay = false,
    required this.show,
    this.onPlay,
    this.width = 200,
    this.height = 200,
    this.isLastVideo,
    this.radius = 200,
    this.tapped,
    this.shouldHide = false,
    this.canBuild = true,
    this.onDuration,
    this.onPause,
    this.onController,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _MiniVideoPlayer();
  }
}

class _MiniVideoPlayer extends ConsumerState<MiniVideoPlayerBetter>   with WidgetsBindingObserver{
  BetterPlayerController? _controller;
  bool _isPlaying = false;
  double _currentProgress = 0.0;
  StreamController<BetterPlayerController?>
  betterPlayerControllerStreamController = StreamController.broadcast();
  Timer? _timer;
  Duration _duration = const Duration();
  String? thumbNail;

   void init()async{
     thumbNail = await VideoThumbnail.thumbnailFile(
       video: widget.filePath,
       thumbnailPath: (await getTemporaryDirectory()).path,
       imageFormat: ImageFormat.PNG,
       maxHeight: 64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
       quality: 75,
     );
     setState(() {

     });
   }
  @override
  void initState() {
    super.initState();
init();
    WidgetsBinding.instance.addObserver(this); // Add observer
    // _initializeController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App is back in the foreground
      debugPrint('App resumed');
      if (visiblity >= 0.2) {
        _controller?.play();
      }
    } else if (state == AppLifecycleState.paused) {
      // App is going to the background
      debugPrint('App paused');
      _controller?.pause();
    }
  }

  void playListener() {
    try {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((callback) {
            if (_currentProgress > 0.5) {
              final isVideoEnded =
                  (_controller?.videoPlayerController?.value.position ??
                      Duration(seconds: 0)) >=
                      (Duration(
                          milliseconds: (_controller?.videoPlayerController
                              ?.value
                              .duration?.inMilliseconds ??
                              1) -
                              100));
              // debugPrint("Video edned " + isVideoEnded.toString());
              if (isVideoEnded) {

                WidgetsBinding.instance.addPostFrameCallback((res) {
                  setState(() {
                    _currentProgress = 0;});
                  widget.onPause?.call();
                });
              }


              setState(() {
            _isPlaying =
                _controller?.videoPlayerController?.value.isPlaying ?? false;
              });
          }
        });
      }
    }
    catch(e){

    }
  }

  BetterPlayerController? oldController;

  Future<void> _initializeController() async {
    try {
      if (!File(widget.filePath).existsSync()) return;
      if (widget.filePath.isNotEmpty) {
        if (_controller == null) {
          _controller =
              ref.read(videoControllerProvider.notifier).getBetterPlayerController(widget.filePath);
          if(_controller?.betterPlayerDataSource?.url!=widget.filePath){
            _controller?.setupDataSource(BetterPlayerDataSource(
              BetterPlayerDataSourceType.file,
              bufferingConfiguration: BetterPlayerBufferingConfiguration(
                minBufferMs: 500,
                maxBufferMs: 1000,
                bufferForPlaybackMs: 500,
                bufferForPlaybackAfterRebufferMs: 500,
              ),
              widget.filePath,
            ));
          }
          _controller?.setVolume(0);


          if (!betterPlayerControllerStreamController.isClosed) {
            betterPlayerControllerStreamController.add(_controller);
          }
          _controller?.addEventsListener(playerEvent);
          widget.onController?.call(_controller!);
        }
      } else {
        debugPrint("Invalid file path");
      }
    } catch (e) {
      debugPrint("error " + e.toString());
    }
  }

  bool _initialized = false;

  void _freeController() {
    try {
      if (_controller != null) {
        _controller?.removeEventsListener(playerEvent);
        _controller?.pause();
        _controller?.setVolume(0);
        _controller?.videoPlayerController?.removeListener(playListener);
        ref.read(videoControllerProvider.notifier).freeBetterPlayerController(
            _controller);
        _controller = null;
        if (!betterPlayerControllerStreamController.isClosed) {
          betterPlayerControllerStreamController.add(null);
        }
        _initialized = false;
      }
    }
    catch(e){}
  }

  int leftview = 2;
  void playerEvent(BetterPlayerEvent event) async{
    if (!mounted) return;
    if (_controller?.isVideoInitialized() != true) return;
    if (event.betterPlayerEventType ==
        BetterPlayerEventType.initialized) {
      setState(() {
        _duration =
            _controller?.videoPlayerController?.value.duration ??
                const Duration();
        widget.onDuration?.call(_duration);
        _controller?.videoPlayerController?.addListener(playListener);
      });
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.pause) {
      setState(() {
        _isPlaying = false;
      });
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      final progress = event.parameters?['progress'] as Duration?;
      final totalDuration =
      event.parameters?['duration'] as Duration?;
      if (progress != null && totalDuration != null ) {
        setState(() {
          if (widget.tapped == true) {
            _currentProgress = progress.inMilliseconds /
                totalDuration.inMilliseconds;
          }
        });

        if (_currentProgress >= 0.99) {
          final lastVideo = await widget?.isLastVideo?.call();
          if (widget.tapped == true) {
            widget.onPause?.call();
          }

          if (visiblity > 0.2) {
            if (lastVideo == true || leftview >= 0) {
              setState(() {
                leftview -= 1;
                _controller?.seekTo(Duration(seconds: 0));
                _controller?.play();
              });
            }
          } else {
            _currentProgress = 0;
            debugPrint("Progress or duration is null");
          }
        }
      }
      }
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      // widget.onPause?.call();
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.play) {
        _isPlaying = true;

    }
  }

  double visiblity = 1;

  void onVisibilityChanged(double visibleFraction) async {

    if (visibleFraction >= 0.2) {
      if (!mounted) return;
      setState(() {
        visiblity = visibleFraction;
      });
    } else {
      debugPrint("freeing");
      if (!mounted) return;
      setState(() {
        visiblity = visibleFraction;
      });
    }
  }

  @override
  void dispose() {
    _controller?.videoPlayerController?.removeListener(playListener);
    betterPlayerControllerStreamController.close();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null ||
        _controller?.videoPlayerController?.value.initialized == false) {
      _initializeController();
      return;
    }

    setState(() {
      if (widget.tapped != true && widget.tapped != null) {
        _controller?.setVolume(1.0);
        _controller?.seekTo(const Duration(seconds: 0));
        _controller?.play();
        FocusScope.of(context).unfocus();
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
  void didUpdateWidget(covariant MiniVideoPlayerBetter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.canBuild && !oldWidget.canBuild){
      if(_controller==null ){
        _initializeController();
      }
    }
      if (widget.tapped != null && widget.tapped != true ) {
        _controller?.setVolume(0.0);
        _controller?.setLooping(false);
      }
    if (_controller?.isVideoInitialized() != true) return;

    if (widget.tapped != null && widget.tapped == true) {
      if(oldWidget.tapped!=true) {
        _controller?.seekTo(Duration(seconds: 0));
        _controller?.setVolume(1.0);
        _controller?.setLooping(false);
      }
      _controller?.play();
    }
  }


  bool wasInvisible = true;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
        key: Key(widget.filePath),
        onVisibilityChanged: (visibilityInfo) {
          final visibleFraction = visibilityInfo.visibleFraction;
         visiblity=visibleFraction;
         if(!widget.canBuild){
           debugPrint("---------------- Scrolling so not buildinh Scrolling");
           return;
         }
         //view just became visible init contact
          debugPrint("${visibleFraction} ${widget.radius}");
         if(wasInvisible && visibleFraction>0) {
           wasInvisible=false;
           _timer?.cancel();
           _timer = null;
           _timer = Timer(Duration(milliseconds: 200), () {
               _initializeController();
           });
           return;
         }
         else if(!wasInvisible && visibleFraction<=0){
           leftview = 2;
           _timer?.cancel();
           wasInvisible = true;
           _freeController();
         }

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
              StreamBuilder<BetterPlayerController?>(
                stream: betterPlayerControllerStreamController.stream,
                builder: (context, snapshot) {
                  return Container(
                    width: widget.width,
                    height: widget.height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                          Radius.circular(widget.tapped == true ? 1200 : 300)),
                      child: ClipOval(
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
                                    1, // Flip vertically
                                  ),
                                child: (widget.shouldHide == true ||
                                    visiblity < 0.1 ||
                                    _controller?.isVideoInitialized() != true)
                                    ? Container()
                                    : BetterPlayer(
                                  controller: _controller!,
                                )),
                          ),
                        ),

                      ),
                    ),
                  );
                },
              ),

              if (!widget.show)
                Container(
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
                    )),
              if (widget.show)
                Positioned(
                    left: -1,
                    right: -1,
                    top: -1,
                    bottom: -1,
                    child: CustomPaint(
                      size: Size(widget.width, widget.height),
                      painter: CircularProgressPainter(
                        progress: _currentProgress,
                        color: Colors.yellow,
                        backgroundColor: Colors.transparent,
                        max: 1.0,
                      ),
                    )),

              if (_controller?.videoPlayerController?.value?.isPlaying!=true && (widget.show || widget.tapped!=true))
                  Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      top: 0,
                      child: UnconstrainedBox(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: SvgPicture.asset(
                      "assets/play.svg",
                      package: "videonote",
                      width: 65,
                    ),
                  ),
                )),
              if (_controller?.videoPlayerController?.value?.isPlaying==true && widget.show)
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
                  child: GestureDetector(
                      onTap: () {
                        _controller?.setVolume(1);
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
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            ' ${_duration.inMinutes}:${_duration.inSeconds
                                .remainder(60)}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      )),
                ),
              if (_controller?.videoPlayerController?.value.volume != null &&
                  _controller!.videoPlayerController!.value.volume >= 0.1 &&
                  !widget.show)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                      onTap: () {
                        _controller?.setVolume(0);
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
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            ' ${_duration.inMinutes}:${_duration.inSeconds
                                .remainder(60)}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      )),
                )
            ],
          ),
        ));
  }
}
