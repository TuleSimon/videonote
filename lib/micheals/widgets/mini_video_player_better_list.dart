import 'dart:io';
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:videonote/micheals/overlay_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MiniVideoPlayerPlaylist extends StatefulWidget {
  final List<String> filePaths;
  final bool autoPlay;
  final double width;
  final double height;
  final double radius;
  final Function()? onPlay;
  final Function()? onPause;
  final Function(Duration)? onDuration;

  const MiniVideoPlayerPlaylist({
    super.key,
    required this.filePaths,
    this.autoPlay = false,
    this.width = 200,
    this.height = 200,
    this.radius = 200,
    this.onPlay,
    this.onPause,
    this.onDuration,
  });

  @override
  State<StatefulWidget> createState() {
    return _MiniVideoPlayerPlaylist();
  }
}

class _MiniVideoPlayerPlaylist extends State<MiniVideoPlayerPlaylist> {
  BetterPlayerPlaylistController? _playlistController;
  BetterPlayerController? _currentController;
  bool _isPlaying = false;
  double _currentProgress = 0.0;
  Duration _duration = const Duration();

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
  }

  void _initializePlaylist() {
    final List<BetterPlayerDataSource> dataSources = widget.filePaths
        .where((filePath) => File(filePath).existsSync())
        .map(
          (filePath) => BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        filePath,
      ),
    )
        .toList();

    if (dataSources.isEmpty) {
      debugPrint("No valid file paths provided.");
      return;
    }
    debugPrint("file paths ${widget.filePaths.join(" ")}");

    _playlistController = BetterPlayerPlaylistController(
      dataSources,
      betterPlayerConfiguration: BetterPlayerConfiguration(
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
          showControlsOnInitialize: false,
        ),
        autoPlay: widget.autoPlay,
        looping: true,
        aspectRatio: 6 / 19,
        fit: BoxFit.cover,
        eventListener: _handlePlayerEvents,
      ),
      betterPlayerPlaylistConfiguration: BetterPlayerPlaylistConfiguration(
        loopVideos: true,
        nextVideoDelay: Duration(seconds: 2),
      ),
    );
  }

  void _handlePlayerEvents(BetterPlayerEvent event) {
    if(!mounted) return;
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      setState(() {
        _duration =
            _playlistController?.betterPlayerController?.videoPlayerController
                ?.value.duration ??
                const Duration();
        widget.onDuration?.call(_duration);
        _currentController = _playlistController?.betterPlayerController;
        _currentController?.videoPlayerController?.addListener(_playListener);
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

    if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
      final progress = event.parameters?['progress'] as Duration?;
      final totalDuration = event.parameters?['duration'] as Duration?;

      if (progress != null && totalDuration != null) {
        setState(() {
          _currentProgress =
              progress.inMilliseconds / totalDuration.inMilliseconds;
        });
      }
    }
  }

  void _playListener() {
    if (mounted) {
      setState(() {
        final isVideoEnded =
            (_currentController?.videoPlayerController?.value.position ??
                Duration.zero) >=
                (_currentController?.videoPlayerController?.value.duration ??
                    Duration.zero) -
                    const Duration(milliseconds: 100);
        if (isVideoEnded) {
          _currentProgress = 0.0;
        }
        _isPlaying =
            _currentController?.videoPlayerController?.value.isPlaying ??
                false;
      });
    }
  }

  @override
  void dispose() {
    try {
      _playlistController?.dispose();
    } catch (e) {
      debugPrint("Error disposing playlist controller: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_playlistController == null ||
        _playlistController?.betterPlayerController == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const CircularProgressIndicator(
          color: Colors.amber,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            _togglePlayPause();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: BetterPlayerPlaylist(
                    betterPlayerDataSourceList: widget.filePaths
                        .where((filePath) => File(filePath).existsSync())
                        .map(
                          (filePath) => BetterPlayerDataSource(
                        BetterPlayerDataSourceType.file,
                        filePath,
                      ),
                    ).toList(),
                    betterPlayerConfiguration:  BetterPlayerConfiguration(
                      controlsConfiguration: const BetterPlayerControlsConfiguration(
                        showControls: false,
                        showControlsOnInitialize: false,
                      ),
                      autoPlay: widget.autoPlay,
                      aspectRatio: 6 / 19,
                      fit: BoxFit.cover,
                      eventListener: _handlePlayerEvents,
                    ),
                    betterPlayerPlaylistConfiguration:  BetterPlayerPlaylistConfiguration(
                      loopVideos: true,
                      nextVideoDelay: Duration(seconds: 0),
                    ),
                  ),
                ),
              ),
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
              if (!_isPlaying)
                Center(
                  child: SvgPicture.asset(
                    "assets/play.svg",
                    package: "videonote",
                    width: 65,
                  ),
                ),
              if (_isPlaying)
                Center(
                  child: SvgPicture.asset(
                    "packages/videonote/assets/pause2.svg",
                    width: 65,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _togglePlayPause() {
    if (_currentController == null ||
        _currentController?.videoPlayerController?.value.initialized != true) {
      return;
    }

    setState(() {
      if (_currentController!.videoPlayerController!.value.isPlaying) {
        _currentController?.pause();
        widget.onPause?.call();
      } else {
        _currentController?.play();
        widget.onPlay?.call();
      }
    });
  }
}
