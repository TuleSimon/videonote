import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:videonote/camera_audionote.dart';
import 'package:better_player/better_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:videonote/micheals/timer_controller.dart';
import 'package:videonote/micheals/widgets/mini_video_player.dart';
import 'package:camera/camera.dart' as Camera2;
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vibration/vibration.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'overlay_screen.dart';
import 'widgets/mini_video_player.dart';
import 'package:videonote/micheals/widgets/mini_video_player_better.dart';
import 'package:videonote/micheals/widgets/mini_video_player_better_list.dart';

DateTime? _recordingStartTime;

class DragValue {
  final double x;
  final double y;

  DragValue({required this.x, required this.y});

  DragValue copyWith({
    double? x,
    double? y,
  }) {
    return DragValue(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class VideNotebutton extends StatefulWidget {
  final Function(String) onAddFile;
  final Function() onStarted;
  final Function(String) onCropped;
  final Future<File> Function(String) getFilePath;
  final Function() onTap;
  final Function()? onCancel;
  double? padding;
  double? size;
  Widget child;

  VideNotebutton(
      {super.key,
      this.padding,
      this.size,
      required this.onAddFile,
      required this.onCropped,
      required this.onStarted,
      required this.getFilePath,
       this.onCancel,
      required this.child,
      required this.onTap});

  @override
  State<VideNotebutton> createState() => _CameraPageState();
}

class _CameraPageState extends State<VideNotebutton> {
  String? _videoPath;
  List<String> _videoPaths = List.empty(growable: true);
  String? _croppedvideoPath;

  double buttonOffsetY = 0.0; // Vertical offset
  double buttonOffsetX = 0.0;
  ValueNotifier<DragValue> buttonOffsetX2 =
      ValueNotifier(DragValue(x: 0, y: 0));
  double defScale = 1.2; // Horizontal offset
  late double scale = defScale;
  Camera2.CameraController? cameraController;
  final RecordingController _recordingController = RecordingController();

  DateTime? _recordingStartTime;
  bool isCurrentlyRecording = false;
  bool isRecordingPaused = false;
  bool isLocked = false;
  bool isValidDuration = false;
  double? lastRecord;

  Future<void> initCamera() async {
    _cameras = await Camera2.availableCameras();
    // Find the front-facing camera
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras[
          0], // Fallback to the first camera if no front camera is found
    );
    cameraController =
        Camera2.CameraController(frontCamera, ResolutionPreset.medium);

  }

  @override
  void initState() {
    super.initState();
    initCamera();
    _recordingController.onDurationExceed = _handleDurationExceed;
  }

  void _handleDurationExceed() async {
    // Stop the recording and update the UI
    stopVideoRecording();
    setState(() {
      isCurrentlyRecording = false;
      isValidDuration = true;
    });
    setStatee?.call(() {});
    lastRecord = _recordingController.stopRecording();
    setState(() {});
    setStatee?.call(() {});
  }

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  var retriesLeft = 5;

  void startRecording() async {
    try {
      isCurrentlyRecording = true;
      isRecordingPaused=false;
      startVideoRecording();

      // cameraController.init(CameraContext())
      //     cameraController.startRecording().then((on) {
      //       _recordingController.startRecording();
      //     }); // Handle state if needed

      lockObs = 0;
      setState(() {});
      setStatee?.call(() {});
    } catch (e) {
      isLocked = false;
      debugPrint(e.toString());
      setState(() {});
      if (retriesLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        retriesLeft -= 1;
        setState(() {});
        startRecording();
      } else {
        cancelOnLock();
      }
    }
  }

  void cancelRecording() {
    isCurrentlyRecording = false;
    isValidDuration = false;
    _recordingController.stopRecording();
    stopVideoRecording();
    lockObs = 0;
    buttonOffsetX = 0;
    buttonOffsetY = 0;
    setState(() {});
    setStatee?.call(() {});
  }

  void lockRecording() {
    debugPrint("LOCK");
    setState(() {
      isLocked = true;
      lockObs = 0;
      isValidDuration = true;
    });
    setStatee?.call(() {});
  }

  void cancelOnLock() {
    isCurrentlyRecording = false;
    isValidDuration = false;
    _recordingStartTime = null;
    buttonOffsetX = 0;
    buttonOffsetY = 0;
    _recordingController.stopRecording();
    try {
      stopVideoRecording(shouldDo: false);
    } catch (e) {
      debugPrint(e.toString());
    }
    _videoPaths.clear();
    disposeOverlay();
    setStatee = null;
    setState(() {
      isLocked = false;
      lastRecord = null;
      lockObs = 0;
    });
    setStatee?.call(() {});
  }

  void sendOnLock() {
    setState(() {
      isCurrentlyRecording = false;
      isValidDuration = _recordingController.isRecordingValid;
      lastRecord = _recordingController.stopRecording();
      buttonOffsetY = 0;
      buttonOffsetX = 0;
      isLocked = false;
      lockObs = 0;
    });
    setStatee?.call(() {});
  }

  void disposeOverlay() {
    myOverayEntry?.remove();
    myOverayEntry = null;
    isRecordingPaused=false;
    duration = null;
    _recordingStartTime = null;
    cameraController?.dispose();
    previewControoler2?.dispose();
    previewControoler?.dispose(forceDispose: true);
    widget.onCancel?.call();
    setState(() {});
    setStatee = null;
  }

  List<String> sent = List.empty(growable: true);

  void sendOnDone() {
    isCurrentlyRecording = false;
    isValidDuration = _recordingController.isRecordingValid;
    lastRecord = _recordingController.stopRecording();
    stopVideoRecording(shouldDo: false);
    sendRecording = true;
    if (_croppedvideoPath != null) {
      widget.onCropped(_croppedvideoPath!);
      sendRecording = false;
      _videoPaths.clear();
    }
    duration = null;
    _videoPath = null;
    _croppedvideoPath = null;
    _videoPaths.clear();
    disposeOverlay();
    isLocked = false;
    lockObs = 0;
    buttonOffsetY = 0;
    buttonOffsetX = 0;
    setState(() {});
    setStatee?.call(() {});
  }

  void cancelOnDone() {
    setState(() {
      _videoPath = null;
      _croppedvideoPath = null;
      duration = null;
      _videoPaths.clear();
      sendRecording = false;
      stopVideoRecording(shouldDo: false);
      isLocked = false;
      buttonOffsetY = 0;
      buttonOffsetX = 0;
      disposeOverlay();
      lastRecord = null;
      lockObs = 0;
    });
    setStatee?.call(() {});
  }

  Future<String?> concatenateVideos(
      List<String> videoPaths, String tempOutputPath) async {
    // Check if all files exist
    for (String path in videoPaths) {
      final file = File(path);
      if (!file.existsSync()) {
        print('File does not exist: $path');
        return null;
      }
    }
    if(Platform.isIOS) {
      try {
        final result = await _methodChannel.invokeMethod('concatVideos', {
          'videoPaths': videoPaths,
          'outputPath': tempOutputPath,
        });
        print('Concatenated video saved at: $result');
        return result as String?;
      } on PlatformException catch (e) {
        print('Error: ${e.message}');
        return null;
      }
    }

    // Create a temporary text file to list all video files
    final concatFilePath = await _createConcatFile(videoPaths);

    // FFmpeg command to concatenate videos
    String concatCommand =
        '-f concat -safe 0 -i "$concatFilePath"  -map 0:v -map 0:a -c:a copy -c:v copy "$tempOutputPath"';

    // Execute the FFmpeg command
     FFmpegKitConfig.enableLogCallback((log) {
      print("FFmpeg log: ${log.getMessage()}");
    });

    final concatResult = await FFmpegKit.execute(concatCommand);
    final returnCode = await concatResult.getReturnCode();

    if (returnCode != null && returnCode.isValueSuccess()) {
      print("Concatenation succeeded: $tempOutputPath");
      return tempOutputPath;
    } else {
      print("Error concatenating videos. Code: ${returnCode?.getValue()}");
      final sessionLog = await concatResult.getLogsAsString();
      print("Session Log: $sessionLog");
      return null;
    }
  }

  Future<String> _createConcatFile(List<String> videoPaths) async {
    final concatFile = File('${(await getTemporaryDirectory()).path}/concat.txt');
    final sink = concatFile.openWrite();

    for (String path in videoPaths) {
      sink.write("file '$path'\n");
    }

    await sink.close();
    return concatFile.path;
  }

  Future<String> _copyMaskToTemporaryFolder() async {
    final tempDir = await getTemporaryDirectory();
    final maskPath = '${tempDir.path}/mask.png';

    // Load the mask from assets
    final byteData =
        await rootBundle.load('packages/videonote/assets/mask.png');
    final file = File(maskPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return maskPath;
  }

  BetterPlayerPlaylistController? previewControoler2;
  BetterPlayerController? previewControoler;
  static const _methodChannel = MethodChannel('com.example.app/video');


  Future<String?> exportCircularVideo(String inputPath) async {
    // Get the directory to save the output video
    final directory = await getDownloadsDirectory();
    var uuid = Uuid();

    final outputPath = (await widget.getFilePath('${uuid.v4()}.mp4')).path;
    final maskPath = await _copyMaskToTemporaryFolder();
    String ffmpegCommand = "";

    if (_videoPaths.isNotEmpty) {
      debugPrint("video paths: ${_videoPaths.join(", ")}");
      final tempOutputPath =  (await widget.getFilePath('${uuid.v4()}.mp4')).path;
      final mergedVideoPath =
          await concatenateVideos([..._videoPaths], tempOutputPath);

      if (mergedVideoPath == null) {
        print('Failed to concatenate videos.');
        return null;
      }
      if (Platform.isIOS) {
        // Call the iOS MethodChannel to clip the video
        try {
          final result = await _methodChannel.invokeMethod('clipVideo', {
            'inputPath': mergedVideoPath,
            'outputPath': outputPath,
          });

          if(result!=null) {
            if (sendRecording) {
              widget.onCropped(outputPath);
              sendRecording = false;
              _videoPaths.clear();
            } else {
              _croppedvideoPath = outputPath;
            }
            return "";
          }
          else{
            disposeOverlay();
          }

        } catch (e) {
          print("Error clipping video on iOS: $e");
          return null;
        }
      }
      // Apply the mask to the concatenated video
      ffmpegCommand =
          '-i "$mergedVideoPath" -i "$maskPath" -filter_complex "[0:v]scale=400:400[video];[1:v]scale=400:400[mask];[video][mask]overlay=0:0[v]" -map "[v]" -c:v libx264 -pix_fmt yuv420p "$outputPath"';
    } else {
      print('Input Path: $inputPath');
      if (Platform.isIOS) {
        // Call the iOS MethodChannel to clip the video
        try {
          final result = await _methodChannel.invokeMethod('clipVideo', {
            'inputPath': inputPath,
            'outputPath': outputPath,
          });

          if(result!=null) {
            if (sendRecording) {
              widget.onCropped(outputPath);
              sendRecording = false;
              _videoPaths.clear();
            } else {
              _croppedvideoPath = outputPath;
            }
            return "";
          }
          else{
            disposeOverlay();
          }

        } catch (e) {
          print("Error clipping video on iOS: $e");
          return null;
        }
      }
      // iOS and Android use libx264 with full GPL
      final maskPath = await _copyMaskToTemporaryFolder();
      ffmpegCommand =
          '-i "$inputPath" -i "$maskPath" -filter_complex "[0:v]scale=400:400[video];[1:v]scale=400:400[mask];[video][mask]overlay=0:0[v]" -map "[v]" -map 0:a? -c:v libx264 -c:a aac -strict experimental -pix_fmt yuv420p "$outputPath"';
    }

    print('FFmpeg Command: $ffmpegCommand');

    // Check if the input file exists
    if (await File(inputPath).exists()) {
      print('Input file exists.');
    } else {
      print('Input file does not exist.');
      return null;
    }

    // Execute the FFmpeg command
    await FFmpegKit.executeAsync(ffmpegCommand, (session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('Video exported successfully to $outputPath');
        if (sendRecording) {
          widget.onCropped(outputPath);
          sendRecording = false;
          _videoPaths.clear();
        } else {
          _croppedvideoPath = outputPath;
        }
        //await Share.shareXFiles([XFile(outputPath)]);

        final outputFile = File(outputPath);
        final now = DateTime.now();
        await outputFile.setLastModified(now);
        await outputFile.setLastAccessed(DateTime.now());
      } else if (ReturnCode.isCancel(returnCode)) {
        print('FFmpeg process was cancelled');
      } else {
        print('FFmpeg process failed with return code $returnCode');
      }
    }, (log) {
      print('FFmpeg Log: ${log.getMessage()}');
    });

    // Check if the output file exists
    final outputFile = File(outputPath);
    if (await outputFile.exists()) {
      return outputPath;
    } else {
      return null;
    }
  }

  void saveFile(String? path) {
    try {
      if (_recordingStartTime == null) return;
      debugPrint('Video saved: ${path}');
      final Map<String, dynamic> videoDetails = {};
      final recordingEndTime = DateTime.now();
      final duration = recordingEndTime.difference(_recordingStartTime!);

      // Step 1: Get basic details using video_player
      final file = File(path ?? "");
      final size = file.lengthSync(); // Get file size in bytes
      videoDetails['size'] =
          '${(size / (1024 * 1024)).toStringAsFixed(2)} MB'; // Convert to MB
      print(videoDetails);
      if (duration.inSeconds >= 2) {
        debugPrint("Reach here duration");

        setState(() {
          if (_videoPaths.isEmpty) {
            _videoPath = path;
            sendOnLock();
          } else {
            _videoPaths.add(path ?? "");
            sendOnLock();
          }
        });
        exportCircularVideo(path ?? "");
      } else {
        debugPrint("Invalid duration ");
        disposeOverlay();
        cancelOnLock();
      }
    } catch (e) {
      disposeOverlay();
      cancelOnLock();
    }
  }

  void stopVideoRecording({bool shouldDo = true}) async {
    if (cameraController?.value?.isRecordingVideo == true) {
      cameraController?.setFlashMode(Camera2.FlashMode.off);
      isCurrentlyRecording = false;
      final file = await cameraController?.stopVideoRecording();
      setState(() {

      });
      setStatee?.call(() {

    });
      if (shouldDo) {
        saveFile(file?.path);
      }
    }
  }

  void startVideoRecording() async {
    if (cameraController?.value?.isRecordingVideo != true) {
      _recordingStartTime = DateTime.now();
      sendRecording = false;
      _croppedvideoPath = null;
      isCurrentlyRecording = true;
      _videoPath = null;
      await cameraController?.startVideoRecording();
      _recordingController.startRecording();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _recordingController.stopRecording();
    cameraController?.dispose();
    super.dispose();
  }

  void stopRecording() {
    isCurrentlyRecording = false;
    isValidDuration = _recordingController.isRecordingValid;
    lastRecord = _recordingController.stopRecording();
    stopVideoRecording(shouldDo: false);
    _videoPaths.clear();
    _videoPath = null;
    lockObs = 0;
    buttonOffsetY = 0;
    buttonOffsetX = 0;
    setState(() {});
    setStatee?.call(() {});
  }

  List<String> recording = [];
  bool sendRecording = false;
  int currentlyTapped = -1;

  double lockObs = 0;
  StateSetter? setStatee;
  Duration? duration;

  // Implement a function to create OverlayEntry
  OverlayEntry getMyOverlayEntry({
    required BuildContext contextt,
    required double x,
    required double y,
  }) {
    final size = MediaQuery.of(context).size;
    return OverlayEntry(
      builder: (context) {
        return StatefulBuilder(builder: (context, setState2) {
          setStatee = setState2;
          return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: (!isCurrentlyRecording && (_videoPath != null || _videoPaths.isNotEmpty) && cameraController?.value?.isRecordingVideo!=true)
                  ? Scaffold(
                      body: Center(
                        child: SizedBox(
                          width: context.getWidth() * 0.9,
                          height: context.getWidth() * 0.9,
                          child: _videoPaths.isEmpty
                              ? MiniVideoPlayerBetter(
                                  width: context.getWidth() * 0.85,
                                  height: context.getWidth() * 0.85,
                                  radius: context.getWidth() / 2.4,
                                  onDuration: (durationn) {
                                    setState2(() {
                                      duration = durationn;
                                    });
                                    setState(() {
                                      duration = durationn;
                                    });
                                    setStatee?.call(() {
                                      duration = durationn;
                                    });
                                  },
                                  show: true,
                                  onController: (control){
                                    previewControoler= control;
                                    setState(() {

                                    });
                                  },
                                  filePath: _videoPath!,
                                  autoPlay: true,
                                )
                              : MiniVideoPlayerPlaylist(
                                  width: context.getWidth() * 0.85,
                                  height: context.getWidth() * 0.85,
                                  radius: context.getWidth() / 2.4,
                                  onDuration: (durationn) {
                                    setState2(() {
                                      duration = durationn;
                                    });
                                    setState(() {
                                      duration = durationn;
                                    });
                                    setStatee?.call(() {
                                      duration = durationn;
                                    });
                                  },
                            onController: (control){
                              previewControoler2= control;
                              setState(() {

                              });
                            },
                                  filePaths: _videoPaths!,
                                  autoPlay: true,
                                ),
                        ),
                      ),
                      backgroundColor: Color(0xFF1F29377A).withOpacity(.5),
                      bottomNavigationBar: Container(
                        height: 100,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                onPressed: () {
                                  cancelOnDone();
                                },
                                icon: const Icon(Icons.delete)),
                            Text(
                              "${duration?.inSeconds ?? 0}s",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.red),
                            ),
                            CircleAvatar(
                              backgroundColor: const Color(0xFFFDD400),
                              child: IconButton(
                                onPressed: () {
                                  sendOnDone();
                                },
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : Scaffold(
                      body: Stack(
                        children: [
                          // if (isCurrentlyRecording)
                          IgnorePointer(
                            ignoring: !isCurrentlyRecording,
                            // Disable interaction when not recording
                            child: ValueListenableBuilder(
                                valueListenable: buttonOffsetX2,
                                builder: (context, value, child) {
                                  return OverlayScreen(
                                    isRecording: isCurrentlyRecording,
                                    recordingController: _recordingController,
                                    isValidDuration: isValidDuration,
                                    isRecordingPaused: isRecordingPaused,
                                    cameraController: cameraController,
                                    lockObs: lockObs,
                                    flipCamera: (paths) {
                                      _videoPaths.add(paths);
                                    },

                                    startedTime: _recordingStartTime,
                                    cameras: _cameras,
                                    getFilePath: widget.getFilePath,
                                    isLocked: isLocked,
                                    onError: () {
                                      cancelOnLock();
                                    },
                                    onStart: () {
                                      debugPrint("start recording");
                                      startRecording();
                                    },
                                    onDone: (String path) async{
                                      if(cameraController?.value?.isRecordingPaused==true) {
                                        isRecordingPaused = false;
                                        _recordingController.playRecording();
                                        await cameraController
                                            ?.resumeVideoRecording();
                                        setState(() {

                                        });
                                        setStatee?.call(() {

                                        });
                                      }
                                      else{
                                        isRecordingPaused = true;
                                        _recordingController.pauseRecording();
                                        await cameraController
                                            ?.pauseVideoRecording();
                                        setState(() {

                                        });
                                        setStatee?.call(() {

                                        });
                                      }
                                      // sendRecording = false;
                                      // setState(() {});
                                      // stopVideoRecording();

                                      // _videoPath = path;
                                      // debugPrint("OnDonePath is $_videoPath");
                                      // setState(() {
                                      //   sendOnLock();
                                      // });
                                    },
                                    offset: value,
                                    onCropped: (String path) {
                                      // if (sendRecording) {
                                      //   widget.onCropped(path);
                                      //   sendRecording = false;
                                      // } else {
                                      //   _croppedvideoPath = path;
                                      // }
                                    },
                                  );
                                }),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 60 + context.getBottomPadding(),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 10.0)
                                    .copyWith(
                                        bottom: context.getBottomPadding()),
                                child: !isLocked
                                    ? Stack(
                                        children: [
                                          AnimatedPositioned(
                                              key: ValueKey(true),
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              bottom: 0,
                                              top: 0,
                                              left: isCurrentlyRecording
                                                  ? 0
                                                  : MediaQuery.of(context)
                                                      .size
                                                      .width,
                                              child: ValueListenableBuilder<
                                                  double>(
                                                valueListenable:
                                                    _recordingController
                                                        .recordingDuration,
                                                builder:
                                                    (context, duration, child) {
                                                  return Row(
                                                    children: [
                                                      if(isRecordingPaused)...[
                                                        SvgPicture.asset(
                                                          "packages/videonote/assets/delete.svg",
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                      ],
                                                      if(!isRecordingPaused)...[
                                                      SvgPicture.asset(
                                                        'packages/videonote/assets/recording.svg',
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                      const SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        _recordingStartTime?.getDuration()??"0",
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          color: Colors.red,
                                                        ),
                                                      ),]
                                                    ],
                                                  );
                                                },
                                              )),
                                          if (!isLocked) ...[
                                            ValueListenableBuilder(
                                                valueListenable: buttonOffsetX2,
                                                builder:
                                                    (context, value, child) {
                                                  return AnimatedPositioned(
                                                    duration: const Duration(
                                                        milliseconds: 500),
                                                    left: 0,
                                                    right: value.x.abs(),
                                                    top: 0,
                                                    bottom: 0,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SvgPicture.asset(
                                                          isRecordingPaused?"packages/videonote/assets/pause.svg":"packages/videonote/assets/delete.svg",
                                                          width: 25,
                                                          height: 25,
                                                        ),
                                                         Text(
                                                         isRecordingPaused?"Recording paused": "Slide to cancel",
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xFF475467)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                          ],
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            top: 0,
                                            child: ValueListenableBuilder(
                                              valueListenable: buttonOffsetX2,
                                              builder:
                                                  (context, value, child) =>
                                                      Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: AnimatedScale(
                                                  duration: const Duration(
                                                      milliseconds: 100),
                                                  scale: isCurrentlyRecording
                                                      ? scale
                                                      : 1,
                                                  child: Transform.translate(
                                                    offset: Offset(
                                                        value.x, value.y),
                                                    child: GestureDetector(
                                                        onVerticalDragEnd:
                                                            (details) {
                                                          buttonOffsetY = details
                                                              .localPosition.dy
                                                              .clamp(
                                                                  -size.height *
                                                                      0.2,
                                                                  0.0);
                                                          if (buttonOffsetY <=
                                                              (-size.height *
                                                                  0.1)) {
                                                            setState(() {
                                                              isLocked = true;
                                                            });
                                                            setStatee
                                                                ?.call(() {});
                                                          }
                                                          //  reset drag mode
                                                          setState(() {
                                                            buttonOffsetY = 0.0;
                                                            buttonOffsetX = 0.0;
                                                            buttonOffsetX2
                                                                    .value =
                                                                DragValue(
                                                                    x: buttonOffsetX,
                                                                    y: buttonOffsetY);
                                                            scale = defScale;
                                                            setStatee
                                                                ?.call(() {});
                                                            if (!_recordingController
                                                                .isRecordingValid) {
                                                              cancelOnLock();
                                                            } else {
                                                              if (!isLocked) {
                                                                try {
                                                                  stopVideoRecording();
                                                                  _recordingController
                                                                      .pauseRecording();
                                                                } catch (e) {
                                                                  debugPrint(e
                                                                      .toString());
                                                                }
                                                              }
                                                            }
                                                          });
                                                        },
                                                        onVerticalDragUpdate:
                                                            (details) {
                                                          debugPrint(
                                                              "moving ${details.delta.dy}");
                                                          setState(() {
                                                            // Dragging up: only allow up movement or return to 0
                                                            if (buttonOffsetX >=
                                                                -5) {
                                                              if (details.delta
                                                                          .dy <
                                                                      0 ||
                                                                  buttonOffsetY <
                                                                      0) {
                                                                buttonOffsetX =
                                                                    0;
                                                                buttonOffsetY = details
                                                                    .delta.dy
                                                                    .clamp(
                                                                        -size.height *
                                                                            0.2,
                                                                        0.0);

                                                                debugPrint("Y: " +
                                                                    buttonOffsetY
                                                                        .toString());
                                                                debugPrint("Height " +
                                                                    (size.height *
                                                                            0.2)
                                                                        .toString());

                                                                // Scale decreases as the button moves up and increases as it moves down
                                                                scale = (defScale -
                                                                        (buttonOffsetY.abs() /
                                                                            (size.height *
                                                                                0.2)))
                                                                    .abs();
                                                                scale = scale.clamp(
                                                                    0.3,
                                                                    defScale); // Clamp scale between 1.0 and 1.5

                                                                buttonOffsetX2
                                                                        .value =
                                                                    DragValue(
                                                                        x: buttonOffsetX,
                                                                        y: buttonOffsetY);
                                                              }
                                                              setStatee
                                                                  ?.call(() {});
                                                            }

                                                            // Dragging left: only allow left movement or return to 0
                                                            if (buttonOffsetY
                                                                    .abs() <=
                                                                5.0) {
                                                              if (details.delta
                                                                          .dx <
                                                                      0 ||
                                                                  buttonOffsetX <
                                                                      0) {
                                                                buttonOffsetY =
                                                                    0;
                                                                buttonOffsetX = details
                                                                    .delta.dx
                                                                    .clamp(
                                                                        -size.width *
                                                                            0.5,
                                                                        0.0);
                                                                buttonOffsetX2
                                                                        .value =
                                                                    DragValue(
                                                                        x: buttonOffsetX,
                                                                        y: buttonOffsetY);
                                                              }
                                                              setStatee
                                                                  ?.call(() {});
                                                            }

                                                            // Trigger actions based on drag thresholds
                                                            if (buttonOffsetY <=
                                                                (-size.height *
                                                                    0.1)) {
                                                              setState(() {
                                                                isLocked = true;
                                                              });
                                                              setStatee
                                                                  ?.call(() {});
                                                            }
                                                            if (buttonOffsetX
                                                                    .abs() >=
                                                                size.width *
                                                                    0.3) {
                                                              stopRecording();
                                                              setStatee
                                                                  ?.call(() {});
                                                            }
                                                          });
                                                        },
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              color: isCurrentlyRecording
                                                                  ? Colors.red
                                                                  : const Color(
                                                                      0x2A767680),
                                                              shape: BoxShape
                                                                  .circle),
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5),
                                                          child:
                                                              SvgPicture.asset(
                                                            "packages/videonote/assets/camera_icon.svg",
                                                            key: ValueKey<bool>(
                                                                isCurrentlyRecording),
                                                            width: 30,
                                                            colorFilter: ColorFilter.mode(
                                                                isCurrentlyRecording
                                                                    ? Colors
                                                                        .white
                                                                    : const Color(
                                                                        0xFF858E99),
                                                                BlendMode
                                                                    .srcIn),
                                                            height: 30,
                                                          ),
                                                        )),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              cancelOnLock();
                                            },
                                            icon: SvgPicture.asset(
                                              "packages/videonote/assets/delete.svg",
                                              width: 25,
                                              height: 25,
                                            ),
                                          ),
                                          Spacer(),
                                          ValueListenableBuilder<double>(
                                            valueListenable:
                                                _recordingController
                                                    .recordingDuration,
                                            builder:
                                                (context, duration, child) {
                                              return Row(
                                                children: [
                                                  if(isRecordingPaused)...[
                                                  SvgPicture.asset(
                                                    "packages/videonote/assets/pause.svg",
                                                    colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                                    width: 22,
                                                    height: 22,
                                                  ),
                                                  SizedBox(width: 5)],
                                                  Text(
                                                    isRecordingPaused?"Recording paused":formatDuration(duration.round()),
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              _recordingController
                                                  .pauseRecording();
                                              stopVideoRecording();
                                            },
                                            child: const CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFFFDD400),
                                              child: Icon(
                                                Icons.send,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                              ),
                            ),
                          )
                        ],
                      ),
                      backgroundColor: Colors.transparent,
                    ));
        });
      },
    );
  }

  late List<Camera2.CameraDescription> _cameras;

  StreamController<double> postionStream = StreamController<double>();

  void _showOverlayWithGesture(BuildContext context) async{
    if (myOverayEntry == null) {
      await initCamera();
      if(cameraController?.value?.isInitialized!=true) {
        cameraController!.initialize().then((_) {
          if (!mounted) {
            return;
          }
          myOverayEntry = getMyOverlayEntry(
              contextt: context, x: buttonOffsetX, y: buttonOffsetY);
          Overlay.of(context).insert(myOverayEntry!);
          widget.onStarted();
          setState(() {});
        }).catchError((Object e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
              // Handle access errors here.
                break;
              default:
              // Handle other errors here.
                break;
            }
          }
        });
      }
      else{
        myOverayEntry = getMyOverlayEntry(
            contextt: context, x: buttonOffsetX, y: buttonOffsetY);
        Overlay.of(context).insert(myOverayEntry!);
        widget.onStarted();
      }

    }
    setState(() {});
  }

  OverlayEntry? myOverayEntry;

  bool _hasPermission = false;

  Future<void> _checkPermission() async {
    final hasPermission = await requestCameraPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<bool> requestCameraPermission() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    // If both permissions are already granted
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      debugPrint("Permissions already granted");
      Vibration.vibrate(duration: 500, amplitude: 255);
      _showOverlayWithGesture(context);
      return false;
    }

    // Request permissions if not granted
    final cameraRequest = await Permission.camera.request();
    final microphoneRequest = await Permission.microphone.request();

    if (cameraRequest.isGranted && microphoneRequest.isGranted) {
      return true;
    }

    // If permissions are denied or restricted, guide the user to settings
    if (cameraRequest.isPermanentlyDenied ||
        microphoneRequest.isPermanentlyDenied) {
      debugPrint("Permissions denied. Directing user to settings.");
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Permissions Required"),
          content: Text(
              "Camera and microphone permissions are required. Please enable them in the app settings."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings(); // Open app settings
              },
              child: Text("Open Settings"),
            ),
          ],
        ),
      );
    } else {
      final opened = await openAppSettings(); // Opens the app settings
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open settings")),
        );
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext contexts) {
    final size = MediaQuery.of(contexts).size;
    // requestPermission();
    // print("object");

    // Show the camera interface
    return PopScope(
      canPop: !isCurrentlyRecording,
        onPopInvoked: (bool) async {
          debugPrint("pop here");
          if (isCurrentlyRecording) {
            stopVideoRecording();
            _recordingController.stopRecording();
            cancelOnDone();

          }
         // Allow back button to work normally
        },
        child: GestureDetector(
          onVerticalDragStart: (details) {
            debugPrint("Vertical drag started at ${details.globalPosition}");
          },
          onVerticalDragUpdate: (details) async {
            // Handle vertical drag to start recording
            // Detect upward drag

            buttonOffsetY += details.delta.dy; // Update button's offset
            buttonOffsetY = buttonOffsetY.clamp(
                -size.height * 0.2, 0.0); // Clamp to a max value
            if (buttonOffsetY <= -size.height * 0.15) {
              if (!isCurrentlyRecording) {
                final isGranted = await requestCameraPermission();
                if (isGranted) {
                  setState(() {
                    isLocked = true; // Lock the recording once triggered
                  });
                  _showOverlayWithGesture(context);
                }
              }
            }
            setState(() {});
          },
          onVerticalDragEnd: (details) {
            setState(() {
              buttonOffsetY = 0.0;
              buttonOffsetX = 0.0;
              buttonOffsetX2.value =
                  DragValue(x: buttonOffsetX, y: buttonOffsetY);

              setStatee?.call(() {});
            });
          },
          onLongPressStart: (details) async {
            final isGranted = await requestCameraPermission();
            if (isGranted) {
              debugPrint("started");
              Vibration.vibrate(duration: 500, amplitude: 255);
              _showOverlayWithGesture(context);
            }
          },
          onLongPressMoveUpdate: (details) {
            debugPrint("moving ${details.offsetFromOrigin.dy}");
            setState(() {
              // Dragging up: only allow up movement or return to 0
              if (buttonOffsetX >= -5) {
                if (details.localOffsetFromOrigin.dy < 0 || buttonOffsetY < 0) {
                  final newY = details.localOffsetFromOrigin.dy
                      .clamp(-size.height * 0.2, 0.0);
                  if (newY == buttonOffsetY) return;
                  buttonOffsetX = 0;
                  buttonOffsetY = details.localOffsetFromOrigin.dy
                      .clamp(-size.height * 0.2, 0.0);

                  debugPrint("Y: " + buttonOffsetY.toString());
                  debugPrint("Height " + (size.height * 0.2).toString());

                  // Scale decreases as the button moves up and increases as it moves down
                  scale =
                      (defScale - (buttonOffsetY.abs() / (size.height * 0.2)))
                          .abs();
                  scale = scale.clamp(
                      0.3, defScale); // Clamp scale between 1.0 and 1.5

                  buttonOffsetX2.value =
                      DragValue(x: buttonOffsetX, y: buttonOffsetY);
                  setStatee?.call(() {});
                }
              }

              // Dragging left: only allow left movement or return to 0
              if (buttonOffsetY.abs() <= 5.0) {
                if (details.localOffsetFromOrigin.dx < 0 || buttonOffsetX < 0) {
                  final newX = details.localOffsetFromOrigin.dx
                      .clamp(-size.width * 0.5, 0.0);
                  if (newX == buttonOffsetX) return;
                  buttonOffsetY = 0;
                  buttonOffsetX = details.localOffsetFromOrigin.dx
                      .clamp(-size.width * 0.5, 0.0);
                  buttonOffsetX2.value =
                      DragValue(x: buttonOffsetX, y: buttonOffsetY);
                  setStatee?.call(() {});
                }
              }

              // Trigger actions based on drag thresholds
              if (buttonOffsetY <= (-size.height * 0.1)) {
                setState(() {
                  isLocked = true;
                });
                setStatee?.call(() {});
              }
              if (buttonOffsetX.abs() >= size.width * 0.3) {
                stopRecording();
                setStatee?.call(() {});
              }
            });
          },
          onLongPressEnd: (details) {
            if (buttonOffsetY <= (-size.height * 0.1)) {
              setState(() {
                isLocked = true;
              });
              setStatee?.call(() {});
            }
            //  reset drag mode
            setState(() {
              buttonOffsetY = 0.0;
              buttonOffsetX = 0.0;
              buttonOffsetX2.value =
                  DragValue(x: buttonOffsetX, y: buttonOffsetY);
              scale = defScale;
              setStatee?.call(() {});
              if (!_recordingController.isRecordingValid) {
                if (!isLocked) {
                  cancelOnLock();
                }
              } else {
                if (!isLocked) {
                  try {
                    stopVideoRecording(shouldDo: true);
                    _recordingController.pauseRecording();
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                }
              }
            });
          },
          onTap: () {
            widget.onTap();
          },
          child: widget.child,
        ));
  }
}

class OverlayStateProvider with ChangeNotifier {
  double _buttonOffsetX = 0.0;
  double _buttonOffsetY = 0.0;
  double _scale = 1.0;

  double get buttonOffsetX => _buttonOffsetX;

  double get buttonOffsetY => _buttonOffsetY;

  double get scale => _scale;

  void updateOffsets(double offsetX, double offsetY) {
    _buttonOffsetX = offsetX;
    _buttonOffsetY = offsetY;
    notifyListeners();
  }

  void updateScale(double newScale) {
    _scale = newScale;
    notifyListeners();
  }
}


extension durationUtils on DateTime{

  String getDuration(){
    final recordingEndTime = DateTime.now();
    final duration = recordingEndTime.difference(this);
    return formatDurationToCustomFormat(duration);
  }

}

String formatDurationToCustomFormat(Duration duration) {
  // Get the hour, minute, and second parts
  String hours = duration.inHours.toString().padLeft(2, '0');
  String minutes = (duration.inMinutes % 60).toString().padLeft(1, '0');
  String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

  // Format the string
  return "$minutes:$seconds";
}