import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dbhelper.dart'; // Import your DatabaseHelper
import 'fiche.dart';

class EspecesPage extends StatefulWidget {
  final String famille;
  final String groupe;

  const EspecesPage({Key? key, required this.famille, required this.groupe})
      : super(key: key);

  @override
  _EspecesPageState createState() => _EspecesPageState();
}

class _EspecesPageState extends State<EspecesPage> {
  late VideoPlayerController _controller;
  List<Map<String, dynamic>> tableData = [];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _fetchData();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/sea_portrait.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  Future<void> _fetchData() async {
    try {
      tableData = await DatabaseHelper.instance
          .getEspecesTableData(widget.groupe, widget.famille);
      setState(() {});
    } catch (e) {
      print('Failed to fetch data: $e');
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Espèces pour ${widget.famille}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Stack(
        children: [
          _buildVideoBackground(),
          _buildEspecesList(),
          _buildLogo(),
        ],
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Positioned.fill(
      child: VideoPlayer(_controller),
    );
  }

  Widget _buildEspecesList() {
  return Padding(
    padding: const EdgeInsets.only(top: 160), // Adjust based on logo size
    child: ListView.builder(
      itemCount: tableData.length,
      itemBuilder: (context, index) {
        var espece = tableData[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(espece['espece'] ?? 'Espece inconnue',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text(espece['description'] ?? 'Pas de description disponible'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FichePage(species: espece),
                ),
              );
            },
          ),
        );
      },
    ),
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
}
