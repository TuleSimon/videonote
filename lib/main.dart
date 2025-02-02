import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:videonote/camera_audionote.dart';
import 'package:videonote/reusuable/reusable_video_list_page.dart';
import 'package:videonote/micheals/widgets/mini_video_player_better.dart';
import 'package:videonote/videonote.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() async {
  runApp(ProviderScope(
      child: MyApp()
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> recording = [];
  int currentlyTapped = -1;

  @override
  void initState() {
    requestStoragePermission();
    super.initState();
  }

  Future<bool> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return await requestManageExternalStoragePermission();
  }

  Future<bool> requestManageExternalStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      return await Permission.manageExternalStorage
          .request()
          .isGranted;
    }
  }

  bool shouldHide = false;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text("VideoNotes"),),
        backgroundColor: Colors.amber,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // Handle attachment action
                },
              ),

              // Comment Input Field
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Write comment",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {
                        // Handle emoji picker
                      },
                    ),
                  ),
                ),
              ),
              VideNotebutton(
                  onAddFile: (file,id) async {
                    debugPrint("here $file");
                   // recording.add(file);
                    shouldHide = false;
                  //   final result = await Share.shareXFiles([XFile(file)]);
                    setState(() {});
                  },
                  onStarted: (id) {
                    shouldHide = true;
                    setState(() {

                    });
                  },
                  onCancel: () {
                    shouldHide = false;
                    setState(() {

                    });
                  },
                  getFilePath: (name) async {
                    final directory = Platform.isIOS
                        ? await getApplicationDocumentsDirectory()
                        : await getDownloadsDirectory();
                    if (!await directory!.exists()) {
                      await directory.create(recursive: true);
                    }
                    var uuid = Uuid();

                    final outputPath =
                        '${directory?.path}/output_circular_${uuid.v4()}.mp4';
                    return File(outputPath);
                  },
                  onCropped: (file,id) async {
                    debugPrint("here cropped $file");
                    recording.add(file);
                    shouldHide = false;
                    setState(() {});
                //    final result = await Share.shareXFiles([XFile(file)]);
                  },
                  child: Icon(Icons.camera),
                  onTap: () async {}),
            ],
          ),
        ),
        body: GestureDetector(
          // Detect taps outside the MiniVideoPlayer
            onTap: () {
              if (currentlyTapped != -1) {
                setState(() {
                  currentlyTapped = -1; // Reset the tapped index
                });
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: recording.length,
                itemBuilder: (context, index) {
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    child: MiniVideoPlayerBetter(
                      width: currentlyTapped == index
                          ? context
                          .getSize()
                          .width * 0.9
                          : context
                          .getSize()
                          .width * 0.7,
                      height: currentlyTapped == index
                          ? context
                          .getSize()
                          .width * 0.9
                          : context
                          .getSize()
                          .width * 0.7,
                      tapped: currentlyTapped == index,
                      onPlay: () {
                        currentlyTapped = index;
                        setState(() {});
                      },
                      onPause: () {
                        currentlyTapped = -1;
                        setState(() {});
                      },
                      shouldHide: shouldHide,
                      filePath: recording[index],
                      show: false,
                    ),
                  );
                },
              ),
            )),
      ),
    );
  }
}
