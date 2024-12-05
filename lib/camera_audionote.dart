import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class DragActionScreen extends StatefulWidget {
  @override
  _DragActionScreenState createState() => _DragActionScreenState();
}

class _DragActionScreenState extends State<DragActionScreen> {
  late final CameraController _cameraController = CameraController();
  bool _isRecording = true;
  bool _isDragMode = false; // Whether drag mode is active

  double buttonOffsetY = 0.0; // Vertical offset
  double buttonOffsetX = 0.0;
  double defScale = 1.2; // Horizontal offset
  late double scale = defScale; // Initial scale

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  bool _hasPermission = false;
  Future<void> _checkPermission() async {
    final hasPermission = await requestCameraPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) {
      WidgetsBinding.instance.addPostFrameCallback((res) {
        _cameraController.startRecording();
        startTimer();
      });
      return true;
    }

    final status = await Permission.camera.request();
    WidgetsBinding.instance.addPostFrameCallback((res) {
      _cameraController.startRecording();
      startTimer();
    });
    return status.isGranted;
  }

  int totalTime = 60; // Total time in seconds
  late int remainingTime = totalTime; // Remaining time
  late Timer timer;

  double getProgress() => (totalTime - remainingTime) / totalTime;

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer.cancel(); // Stop the timer when it reaches 0
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel(); // Clean up the timer
    super.dispose();
  }

  Timer? _longPressTimer; // Timer for long press

  bool locked = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(children: [
        // Camera overlay
        _hasPermission
            ? Align(
                alignment: Alignment.center,
                child: FittedBox(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(500),
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                        width: context.getWidth() * 0.7,
                        height: context.getWidth() * 0.7,
                        child: CameraAwesomeBuilder.awesome(
                          saveConfig: SaveConfig.video(),
                          controller: _cameraController,
                          onMediaCaptureEvent: (event) {
                            switch ((
                              event.status,
                              event.isPicture,
                              event.isVideo
                            )) {
                              case (MediaCaptureStatus.capturing, true, false):
                                debugPrint('Capturing picture...');
                              case (MediaCaptureStatus.success, true, false):
                                event.captureRequest.when(
                                  single: (single) {
                                    debugPrint(
                                        'Picture saved: ${single.file?.path}');
                                  },
                                  multiple: (multiple) {
                                    multiple.fileBySensor.forEach((key, value) {
                                      debugPrint(
                                          'multiple image taken: $key ${value?.path}');
                                    });
                                  },
                                );
                              case (MediaCaptureStatus.failure, true, false):
                                debugPrint(
                                    'Failed to capture picture: ${event.exception}');
                              case (MediaCaptureStatus.capturing, false, true):
                                debugPrint('Capturing video...');
                              case (MediaCaptureStatus.success, false, true):
                                event.captureRequest.when(
                                  single: (single) {
                                    debugPrint(
                                        'Video saved: ${single.file?.path}');
                                  },
                                  multiple: (multiple) {
                                    multiple.fileBySensor.forEach((key, value) {
                                      debugPrint(
                                          'multiple video taken: $key ${value?.path}');
                                    });
                                  },
                                );
                              case (MediaCaptureStatus.failure, false, true):
                                debugPrint(
                                    'Failed to capture video: ${event.exception}');
                              default:
                                debugPrint('Unknown event: $event');
                            }
                          },
                        )),
                  ),
                ))
            : Container(color: Colors.black),

        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: context.getWidth() * 0.73,
            height: context.getWidth() * 0.73,
            child: CircularProgressIndicator(
              value: getProgress(),
              strokeWidth: 8.0,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              backgroundColor: Colors.grey[300],
            ),
          ),
        ),

        if (!locked) ...[
          Transform.translate(
            offset: Offset(buttonOffsetX, 0),
            child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black26),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(right: 120),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_left,
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Slide to cancel",
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                )),
          ),
          Positioned(
              bottom: 0.4,
              right: 10,
              child: Padding(
                padding: horizontalPadding.copyWith(bottom: 70),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    height: (180 - buttonOffsetY.abs()).clamp(40, 180),
                    decoration: BoxDecoration(
                        color: Colors.black26.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 28,
                          color: locked ? Colors.green : Colors.black26,
                        ),
                        const Icon(
                          Icons.keyboard_arrow_up,
                          size: 28,
                          color: Colors.black26,
                        )
                      ],
                    ),
                  ),
                ),
              )),
          // Draggable button
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onLongPressStart: (_) {
                _longPressTimer = Timer(const Duration(milliseconds: 600), () {
                  Vibration.vibrate(
                      duration: 500, amplitude: 255); // Strong vibration
                  setState(() {
                    _isDragMode = true; // Enable drag mode
                  });
                });
              },
              onLongPressMoveUpdate: (details) {
                if (!_isDragMode)
                  return; // Only allow dragging if drag mode is active

                setState(() {
                  // Dragging up: only allow up movement or return to 0
                  if (buttonOffsetX == 0.0) {
                    if (details.localOffsetFromOrigin.dy < 0 ||
                        buttonOffsetY < 0) {
                      buttonOffsetY = details.localOffsetFromOrigin.dy
                          .clamp(-size.height * 0.2, 0.0);
                      debugPrint(buttonOffsetY.toString());
                      debugPrint((size.height * 0.2).toString());

                      // Scale decreases as the button moves up and increases as it moves down
                      scale = (defScale -
                              (buttonOffsetY.abs() / (size.height * 0.2)))
                          .abs();
                      scale = scale.clamp(
                          0.3, defScale); // Clamp scale between 1.0 and 1.5
                    }
                  }

                  // Dragging left: only allow left movement or return to 0
                  if (buttonOffsetY == 0.0) {
                    if (details.localOffsetFromOrigin.dx < 0 ||
                        buttonOffsetX < 0) {
                      buttonOffsetX = details.localOffsetFromOrigin.dx
                          .clamp(-size.width * 0.5, 0.0);
                    }
                  }

                  // Trigger actions based on drag thresholds
                  if (buttonOffsetY == -size.height * 0.2) {
                    setState(() {
                      locked = true;
                    });
                  }
                  if (buttonOffsetX == -size.width * 0.5) {
                    _cameraController.stopRecording();
                    timer.cancel(); // Cancel and exit
                  }
                });
              },
              onLongPressEnd: (_) {
                // Cancel the timer and reset drag mode
                _longPressTimer?.cancel();
                setState(() {
                  _isDragMode = false;
                  buttonOffsetY = 0.0;
                  buttonOffsetX = 0.0;
                  scale = defScale;
                });
              },
              child: Padding(
                padding: horizontalPadding.copyWith(
                    bottom: context.getBottomPadding()),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 100),
                  scale: scale,
                  child: Transform.translate(
                    offset: Offset(buttonOffsetX, buttonOffsetY),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (locked) ...[
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: horizontalPadding.copyWith(bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      size: 30,
                    ),
                    onPressed: () {
                      _cameraController.switchCamera();
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          timer.cancel();
                          _cameraController.stopRecording();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause),
                        onPressed: () {
                          _cameraController.stopRecording();
                        },
                      ),
                      const Icon(Icons.send),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ]),
    );
  }
}

extension ContExtension on BuildContext {
  Size getSize() {
    return MediaQuery.of(this).size;
  }

  double getWidth() {
    return getSize().width;
  }

  double getBottomPadding() {
    return MediaQuery.of(this).padding.bottom;
  }

  double getTopPadding() {
    return MediaQuery.of(this).padding.top;
  }

  double getBottomInsets() {
    return MediaQuery.of(this).viewInsets.bottom;
  }

  double getCombinedBottomPadding() {
    return getBottomPadding() + getBottomInsets();
  }
}

const horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
