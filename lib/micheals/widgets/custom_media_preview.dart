// File: lib/src/widgets/preview/awesome_camera_preview.dart

import 'dart:async';
import 'dart:io';

import 'package:audionotee/micheals/hole_widget.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Import the CameraController

enum CameraPreviewFit {
  fitWidth,
  fitHeight,
  contain,
  cover,
}

/// This is a fullscreen camera preview
/// some part of the preview are cropped so we have a full sized camera preview
class AwesomeCameraPreview extends StatefulWidget {
  final CameraPreviewFit previewFit;
  final Widget? loadingWidget;
  final CameraState state;
  final OnPreviewTap? onPreviewTap;
  final OnPreviewScale? onPreviewScale;
  final CameraLayoutBuilder interfaceBuilder;
  final CameraLayoutBuilder? previewDecoratorBuilder;
  final EdgeInsets padding;
  final Alignment alignment;

  final PictureInPictureConfigBuilder? pictureInPictureConfigBuilder;

  /// **New**: CameraController to control camera actions
  final CameraController? controller;

  const AwesomeCameraPreview({
    super.key,
    this.loadingWidget,
    required this.state,
    this.onPreviewTap,
    this.onPreviewScale,
    this.previewFit = CameraPreviewFit.cover,
    required this.interfaceBuilder,
    this.previewDecoratorBuilder,
    required this.padding,
    required this.alignment,
    this.pictureInPictureConfigBuilder,
    this.controller, // Initialize the controller
  });

  @override
  State<StatefulWidget> createState() {
    return AwesomeCameraPreviewState();
  }
}

class AwesomeCameraPreviewState extends State<AwesomeCameraPreview> {
  PreviewSize? _previewSize;

  final List<Texture> _textures = [];

  PreviewSize? get pixelPreviewSize => _previewSize;

  StreamSubscription? _sensorConfigSubscription;
  StreamSubscription? _aspectRatioSubscription;
  CameraAspectRatios? _aspectRatio;
  double? _aspectRatioValue;
  Preview? _preview;

  // **New**: Reference to CameraController
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    Future.wait([
      widget.state.previewSize(0),
      _loadTextures(),
    ]).then((data) {
      if (mounted) {
        setState(() {
          _previewSize = data[0];
        });
      }
    });

    // Assign the controller
    _cameraController = widget.controller;

    // Listen to sensor config changes
    _sensorConfigSubscription =
        widget.state.sensorConfig$.listen((sensorConfig) {
      _aspectRatioSubscription?.cancel();
      _aspectRatioSubscription =
          sensorConfig.aspectRatio$.listen((event) async {
        final previewSize = await widget.state.previewSize(0);
        if ((_previewSize != previewSize || _aspectRatio != event) && mounted) {
          setState(() {
            _aspectRatio = event;
            switch (event) {
              case CameraAspectRatios.ratio_16_9:
                _aspectRatioValue = 16 / 9;
                break;
              case CameraAspectRatios.ratio_4_3:
                _aspectRatioValue = 4 / 3;
                break;
              case CameraAspectRatios.ratio_1_1:
                _aspectRatioValue = 1;
                break;
            }
            _previewSize = previewSize;
          });
        }
      });
    });

    // **Optional**: Listen to CameraState changes via the controller
    if (_cameraController != null) {
      _cameraController!.currentCameraState?.when(
        onVideoRecordingMode: (_) {
          // Handle state if needed
        },
      );
    }
  }

  Future _loadTextures() async {
    // Get the number of sensors
    final sensors = widget.state.cameraContext.sensorConfig.sensors.length;

    for (int i = 0; i < sensors; i++) {
      final textureId = await widget.state.previewTextureId(i);
      if (textureId != null) {
        _textures.add(
          Texture(textureId: textureId),
        );
      }
    }
  }

  @override
  void dispose() {
    _sensorConfigSubscription?.cancel();
    _aspectRatioSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textures.isEmpty || _previewSize == null || _aspectRatio == null) {
      return widget.loadingWidget ??
          Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          );
    }

    bool isCurrentlyRecording = widget.state.when(
      onVideoRecordingMode: (_) => true,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: HoleWidget(
              child: FittedBox(
                fit: BoxFit.cover, // Ensure the video preview fills the circle
                child: SizedBox(
                  width: _previewSize!.width,
                  height: _previewSize!.height,
                  child: _textures.first,
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: isCurrentlyRecording
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                // Flashlight Button
                if (isCurrentlyRecording)
                  AwesomeFlashButton(state: widget.state),

                // Capture Button
                AwesomeCaptureButton(state: widget.state),

                // Camera Switch Button
                if (isCurrentlyRecording)
                  AwesomeCameraSwitchButton(state: widget.state),
              ],
            ),
          ),
        ],
      ),
      // Optionally, you can remove the bottomSheet if not needed
      // bottomSheet: ...,
    );
  }
}
