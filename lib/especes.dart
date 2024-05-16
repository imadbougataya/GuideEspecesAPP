import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dbhelper.dart';
import 'fiche.dart'; // Assurez-vous que ce fichier est importé correctement

class EspecesPage extends StatefulWidget {
  final String famille;
  final String groupe;

  EspecesPage({required this.famille, required this.groupe});

  @override
  _EspecesPageState createState() => _EspecesPageState();
}

class _EspecesPageState extends State<EspecesPage> {
  final dbHelper = DatabaseHelper.instance;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/sea_portrait.mp4')
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
        title: Text('${widget.groupe} - ${widget.famille}'),
      ),
      body: Stack(
        children: [
          _controller.value.isInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
              : Container(),
          Column(
            children: [
              _buildLogo(),
              Expanded(child: _buildContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FutureBuilder(
      future: dbHelper.getEspecesTableData(widget.groupe, widget.famille),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(child: Text('Aucune espèce trouvée.'));
        } else {
          final especes = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: especes.length,
            itemBuilder: (context, index) {
              final espece = especes[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FichePage(
                        nom: espece['espece'] ?? 'Espèce inconnue',
                        description: espece['diagnose'] ?? 'Aucune description',
                        image: espece['pictureUrl'] ?? '',
                        habitat: espece['habitats'] ?? 'N/A',
                        alimentation: espece['biology'] ?? 'N/A',
                        taille: espece['tailleMax'] ?? 'N/A',
                        conservationStatus: espece['fisheries'] ?? 'N/A',
                        funFact: espece['observations'] ?? 'N/A',
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          espece['espece'] ?? 'Espèce inconnue',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ordre: ${espece['ordre'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Famille: ${espece['famille'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
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
}
