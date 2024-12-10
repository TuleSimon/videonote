import 'dart:async';

import 'package:audionotee/camera_audionote.dart';
import 'package:audionotee/micheals/timer_controller.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'overlay_screen.dart';
import 'widgets/mini_video_player.dart';

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
  final Function(String) onCropped;
  final Function() onTap;

  const VideNotebutton(
      {super.key,
      required this.onAddFile,
      required this.onCropped,
      required this.onTap});

  @override
  State<VideNotebutton> createState() => _CameraPageState();
}

class _CameraPageState extends State<VideNotebutton> {
  String? _videoPath;
  String? _croppedvideoPath;

  double buttonOffsetY = 0.0; // Vertical offset
  double buttonOffsetX = 0.0;
  ValueNotifier<DragValue> buttonOffsetX2 =
      ValueNotifier(DragValue(x: 0, y: 0));
  double defScale = 1.2; // Horizontal offset
  late double scale = defScale;
  final CameraController cameraController = CameraController();
  final RecordingController _recordingController = RecordingController();

  bool isCurrentlyRecording = false;
  bool isLocked = false;
  bool isValidDuration = false;
  double? lastRecord;

  @override
  void initState() {
    super.initState();
    _recordingController.onDurationExceed = _handleDurationExceed;
  }

  void _handleDurationExceed() async {
    // Stop the recording and update the UI
    cameraController.stopRecording();
    setState(() {
      sendRecording = false;
      isCurrentlyRecording = false;
      isValidDuration = true;
    });
    setStatee?.call(() {});
    lastRecord = _recordingController.stopRecording();

    await Future.delayed(Duration(milliseconds: 500), () {
      setState(() {});
    });
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
      cameraController.startRecording().then((on) {
        _recordingController.startRecording();
      }); // Handle state if needed

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
    cameraController.stopRecording();
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
    buttonOffsetX = 0;
    buttonOffsetY = 0;
    _recordingController.stopRecording();
    try {
      cameraController.stopRecording();
    } catch (e) {
      debugPrint(e.toString());
    }
    myOverayEntry?.remove();
    myOverayEntry = null;
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
      sendRecording = true;
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
    setStatee = null;
  }

