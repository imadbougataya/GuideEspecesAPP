import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String _databaseName = 'guideEspeces.db';
  static const int _databaseVersion = 1;
  static const baseServerURL="https://etpqback.ailab.ma";
  //static const baseServerURL="http://10.0.2.2:8080";
  static const String serverUrl =
      '$baseServerURL/api/marine-species/all-familles-for-order/';
  //final logger = Logger(printer: PrettyPrinter());

  final logger = Logger(
  level: Level.debug, // Ensure debug level logging is enabled
  printer: PrettyPrinter(),
);

  static final List<String> tables = [
    'lamproies',
    'myxines',
    'requins',
    'batoides',
    'chimeres',
    'osseux'
  ];

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = path.join(databasesPath, _databaseName);
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (String table in tables) {
      await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY, 
        groupe TEXT, 
        ordre TEXT, 
        famille TEXT, 
        espece TEXT, 
        auteurEtAnnee TEXT, 
        synonymeCommun TEXT, 
        codeAlpha3 TEXT, 
        nomFAOFr TEXT, 
        nomFAOEsp TEXT, 
        nomFAOAng TEXT, 
        vernacularName TEXT, 
        commonName TEXT, 
        arabicName TEXT, 
        halleName TEXT, 
        wormsID TEXT, 
        asfisId TEXT,
        speciesReferencePhoto BLOB, 
        speciesReferencePhotoContentType TEXT,
        speciesDistributionPhoto BLOB,
        speciesDistributionPhotoContentType TEXT,
        statutEvaluationProtectionMenace TEXT,
        statutIndigeneIndetermineIntroduit TEXT,
        valorisation TEXT,
        guideEspeceRemarquesTaxo TEXT,
        guideEspeceRemarquesQualite TEXT,
        guideEspeceRemarquesTaille TEXT,
        guideEspeceRemarquesGenetique TEXT,
        tailleMinimaleCaptureCommentaire TEXT,
        tailleMinimaleCaptureCommentaireAR TEXT,
        tailleMaximaleCaptureCommentaire TEXT,
        tailleMaximaleCaptureCommentaireAR TEXT,
        guideEspeceDescription TEXT,
        guideEspeceDescriptionEspece TEXT,
        guideEspeceDescriptionFamille TEXT,
        guideEspeceHabitat TEXT,
        guideEspeceEnginPeche TEXT,
        guideEspeceDistributionMonde TEXT,
        guideEspeceDistributionMaroc TEXT,
        guideEspeceDescriptionAR TEXT,
        guideEspeceDescriptionEspeceAR TEXT,
        guideEspeceDescriptionFamilleAR TEXT,
        guideEspeceHabitatAR TEXT,
        guideEspeceEnginPecheAR TEXT,
        guideEspeceDistributionMondeAR TEXT,
        guideEspeceDistributionMarocAR TEXT,
        referencePhoto BLOB,
        referenceCapture BLOB
      )
    ''');
    }
  }

  Future<void> fetchFamilleDataIfNeeded(String tableName) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      logger.d(
          "No internet connectivity for table $tableName. Will not fetch data from API.");
    } else {
      logger.d(
          "Internet connectivity found for table $tableName. Attempting to fetch data from API.");
      await _fetchFamilleDataFromAPIWithRetry(tableName);
    }
  }

  Future<void> _fetchFamilleDataFromAPIWithRetry(String tableName,
      {int retries = 5}) async {
    int attempt = 0;
    bool success = false;
    while (attempt < retries && !success) {
      attempt++;
      try {
        await _fetchFamilleDataFromAPI(tableName);
        success = true; // Mark as successful to avoid unnecessary retries
        logger.d(
            "Data fetched successfully from API for table $tableName on attempt $attempt");
      } catch (e) {
        if (e is TimeoutException || e is SocketException) {
          logger.e(
              "Attempt $attempt for table $tableName failed due to network error: $e");
        } else {
          // Break the loop if the error is not related to network issues
          logger.e("Error fetching data not related to network issues: $e");
          break;
        }
      }
      if (!success && attempt < retries) {
        logger.d(
            "Retrying to fetch data for table $tableName. Attempt: $attempt");
      }
    }
    if (!success) {
      logger.e(
          "Max retries reached. Failed to fetch data from API for table $tableName.");
    }
  }

  Future<void> _fetchFamilleDataFromAPI(String tableName) async {
    String tableUrl = tableName;
    if (tableName == "osseux") {
      tableUrl = "poissons osseux";
    }
    var fullUrl = Uri.parse('$serverUrl$tableUrl');
    logger.d('Request URL: $fullUrl');
    try {
      var response = await http
          .get(fullUrl)
          .timeout(const Duration(seconds: 100)); // Set a reasonable timeout

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> jsonData =
            jsonDecode(response.body).cast<Map<String, dynamic>>();
        await _insertJsonData(tableName, jsonData);
        logger.d(
            "Data for table $tableName fetched and inserted into database successfully.");
      } else {
        throw Exception(
            'Failed to fetch data for table $tableName from API, status code: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching data: $e');
      throw Exception('Error fetching data for table $tableName: $e');
    }
  }

  Future<void> _insertJsonData(
      String tableName, List<Map<String, dynamic>> jsonData) async {
        logger.d(
            "_insertJsonData data for table $tableName.");
    final db = await database;
    Batch batch = db.batch();
    jsonData.forEach((row) {
      batch.insert(tableName, row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    var results = await batch.commit();
    logger.d(
        "${results.length} rows inserted into table $tableName successfully.");
  }

  Future<List<Map<String, dynamic>>> getFamillesTableData(
      String tableName) async {

         logger.d(
            "Getting getFamillesTableData for table $tableName.");
        
    await fetchFamilleDataIfNeeded(
        tableName); // Ensure we attempt to fetch updated data
    final db = await database;
    List<Map<String, dynamic>> result =
        await db.query(tableName.replaceAll(' ', '-'));
    if (result.isEmpty) {
      logger.d("No data found in table $tableName.");
    } else {
      logger.d("Data retrieved from table $tableName successfully.");
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getEspecesTableData(
      String groupe, String famille) async {
    final db = await database;
    // Map "poissons osseux" to "osseux" table, otherwise use groupe as the table name
    String tableName =
        (groupe == "poissons osseux") ? "osseux" : "osseux";

 logger.d(
            "getEspecesTableData for table $tableName.");


    List<Map<String, dynamic>> result = await db.query(
      tableName, // Use the tableName for the query
      where: 'famille = ?',
      whereArgs: [famille],
    );
    return result;
  }
}
