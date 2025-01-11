import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:collection/collection.dart' show IterableExtension;

class ReusableVideoListController extends Equatable {
  final List<BetterPlayerController> betterPlayerControllerRegistry;
  final List<BetterPlayerController> usedBetterPlayerControllerRegistry;

  ReusableVideoListController({
    this.betterPlayerControllerRegistry = const [],
    this.usedBetterPlayerControllerRegistry = const [],
  });

  ReusableVideoListController copyWith({
    List<BetterPlayerController>? betterPlayerControllerRegistry,
    List<BetterPlayerController>? usedBetterPlayerControllerRegistry,
  }) {
    return ReusableVideoListController(
      betterPlayerControllerRegistry: betterPlayerControllerRegistry ??
          this.betterPlayerControllerRegistry,
      usedBetterPlayerControllerRegistry: usedBetterPlayerControllerRegistry ??
          this.usedBetterPlayerControllerRegistry,
    );
  }

  /// Adds a controller to the betterPlayerControllerRegistry and returns a new instance
  ReusableVideoListController addToBetterPlayerRegistry(
      BetterPlayerController controller) {
    return ReusableVideoListController(
      betterPlayerControllerRegistry: [
        ...betterPlayerControllerRegistry,
        controller
      ],
      usedBetterPlayerControllerRegistry: usedBetterPlayerControllerRegistry,
    );
  }

  /// Removes a controller from the betterPlayerControllerRegistry and returns a new instance
  ReusableVideoListController removeFromBetterPlayerRegistry(
      BetterPlayerController controller) {
    return ReusableVideoListController(
      betterPlayerControllerRegistry: betterPlayerControllerRegistry
          .where((c) => c != controller)
          .toList(),
      usedBetterPlayerControllerRegistry: usedBetterPlayerControllerRegistry,
    );
  }

  /// Adds a controller to the usedBetterPlayerControllerRegistry or updates it if it already exists
  ReusableVideoListController addToUsedBetterPlayerRegistry(
      BetterPlayerController controller) {
    // Check if the controller already exists in the registry
    final existingIndex = usedBetterPlayerControllerRegistry.indexWhere(
          (existingController) => existingController == controller,
    );

    // Update the registry if the controller exists
    List<BetterPlayerController> updatedRegistry;
    if (existingIndex != -1) {
      updatedRegistry = List.from(usedBetterPlayerControllerRegistry);
      updatedRegistry[existingIndex] = controller;
    } else {
      // Add the new controller to the registry
      updatedRegistry = [
        controller,
        ...usedBetterPlayerControllerRegistry,
      ];
    }

    // Return a new instance with the updated registry
    return ReusableVideoListController(
      betterPlayerControllerRegistry: betterPlayerControllerRegistry,
      usedBetterPlayerControllerRegistry: updatedRegistry,
    );
  }

  /// Removes a controller from the usedBetterPlayerControllerRegistry and returns a new instance
  ReusableVideoListController removeFromUsedBetterPlayerRegistry(
      BetterPlayerController controller) {
    return ReusableVideoListController(
      betterPlayerControllerRegistry: betterPlayerControllerRegistry,
      usedBetterPlayerControllerRegistry: usedBetterPlayerControllerRegistry
          .where((c) => c != controller)
          .toList(),
    );
  }

  /// Disposes all controllers
  void dispose() {
   try {
     for (final controller in betterPlayerControllerRegistry) {
       controller.dispose(forceDispose: true);
     }
     for (final controller in usedBetterPlayerControllerRegistry) {
       controller.dispose(forceDispose: true);
     }
   }
   catch(e){}
  }

  @override
  List<Object> get props {
    return [betterPlayerControllerRegistry,usedBetterPlayerControllerRegistry];
  }


}
