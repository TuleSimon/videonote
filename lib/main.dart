import 'package:audionotee/camera_audionote.dart';
import 'package:audionotee/micheals/hole_widget.dart';
import 'package:audionotee/micheals/main.dart';
import 'package:audionotee/micheals/widgets/mini_video_player.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> recording = [];
  int currentlyTapped = -1;

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
              CameraPage(),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(horizontal: 10)
                .copyWith(bottom: 100),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recording.length,
              itemBuilder: (context, index) {
                return AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  child: SizedBox(
                    // color: Colors.black,
                    height: currentlyTapped == index
                        ? context.getSize().height * 0.6
                        : context.getSize().height * 0.4,
                    // width: MediaQuery.of(context).size.width * .8,
                    child: HoleWidget(
                      radius: currentlyTapped == index ? 150 : 100,
                      child: MiniVideoPlayer(
                        onPlay: () {
                          currentlyTapped = index;
                          setState(() {});
                        },
                        onPause: () {
                          currentlyTapped = -1;
                          setState(() {});
                        },
                        filePath: recording[index],
                        show: false,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
