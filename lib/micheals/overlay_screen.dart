// File: lib/overlay_screen.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:audionotee/camera_audionote.dart';
import 'package:audionotee/micheals/timer_controller.dart';
import 'package:audionotee/micheals/widgets/video_processor.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'hole_widget.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen(
      {super.key,
      required this.cameraController,
      required this.onDone,
      required this.onError,
      required this.isLocked,
      required this.isRecording,
      required this.lockObs,
      required this.onStart,
      required this.isValidDuration,
      required this.recordingController});

  final CameraController cameraController;
  final RecordingController recordingController;
  final Function(String path) onDone;
  final Function() onError;
  final Function() onStart;
  final bool isValidDuration;
  final bool isLocked;
  final double lockObs;
  final bool isRecording;

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  bool isRecordingValid = false;
  String? _videoPath; // To store the path of the recorded video
  Future<void> _shareVideoFile(String videoPath) async {
    try {
      // Ensure the file exists before attempting to share
      //  String? n = await exportCVideo(videoPath);
      // String? n = await exportCircularVideo(videoPath);
      //final videoFile = File(n ?? "");

      // Share the video file
      widget.onDone(videoPath);
      final result = await Share.shareXFiles([XFile(videoPath)]);
    } catch (e) {
      print('Error sharing video file: $e');
    }
  }

  Future<void> copyAssetToFile(String assetPath, String targetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;

    await File(targetPath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }

  Future<String> _copyMaskToTemporaryFolder() async {
    final tempDir = await getTemporaryDirectory();
    final maskPath = '${tempDir.path}/mask.png';

    // Load the mask from assets
    final byteData = await rootBundle.load('assets/mask.png');
    final file = File(maskPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return maskPath;
  }

  Future<String?> exportCircularVideo(String inputPath) async {
    print('Input Path: $inputPath');

    // Get the directory to save the output video
    final directory = await getDownloadsDirectory();
    var uuid = Uuid();

    final outputPath = '${directory?.path}/output_circular_${uuid.v4()}.mp4';

    String ffmpegCommand = "";
    if (Platform.isIOS) {
      ffmpegCommand =
          // '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v h264_videotoolbox -b:v 750k -preset ultrafast -pix_fmt yuv420p -ac 2 "$outputPath"';
          """-i $inputPath -vf "crop='min(iw,ih)':'min(iw,ih)',scale=480:480,geq=r='if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))':g='if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))':b='if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))'" -c:v h264_videotoolbox -b:v 750k -preset ultrafast -pix_fmt yuv420p -ac 2 -threads 4 $outputPath""";

      // '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v libx264 -b:v 750k -preset veryfast -pix_fmt yuv420p -ac 2 "$outputPath"';
    } else {
      final maskPath = await _copyMaskToTemporaryFolder();

      // FFmpeg command using the alpha mask
      //  ffmpeg -y -i input.mp4 -loop 1 -i mask_with_alpha.png -filter_complex "[1:v]alphaextract[alf];[0:v][alf]alphamerge" -c:v qtrle -an output.mov
      ffmpegCommand =
          '-i "$inputPath" -i "$maskPath" -filter_complex "[0:v]scale=400:400[video];[1:v]scale=400:400[mask];[video][mask]overlay=0:0[v]" -map "[v]" -c:v h264_mediacodec -pix_fmt yuv420p "$outputPath"';

      //
      // ffmpegCommand =
      //     '-i "$inputPath" -vf "crop=\'min(iw,ih)\':\'min(iw,ih)\',scale=480:480,geq=r=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,p(X,Y))\':g=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,g(X,Y))\':b=\'if(gt((X-W/2)*(X-W/2)+(Y-H/2)*(Y-H/2),(W/2)*(W/2)),0,b(X,Y))\'" -c:v h264_mediacodec -b:v 750k -pix_fmt yuv420p -ac 1 "$outputPath"';
    }
    // Uncomment the following line for iOS hardware acceleration

    // Print the FFmpeg command for debugging
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

        // Set the creation and modification dates to current time
        final now = DateTime.now();
        final outputFile = File(outputPath);
        widget.onDone(outputPath);
        _shareVideoFile(outputPath);

        // Update the file's modification time
        await outputFile.setLastModified(now);
        await outputFile.setLastAccessed(DateTime.now());
        var st = await outputFile.stat();

        // Note: Setting the creation time is not directly supported in Dart.
        // Consider embedding metadata or using platform-specific code if necessary.
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
    print('Output File Path: $outputFile');
    print('Does output file exist? ${await outputFile.exists()}');

    if (await outputFile.exists()) {
      return outputPath;
    } else {
      return null;
    }
  }

  Future<String?> exportCVideo(String iP) async {
    VideoProcessor videoProcessor = VideoProcessor();
    return await videoProcessor.processVideo(iP);
  }

  void _handleMediaCaptureEvent(MediaCapture event) {
    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, false, true):
        debugPrint('Capturing video...');
        break;

      case (MediaCaptureStatus.success, false, true):
        event.captureRequest.when(
          single: (single) async {
            debugPrint('Video saved: ${single.file?.path}');
            final Map<String, dynamic> videoDetails = {};
            exportCircularVideo(single.file?.path ?? "");
            // Step 1: Get basic details using video_player
            final file = File(single.file?.path ?? "");
            final size = file.lengthSync(); // Get file size in bytes
            videoDetails['size'] =
                '${(size / (1024 * 1024)).toStringAsFixed(2)} MB'; // Convert to MB
            print(videoDetails);
            if (widget.recordingController.isRecordingValid) {
              debugPrint("Reach here duration");
              setState(() {
                _videoPath = single.file?.path;
              });
              //   widget.onDone(single.file!.path!);
            } else {
              debugPrint("Invalid duration ${isRecordingValid}");
              widget.onError();
            }
          },
          multiple: (multiple) {
            multiple.fileBySensor.forEach((key, value) {
              debugPrint('Multiple videos taken: $key ${value?.path}');
              setState(() {
                _videoPath = value?.path;
              });
            });
          },
        );
        break;

      case (MediaCaptureStatus.failure, false, true):
        debugPrint('Failed to capture video: ${event.exception}');
        break;

      default:
        debugPrint('Unknown event: $event');
    }
  }

  bool pause = false;

  void init() async {
    await Future.delayed(Duration(seconds: 2));
    widget.onStart();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(.7),
        body: Container(
          color: Colors.transparent,
          width: MediaQuery.sizeOf(context).width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: HoleWidget(
                        radius: context.getWidth() / 2.35,
                        child: AspectRatio(
                          aspectRatio: 1 / 1.4,
                          child: CameraAwesomeBuilder.awesome(
                            onMediaCaptureEvent: _handleMediaCaptureEvent,
                            saveConfig: SaveConfig.video(
                              videoOptions: VideoOptions(
                                enableAudio: true,
                                quality: VideoRecordingQuality.lowest,
                                ios: CupertinoVideoOptions(
                                  fps: 30,
                                  codec: CupertinoCodecType.hevc,
                                ),
                                android: AndroidVideoOptions(
                                  bitrate: 800000,
                                  fallbackStrategy:
                                      QualityFallbackStrategy.lower,
                                ),
                              ),
                            ),
                            sensorConfig: SensorConfig.single(
                              sensor: Sensor.position(SensorPosition.front),
                              flashMode: FlashMode.auto,
                              aspectRatio: CameraAspectRatios.ratio_1_1,
                              zoom: 0.0,
                            ),
                            enablePhysicalButton: true,
                            previewAlignment: Alignment.center,
                            previewFit: CameraPreviewFit.fitWidth,
                            controller:
                                widget.cameraController, // Pass the controller
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: ValueListenableBuilder<double>(
                        valueListenable:
                            widget.recordingController.recordingDuration,
                        builder: (context, duration, child) {
                          return CustomPaint(
                            size: const Size(380, 380),
                            painter: CircularProgressPainter(
                              radius: context.getWidth() / 2.2,
                              progress: duration.toDouble(),
                              color: Colors.yellow,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            await widget.cameraController.toggleFlash();
                            setState(
                                () {}); // Update the UI to reflect the flash mode change
                          },
                          child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Center(
                                child:
                                    widget.cameraController.currentFlashMode !=
                                            FlashMode.always
                                        ? Icon(widget.cameraController
                                                    .currentFlashMode ==
                                                FlashMode.on
                                            ? Icons.flash_on
                                            : Icons.flash_auto)
                                        : SvgPicture.asset(
                                            "assets/flash_icon.svg",
                                            width: 25,
                                          ),
                              )),
                        ),

                        const SizedBox(width: 10),
                        GestureDetector(
                            onTap: () async {
                              try {
                                await widget.cameraController.switchCamera();
                              } catch (e) {}
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: SvgPicture.asset(
                                "assets/camera_switch_icon.svg",
                                width: 25,
                              ),
                            )),

                        // Switch Camera Button
                      ],
                    ),
                    Row(
                      children: [
                        widget.isLocked
                            ? InkWell(
                                onTap: () {
                                  isRecordingValid = widget
                                      .recordingController.isRecordingValid;
                                  widget.cameraController.stopRecording();
                                  widget.recordingController.pauseRecording();
                                  setState(() {});
                                },
                                child: CircleAvatar(
                                    backgroundColor: const Color(0xFFD92D20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: SvgPicture.asset(
                                        "assets/pause.svg",
                                        width: 25,
                                        height: 25,
                                      ),
                                    )),
                              )
                            : AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  color: Colors.white,
                                ),
                                transform: Matrix4.translationValues(
                                  0, // No horizontal movement
                                  widget.isRecording ? 0 : 200,
                                  // Move vertically (200 units down when collapsed)
                                  0,
                                ),
                                height: 94 + (widget.lockObs * 20),
                                width: 45,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Icon(
                                      widget.isLocked
                                          ? Icons.lock_outlined
                                          : Icons.lock_open_outlined,
                                    ),
                                    SizedBox(
                                      height: 5 +
                                          (widget.lockObs > -0.1
                                              ? widget.lockObs
                                              : 0),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_up_sharp,
                                    ),
                                    if (widget.lockObs > -0.15) ...[
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_up_sharp,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                        const SizedBox(
                          width: 15,
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress; // Expected to be between 0 and 10
  final Color color;
  final double max;
  final double radius;

  CircularProgressPainter(
      {required this.progress,
      required this.color,
      this.max = 30,
      this.radius = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Normalize progress to a value between 0 and 1
    final double normalizedProgress = (progress.clamp(0.0, max)) / max;

    // Convert normalized progress to radians (0 to 2π)
    final double sweepAngle = normalizedProgress * 2 * pi;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius == 0 ? (min(size.width, size.height) / 2) - 4 : radius,
      // (min(size.width, size.height) / 2) -
      //     4, // Ensures the circle fits within the widget
    );

    // Start at the top (-π/2 radians)
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class CircularOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final Paint transparentPaint = Paint()..blendMode = BlendMode.clear;

    final double circleRadius = size.width * 0.4;
    final Offset circleCenter = Offset(size.width / 2, size.height / 2);

    // Draw the overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // Cut out the transparent circle
    canvas.drawCircle(circleCenter, circleRadius, transparentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VideoCroppingPlugin {
  static const MethodChannel _channel = MethodChannel('video_cropping_plugin');

  static Future<String> cropVideoToCircle(String inputPath) async {
    final String outputPath = await _channel.invokeMethod('cropVideoToCircle', {
      'inputPath': inputPath,
      'outputPath':
          '/path/to/output.mp4', // Define your output path dynamically
    });
    return outputPath;
  }
}
