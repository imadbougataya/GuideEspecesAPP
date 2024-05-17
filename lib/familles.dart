import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

import 'dbhelper.dart';
import 'especes.dart';

class FamillesPage extends StatefulWidget {
  final int index;

  const FamillesPage({Key? key, required this.index}) : super(key: key);

  @override
  _FamillesPageState createState() => _FamillesPageState();
}

class _FamillesPageState extends State<FamillesPage> {
  late VideoPlayerController _controller;
  final logger = Logger(printer: PrettyPrinter());
  String message = 'Recherche de résultats, merci de patienter...';
  List<Map<String, dynamic>> tableData = [];
  List<String> tables = [
    'Lamproies',
    'Myxines',
    'Requins',
    'Batoides',
    'Chimeres',
    'osseux'
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _attemptFetchData();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/sea_portrait.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      }).catchError((error) {
        logger.e('Error initializing video: $error');
      });
    logger.d('VideoPlayer initialized and playing');
  }

  Future<void> _attemptFetchData() async {
    String tableName = tables[widget.index].toLowerCase();
    try {
      tableData = await DatabaseHelper.instance.getFamillesTableData(tableName);
      setState(() {
        message = tableData.isNotEmpty ? '' : 'Aucun résultat pour $tableName.';
      });
    } catch (e) {
      setState(() => message =
          'Impossible de récupérer les informations. Vérifiez votre connexion.');
      logger.e('Failed to fetch data: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    logger.d('VideoPlayer disposed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Familles de Poissons'),
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
    return tableData.isEmpty
        ? _buildMessageOverlay()
        : ListView.builder(
            itemCount: tableData.length,
            itemBuilder: (context, index) {
              final data = tableData[index];
              return InkWell(
                onTap: () {
                  try {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EspecesPage(
                          famille: data['famille'],
                          groupe: tables[widget.index],
                        ),
                      ),
                    );
                  } catch (e) {
                    logger.e('Error navigating to EspecesPage: $e');
                  }
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
                          data['famille'] ?? 'Famille inconnue',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ordre: ${data['ordre'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Espèce: ${data['espece'] ?? 'N/A'}',
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

  Widget _buildMessageOverlay() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(10),
        color: Colors.black45,
        child: Text(
          message,
          style: TextStyle(fontSize: 20, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
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
