import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Import the Logger package
import 'package:video_player/video_player.dart';

import 'familles.dart'; // Import the FamillesPage class

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guide Des Especes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromRGBO(1, 86, 135, 1)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Guide des espèces'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VideoPlayerController _controller;
  final logger = Logger(printer: PrettyPrinter()); // Create a Logger instance

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/sea_portrait.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true); // Ensure video continuously loops
      });
    logger.d('Video Player initialized and playing');
  }

  @override
  void dispose() {
    _controller.dispose();
    logger.d('Video Player disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Building MyHomePage widget');
    double imageSize = (MediaQuery.of(context).size.width - 60) / 2; // Adjust based on screen width and desired spacing

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          SizedBox.expand(child: VideoPlayer(_controller)),
          Container(color: Color.fromRGBO(1, 86, 135, 0.5)),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20, // Horizontal spacing
              runSpacing: 20, // Vertical spacing
              children: List.generate(6, (index) => GestureDetector(
                onTap: () {
                  logger.d('Picto $index tapped, navigating to FamillesPage');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FamillesPage(index: index)));
                },
                child: Image.asset('assets/picto_$index.png', width: imageSize),
              )),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: MediaQuery.of(context).size.width * 0.10,
            right: MediaQuery.of(context).size.width * 0.10,
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => logger.d('FloatingActionButton tapped'),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
