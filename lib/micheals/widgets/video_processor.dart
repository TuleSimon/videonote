import 'package:flutter/services.dart';

class VideoProcessor {
  static const platform = MethodChannel('com.example.video_processor');

  Future<String> processVideo(String videoPath) async {
    try {
      final String result =
          await platform.invokeMethod('processVideo', {'videoPath': videoPath});
      return result;
    } on PlatformException catch (e) {
      return "Failed to process video: '${e.message}'.";
    }
  }
}