  void sendOnDone() {
    isCurrentlyRecording = false;
    isValidDuration = _recordingController.isRecordingValid;
    lastRecord = _recordingController.stopRecording();
    cameraController.stopRecording();
    sendRecording = true;
    if (_videoPath != null) {
      widget.onAddFile(_videoPath!);
    }
    _videoPath = null;
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
      isLocked = false;
      buttonOffsetY = 0;
      buttonOffsetX = 0;
      disposeOverlay();
      lastRecord = null;
      lockObs = 0;
    });
    setStatee?.call(() {});
  }

  void stopRecording() {
    isCurrentlyRecording = false;
    isValidDuration = _recordingController.isRecordingValid;
    lastRecord = _recordingController.stopRecording();
    cameraController.stopRecording();
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
          return (_videoPath != null)
              ? PopScope(
                  canPop: true, // Allow back navigation
                  onPopInvokedWithResult: (bool didPop, Object? result) async {
                    if (didPop) {
                      cancelOnDone();
                      return;
                    }
                  },
                  child: Scaffold(
                    body: Center(
                      child: SizedBox(
                        width: context.getWidth() * 0.9,
                        height: context.getWidth() * 0.9,
                        child: MiniVideoPlayer(
                          radius: context.getWidth() / 2.4,
                          show: true,
                          filePath: _videoPath!,
                          autoPlay: true,
                        ),
                      ),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerFloat,
                    backgroundColor: Colors.white,
                    bottomNavigationBar: Container(
                      height: 100,
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
                            "${lastRecord?.round()}s",
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
                  ),
                )
              : PopScope(
                  canPop: true, // Allow back navigation
                  onPopInvokedWithResult: (bool didPop, Object? result) async {
                    if (didPop) {
                      cancelOnDone();
                      return;
                    }
                  },
                  child: Scaffold(
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
                                  cameraController: cameraController,
                                  lockObs: lockObs,
                                  isLocked: isLocked,
                                  onError: () {
                                    cancelOnLock();
                                  },
                                  onStart: () {
                                    debugPrint("start recording");
                                    startRecording();
                                  },
                                  onDone: (String path) {
                                    _videoPath = path;
                                    debugPrint("OnDonePath is $_videoPath");
                                    setState(() {
                                      sendOnLock();
                                    });
                                  },
                                  offset: value,
                                  onCropped: (String path) {
                                    _croppedvideoPath = path;
                                    widget.onCropped(path);
                                  },
                                );
                              }),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 60,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 10.0),
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
                                            child:
                                                ValueListenableBuilder<double>(
                                              valueListenable:
                                                  _recordingController
                                                      .recordingDuration,
                                              builder:
                                                  (context, duration, child) {
                                                return Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      'assets/recording.svg',
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      formatDuration(
                                                          duration.round()),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            )),
                                        if (!isLocked) ...[
                                          ValueListenableBuilder(
                                              valueListenable: buttonOffsetX2,
                                              builder: (context, value, child) {
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
                                                        "assets/delete.svg",
                                                        width: 25,
                                                        height: 25,
                                                      ),
                                                      const Text(
                                                        "Slide to cancel",
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
                                            builder: (context, value, child) =>
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
                                                  offset:
                                                      Offset(value.x, value.y),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color:
                                                            isCurrentlyRecording
                                                                ? Colors.red
                                                                : const Color(
                                                                    0x2A767680),
                                                        shape: BoxShape.circle),
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: SvgPicture.asset(
                                                      "assets/camera_icon.svg",
                                                      key: ValueKey<bool>(
                                                          isCurrentlyRecording),
                                                      width: 30,
                                                      colorFilter: ColorFilter.mode(
                                                          isCurrentlyRecording
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF858E99),
                                                          BlendMode.srcIn),
                                                      height: 30,
                                                    ),
                                                  ),
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
                                            "assets/delete.svg",
                                            width: 25,
                                            height: 25,
                                          ),
                                        ),
                                        Spacer(),
                                        ValueListenableBuilder<double>(
                                          valueListenable: _recordingController
                                              .recordingDuration,
                                          builder: (context, duration, child) {
                                            return Row(
                                              children: [
                                                Text(
                                                  formatDuration(
                                                      duration.round()),
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
                                            cameraController.stopRecording();
                                            sendOnDone();
                                          },
                                          child: const CircleAvatar(
                                            backgroundColor: Color(0xFFFDD400),
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
                  ),
                );
        });
      },
    );
  }

  StreamController<double> postionStream = StreamController<double>();

  void _showOverlayWithGesture(
      BuildContext context, LongPressStartDetails details) {
    if (myOverayEntry == null) {
      myOverayEntry = getMyOverlayEntry(
          contextt: context, x: buttonOffsetX, y: buttonOffsetY);
      Overlay.of(context).insert(myOverayEntry!);
    }
    setState(() {});
  }

  OverlayEntry? myOverayEntry;

  @override
  Widget build(BuildContext contexts) {
    final size = MediaQuery.of(contexts).size;
    // requestPermission();
    // print("object");

    // Show the camera interface
    return GestureDetector(
        onLongPressStart: (details) async {
          Vibration.vibrate(duration: 500, amplitude: 255);
          _showOverlayWithGesture(context, details);
        },
        onLongPressMoveUpdate: (details) {
          debugPrint("moving ${details.offsetFromOrigin.dy}");
          ;
          setState(() {
            // Dragging up: only allow up movement or return to 0
            if (buttonOffsetX >= -5) {
              if (details.localOffsetFromOrigin.dy < 0 || buttonOffsetY < 0) {
                buttonOffsetX = 0;
                buttonOffsetY = details.localOffsetFromOrigin.dy
                    .clamp(-size.height * 0.2, 0.0);

                debugPrint("Y: " + buttonOffsetY.toString());
                debugPrint("Height " + (size.height * 0.2).toString());

                // Scale decreases as the button moves up and increases as it moves down
                scale = (defScale - (buttonOffsetY.abs() / (size.height * 0.2)))
                    .abs();
                scale = scale.clamp(
                    0.3, defScale); // Clamp scale between 1.0 and 1.5

                buttonOffsetX2.value =
                    DragValue(x: buttonOffsetX, y: buttonOffsetY);
              }
              setStatee?.call(() {});
            }

            // Dragging left: only allow left movement or return to 0
            if (buttonOffsetY.abs() <= 5.0) {
              if (details.localOffsetFromOrigin.dx < 0 || buttonOffsetX < 0) {
                buttonOffsetY = 0;
                buttonOffsetX = details.localOffsetFromOrigin.dx
                    .clamp(-size.width * 0.5, 0.0);
                buttonOffsetX2.value =
                    DragValue(x: buttonOffsetX, y: buttonOffsetY);
              }
              setStatee?.call(() {});
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
          buttonOffsetY =
              details.localPosition.dy.clamp(-size.height * 0.2, 0.0);
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
              cancelOnLock();
            } else {
              if (!isLocked) {
                try {
                  cameraController.stopRecording();
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            scale: 1,
            child: Container(
              decoration: const BoxDecoration(
                  color: Color(0x2A767680), shape: BoxShape.circle),
              padding: const EdgeInsets.all(5),
              child: SvgPicture.asset(
                "assets/camera_icon.svg",
                key: ValueKey<bool>(isCurrentlyRecording),
                width: 30,
                colorFilter: ColorFilter.mode(
                    isCurrentlyRecording
                        ? Colors.white
                        : const Color(0xFF858E99),
                    BlendMode.srcIn),
                height: 30,
              ),
            ),
          ),
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
