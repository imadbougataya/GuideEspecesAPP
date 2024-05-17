import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

import 'dbhelper.dart';
import 'fiche.dart';

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
  final Logger logger = Logger();
  List<Map<String, dynamic>> tableData = []; // Définition de tableData

  @override
  void initState() {
    super.initState();
    logger.i('EspecesPage initialized for groupe: ${widget.groupe}, famille: ${widget.famille}');
    _initializeVideo();
    _fetchData();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/sea_portrait.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
        logger.i('Video initialized and playing.');
      }).catchError((error) {
        logger.e('Error initializing video: $error');
      });
  }

  void _fetchData() async {
    try {
      final data = await dbHelper.getEspecesTableData(widget.groupe, widget.famille);
      setState(() {
        tableData = data;
      });
      logger.i('Data fetched successfully.');
    } catch (error) {
      logger.e('Error fetching data: $error');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    logger.i('EspecesPage disposed.');
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
          logger.e('Error in FutureBuilder: ${snapshot.error}');
          return Center(child: Text('Erreur : ${snapshot.error}'));
        } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          logger.w('No data found.');
          return Center(child: Text('Aucune espèce trouvée.'));
        } else {
          final especes = snapshot.data as List<Map<String, dynamic>>;
          return ListView.builder(
            itemCount: especes.length,
            itemBuilder: (context, index) {
              final espece = especes[index];
              return InkWell(
                onTap: () {
                  logger.i('Navigating to FichePage for espece: ${espece['espece']}');
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
