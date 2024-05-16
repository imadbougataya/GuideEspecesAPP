import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FichePage extends StatefulWidget {
  //final Map<String, dynamic> species;
  final String famille;
  final String groupe;
  final String espece;
  final String nomFAOFr;


  const FichePage({Key? key, required this.espece,required this.groupe,required this.famille,required this.nomFAOFr}) : super(key: key);

  @override
  _FichePageState createState() => _FichePageState();
}

class _FichePageState extends State<FichePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/sea_background.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Espèces pour ${widget.espece}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Stack(
        children: [
          _buildVideoBackground(),
          _buildLogo(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Positioned.fill(
      child: VideoPlayer(_controller),
    );
  }

  Widget _buildLogo() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: Image.asset(
          'assets/logo.png',
          width: MediaQuery.of(context).size.width * 0.65,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Positioned.fill(
      top: MediaQuery.of(context).size.height * 0.15, // Adjust this to avoid overlap with the logo
      child: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.species['espece'] ?? 'Unknown Species',
                  style: Theme.of(context).textTheme.headline4),
              SizedBox(height: 10),
              Text('Details:',
                  style: Theme.of(context).textTheme.headline6),
              Text(widget.species['description'] ?? 'No details available'),
              SizedBox(height: 20),
              // Add more fields as necessary
              Text('More Info:',
                  style: Theme.of(context).textTheme.headline6),
              Text(widget.species['additionalInfo'] ?? 'No additional information'),
            ],
          ),
        ),
      ),
    );
  }
}
