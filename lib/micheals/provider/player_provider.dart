import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_player/better_player.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

// Define the ControllerData class to hold the controller, id, and timestamp.
class ControllerData {
  BetterPlayerController? controller;
  String? id;
  DateTime? timestamp;

  ControllerData({this.controller, this.id, this.timestamp});

  ControllerData copyWith({
    BetterPlayerController? controller,
    String? id,
    DateTime? timestamp,
  }) {
    return ControllerData(
      controller: controller ?? this.controller,
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class VideoControllerState{

  final ControllerData first;
  final ControllerData second;
  final ControllerData third;
  final ControllerData fourth;

  VideoControllerState({required this.first, required this.second, required this.third, required this.fourth});

}

class VideoControllerNotifier extends StateNotifier<List<ControllerData>> {
  VideoControllerNotifier() : super(List.generate(4, (_) => ControllerData()));

  ControllerData initController(String filePath) {
    // Check if the filePath already exists in any controller.
    final existingController = state.firstWhereOrNull(
          (controllerData) =>
      controllerData.controller != null &&
          controllerData.controller!.betterPlayerDataSource?.url == filePath,
    );

    if (existingController != null) {
      return existingController!;
    }

    // Look for a null controller.
    ControllerData? targetController = state.firstWhereOrNull(
          (controllerData) => controllerData.controller == null,
    );

    if (targetController == null) {
      debugPrint("no old controllers found");
      // If no null controller, find the oldest one.
      targetController = state.where((c) => c.controller != null).reduce(
            (current, next) => current.timestamp!.isBefore(next.timestamp!) ? current : next,
      );


      targetController.controller!.pause();
      targetController.controller!.dispose(forceDispose: true);
      targetController = targetController.copyWith(
        controller: null,
        id: null,
        timestamp: null,
      );
    }

    // Initialize a new BetterPlayerController.
    final newController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoDispose: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
          showControlsOnInitialize: false,
        ),
        autoPlay: true,
        looping: true,
        aspectRatio: 9 / 16,
        fit: BoxFit.cover,
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.file,
        filePath,
      ),
    )..setVolume(0);

    // Update the controller data.
    final updatedController = targetController.copyWith(
      controller: newController,
      id: DateTime.now().toIso8601String(),
      timestamp: DateTime.now(),
    );

    // Update the state with the new list.
    state = state.map((controller) {
      return controller == targetController ? updatedController : controller;
    }).toList();

    return updatedController;
  }

  void disposeOldestController() {
    // Find the controller with the oldest timestamp.
    final oldestController = state.where((c) => c.controller != null).reduce(
          (current, next) => current.timestamp!.isBefore(next.timestamp!) ? current : next,
    );

    // Dispose the oldest controller if it exists.
    if (oldestController.controller != null) {
      oldestController.controller!.dispose();
  
      final updatedController = oldestController.copyWith(
        controller: null,
        id: null,
        timestamp: null,
      );

      // Update the state with the new list.
      state = state.map((controller) {
        return controller == oldestController ? updatedController : controller;
      }).toList();
 
    }
  }

  void disposeControllerById(String id) {
    final targetController = state.firstWhereOrNull((controllerData) => controllerData.id == id);

    if (targetController != null && targetController.controller != null) {
      targetController.controller!.dispose();

      final updatedController = targetController.copyWith(
        controller: null,
        id: null,
        timestamp: null,
      );

      // Update the state with the new list.
      state = state.map((controller) {
        return controller == targetController ? updatedController : controller;
      }).toList();
    }
  }
}

final videoControllerProvider = StateNotifierProvider<VideoControllerNotifier, List<ControllerData>>(
      (ref) => VideoControllerNotifier(),
);

