import 'package:audionotee/camera_audionote.dart';
import 'package:audionotee/micheals/main.dart';
import 'package:audionotee/micheals/widgets/mini_video_player.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => OverlayStateProvider(),
      builder: (providercontext, child) => MyApp()));
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
      return await Permission.manageExternalStorage.request().isGranted;
    }
  }

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
              VideNotebutton(onAddFile: (file) async {
                recording.add(file);
                setState(() {});
              }),
            ],
          ),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: recording.length,
            itemBuilder: (context, index) {
              ValueNotifier<bool> notifier = ValueNotifier(true);
              return VisibilityDetector(
                key: Key(index.toString()),
                onVisibilityChanged: (info) {
                  notifier.value = info.visibleFraction > 0;
                },
                child: ValueListenableBuilder(
                    valueListenable: notifier,
                    builder: (context, value, child) {
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeIn,
                        child: SizedBox(
                          width: currentlyTapped == index
                              ? context.getSize().width * 0.8
                              : context.getSize().width * 0.5,
                          height: currentlyTapped == index
                              ? context.getSize().width * 0.8
                              : context.getSize().width * 0.5,
                          child: MiniVideoPlayer(
                            isVisible: value,
                            onPlay: () {
                              currentlyTapped = index;
                              setState(() {});
                            },
                            onPause: () {
                              currentlyTapped = -1;
                              setState(() {});
                            },
                            autoPlay: true,
                            filePath: recording[index],
                            show: false,
                          ),
                        ),
                      );
                    }),
              );
            },
          ),
        ),
      ),
    );
  }
}
