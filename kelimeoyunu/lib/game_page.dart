import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'game_board_page.dart';
//import 'letter_pool.dart';

class GamePage extends StatefulWidget {
  final String gameId; // Oyun ID'si
  final String myId; // Oyuncunun kendi ID'si
  final String selectedDuration;

  const GamePage({
    super.key,
    required this.gameId,
    required this.myId,
    required this.selectedDuration,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DocumentSnapshot gameDetails;
  late String player1Name;
  late String player2Name;
  late int player1Score;
  late int player2Score;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    _fetchGameDetails();
  }

  // Oyun detaylarını Firestore'dan al
  Future<void> _fetchGameDetails() async {
    DocumentSnapshot gameDoc =
        await _firestore.collection('games').doc(widget.gameId).get();
    setState(() {
      gameDetails = gameDoc;
      player1Name = ''; // Default value
      player2Name = ''; // Default value
      player1Score = 0; // Puan 0
      player2Score = 0; // Puan 0
      gameStarted =
          true; // Oyun bilgileri alındığında oyun başladı kabul edilir
    });

    // Oyuncu adlarını al
    _fetchPlayerNames(gameDoc['player1'], gameDoc['player2']);
  }

  // Oyuncu adlarını ve puanlarını Firestore'dan al
  Future<void> _fetchPlayerNames(String player1Id, String player2Id) async {
    try {
      // Player 1 adını al (kullanicilar koleksiyonundan)
      DocumentSnapshot player1Doc =
          await _firestore.collection('kullanicilar').doc(player1Id).get();
      setState(() {
        player1Name = player1Doc['kullaniciAdi'] ?? 'Oyuncu 1';
        player1Score = 0; // Oyun başında puan sıfır
      });

      // Player 2 adını al (kullanicilar koleksiyonundan)
      DocumentSnapshot player2Doc =
          await _firestore.collection('kullanicilar').doc(player2Id).get();
      setState(() {
        player2Name = player2Doc['kullaniciAdi'] ?? 'Oyuncu 2';
        player2Score = 0; // Oyun başında puan sıfır
      });

      // Oyuncu bilgileri alındıktan sonra, puanları `games` koleksiyonuna kaydedelim
      _initializeGameScores(player1Id, player2Id);
    } catch (e) {
      print("Oyuncu adları ve puanları alınırken hata oluştu: $e");
    }
  }

  // Oyun başladığında oyuncuların puanlarını sıfırlayarak games tablosuna kaydet
  Future<void> _initializeGameScores(String player1Id, String player2Id) async {
    try {
      // Oyun başladığında player1 ve player2'nin puanlarını sıfır olarak kaydediyoruz.
      await _firestore.collection('games').doc(widget.gameId).set({
        'player1': player1Id,
        'player2': player2Id,
        'player1Score': 0, // Oyuncu 1'in puanı sıfır
        'player2Score': 0, // Oyuncu 2'nin puanı sıfır
        'status':
            'started', // Oyun başladığında durumu 'started' olarak işaretliyoruz
        'startTime': FieldValue.serverTimestamp(), // Başlangıç zamanı
      });
    } catch (e) {
      print("Oyun başlatılırken puanlar kaydedilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oyun Başladı"),
        backgroundColor: const Color(0xFF0A2A62),
      ),
      body: Center(
        child:
            gameStarted
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Oyun Başladı!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Oyuncu 1'in adı
                    Text(
                      "Oyuncu 1: $player1Name",
                      style: TextStyle(fontSize: 18),
                    ),
                    // Oyuncu 2'nin adı
                    Text(
                      "Oyuncu 2: $player2Name",
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Oyuna başlamak için GameBoardPage sayfasına yönlendir
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => GameBoardPage(
                                  player1Name: player1Name,
                                  player2Name: player2Name,
                                  player1Score: player1Score,
                                  player2Score: player2Score,
                                  gameId: widget.gameId,
                                  myId: widget.myId,
                                  selectedDuration: widget.selectedDuration,
                                  /*letterPool:
                                      letterPool, // Burada letterPool parametresini ekliyoruz*/
                                ),
                          ),
                        );
                      },
                      child: Text("Oyuna Başla"),
                    ),
                  ],
                )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
