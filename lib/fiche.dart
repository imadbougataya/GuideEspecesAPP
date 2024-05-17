import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FichePage extends StatefulWidget {
  final String nom;
  final String description;
  final String image;
  final String habitat;
  final String alimentation;
  final String taille;
  final String conservationStatus;
  final String funFact;

  const FichePage({
    Key? key,
    required this.nom,
    required this.description,
    required this.image,
    required this.habitat,
    required this.alimentation,
    required this.taille,
    required this.conservationStatus,
    required this.funFact,
  }) : super(key: key);

  @override
  _FichePageState createState() => _FichePageState();
}

class _FichePageState extends State<FichePage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/sea_portrait.mp4');
    try {
      await _controller.initialize();
      setState(() {
        _isVideoInitialized = true;
        _controller.play();
        _controller.setLooping(true);
      });
    } catch (e) {
      setState(() {
        _isVideoInitialized = false;
      });
      print('Error initializing video: $e');
    }
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
        title: Text(widget.nom),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Stack(
        children: <Widget>[
          if (_isVideoInitialized)
            SizedBox.expand(child: VideoPlayer(_controller)),
          Container(color: Color.fromRGBO(1, 86, 135, 0.5)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildLogo(),
                  SizedBox(height: 10), // Adjusted spacing between logo and image
                  Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.asset(
                        widget.image.isNotEmpty
                            ? widget.image
                            : 'assets/Image_non_disponible.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/Image_non_disponible.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  _buildInfoGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Reduced vertical padding
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: MediaQuery.of(context).size.width * 0.65,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    final List<Map<String, String>> info = [
      {'title': 'Nom', 'content': widget.nom},
      {'title': 'Description', 'content': widget.description},
      {'title': 'Habitat', 'content': widget.habitat},
      {'title': 'Alimentation', 'content': widget.alimentation},
      {'title': 'Taille', 'content': widget.taille},
      {'title': 'Statut de conservation', 'content': widget.conservationStatus},
      {'title': 'Fait amusant', 'content': widget.funFact},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 1.0, // Adjusted child aspect ratio
      ),
      itemCount: info.length,
      itemBuilder: (context, index) {
        final item = info[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      item['content']!,
                      style: const TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
