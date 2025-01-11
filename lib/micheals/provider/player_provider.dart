import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_player/better_player.dart';
import 'package:videonote/micheals/widgets/registry.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';



class VideoControllerNotifier extends StateNotifier<ReusableVideoListController> {
  VideoControllerNotifier() : super(ReusableVideoListController()) {
    initializeControllers();
  }

  /// Initialize the `betterPlayerControllerRegistry` with 3 controllers.
  void initializeControllers() {

    final controllers = <BetterPlayerController>[];
    for (int index = 0; index < (3); index++) {
      controllers.add(
        BetterPlayerController(

          BetterPlayerConfiguration(
            handleLifecycle: false,
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
        ),
      );
    }
    // Update the state with the new controllers
    state = state.copyWith(betterPlayerControllerRegistry: controllers);
  }


  BetterPlayerController? getBetterPlayerController(String path) {
    debugPrint("Current list ${state.usedBetterPlayerControllerRegistry}");
    BetterPlayerController? existingController = state.usedBetterPlayerControllerRegistry.firstWhereOrNull(
            (controller) =>
        controller.betterPlayerDataSource?.url==path);
    if(existingController!=null){
      return existingController;
    }
    BetterPlayerController? freeController =state.betterPlayerControllerRegistry.firstWhereOrNull(
            (controller) =>
        !state.usedBetterPlayerControllerRegistry.contains(controller));


    if(freeController==null){
      debugPrint("no free controller");
      // state.usedBetterPlayerControllerRegistry.last.pause();
      // freeBetterPlayerController(state.usedBetterPlayerControllerRegistry.last);
      // freeController = state.betterPlayerControllerRegistry.firstWhereOrNull(
      //         (controller) =>
      //         !state.usedBetterPlayerControllerRegistry.contains(controller));
    }
    if (freeController != null) {
      state = state.addToUsedBetterPlayerRegistry(freeController);
    }
    debugPrint("Current list ${state.usedBetterPlayerControllerRegistry}");

    return freeController;
  }

  void freeBetterPlayerController(BetterPlayerController? betterPlayerController) {
    debugPrint("Freeing ${betterPlayerController?.betterPlayerDataSource?.url}");
    if(betterPlayerController==null) return;
    debugPrint("Old list ${state.usedBetterPlayerControllerRegistry}");
    final newList = state.removeFromUsedBetterPlayerRegistry(betterPlayerController!);
   debugPrint("Old list ${newList.usedBetterPlayerControllerRegistry}");
   state = newList;

  }



  void dispose(){
    state.dispose();
    state = ReusableVideoListController();
  }

}

final videoControllerProvider = StateNotifierProvider<VideoControllerNotifier, ReusableVideoListController>(
      (ref) => VideoControllerNotifier(),
);

