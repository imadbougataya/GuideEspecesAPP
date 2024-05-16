import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:video_player/video_player.dart';

import 'dbhelper.dart'; // Ensure this is correctly pointing to your DatabaseHelper class
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
  String message = 'Recherche de resultats, merci de patienter...';
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
      });
    logger.d('VideoPlayer initialized and playing');
  }

  Future<void> _attemptFetchData() async {
    String tableName =
        tables[widget.index].toLowerCase(); // Ensure table name is lowercase
    try {
      tableData = await DatabaseHelper.instance.getFamillesTableData(tableName);
      setState(() {
        message = tableData.isNotEmpty ? '' : 'Aucun resultat pour $tableName.';
      });
    } catch (e) {
      setState(() => message =
          'Impossible de recuperer les informations. Verifiez votre connection.');
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Familles de l\'ordre ${tables[widget.index]}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Stack(
        children: [
          // Video Background
          _buildVideoBackground(),
          // Content Overlay
          _buildScrollableContentWithLogo(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => logger.d('FloatingActionButton pressed'),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVideoBackground() {
    // Ensure the video covers the entire screen
    return Positioned.fill(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildScrollableContentWithLogo() {
    // Use a ListView to allow for scrolling
    return ListView(
      children: <Widget>[
        // Logo and potentially other content before the list
        _buildLogo(),
        // Message or Data Cards
        if (message.isNotEmpty) _buildMessageOverlay(),
        ...tableData.map((data) => _buildDataCard(data)).toList(),
      ],
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _buildLogo(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(8.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (message.isNotEmpty && index == 0) {
                  // Only show the message in the first position if it's set
                  return _buildMessageOverlay();
                }
                // Adjust index if message is not empty to account for the offset
                int dataIndex = message.isNotEmpty ? index - 1 : index;
                return _buildDataCard(tableData[dataIndex]);
              },
              childCount:
                  message.isNotEmpty ? tableData.length + 1 : tableData.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    return InkWell(
      onTap: () {
        // When the card is tapped, navigate to the EspecesPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EspecesPage(famille: data['famille'], groupe: data['groupe']),
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
                'Espece: ${data['espece'] ?? 'N/A'}', // Changed 'Famille' to 'Espece' for clarity
                style: TextStyle(fontSize: 16),
              ),
              // Add more fields as needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageOverlay() {
    // Message overlay widget, similar to your current implementation
    return Center(
      child: Container(
        padding: EdgeInsets.all(10),
        color: Colors
            .black45, // Semi-transparent black background for better readability
        child: Text(
          message,
          style: TextStyle(fontSize: 20, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // This widget displays the logo; adjust size and margins as needed
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: MediaQuery.of(context).size.width * 0.65,
          height: 120, // Specify your logo height
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
