import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dashboard_page.dart';

class GameBoardPage extends StatefulWidget {
  final String gameId;
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final String myId;
  final String selectedDuration;

  const GameBoardPage({
    super.key,
    required this.gameId,
    required this.player1Name,
    required this.player2Name,
    required this.player1Score,
    required this.player2Score,
    required this.myId,
    required this.selectedDuration,
  });

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

class _GameBoardPageState extends State<GameBoardPage> {
  final List<List<String>> board = List.generate(
    15,
    (_) => List.generate(15, (_) => ''),
  );
  final List<Map<String, int>> mines = [];
  final List<Map<String, int>> mines2 = [];
  final List<Map<String, int>> mines3 = [];
  final List<Map<String, int>> mines4 = [];
  final List<Map<String, int>> mines5 = [];
  final List<Map<String, int>> prizes = [];
  final List<Map<String, int>> prizes2 = [];
  final List<Map<String, int>> prizes3 = [];
  Timer? _moveTimer;
  Duration _remainingTime = Duration.zero;
  Set<String> validWords = {};
  List<Map<String, dynamic>> myLetters = [];
  String? selectedLetter;
  int? selectedLetterIndex; // hangi harf tıklandı
  Map<String, String> tempPlacedLetters = {};
  bool isCurrentWordValid = true;
  Map<String, int> placedLetterSources =
      {}; 
      bool _gameEnded = false;

  final List<Map<String, dynamic>> letterPool = [
    {'letter': 'A', 'count': 12, 'point': 1},
    {'letter': 'B', 'count': 2, 'point': 3},
    {'letter': 'C', 'count': 2, 'point': 4},
    {'letter': 'Ç', 'count': 2, 'point': 4},
    {'letter': 'D', 'count': 2, 'point': 3},
    {'letter': 'E', 'count': 8, 'point': 1},
    {'letter': 'F', 'count': 1, 'point': 7},
    {'letter': 'G', 'count': 1, 'point': 5},
    {'letter': 'Ğ', 'count': 1, 'point': 8},
    {'letter': 'H', 'count': 1, 'point': 5},
    {'letter': 'I', 'count': 4, 'point': 2},
    {'letter': 'İ', 'count': 7, 'point': 1},
    {'letter': 'J', 'count': 1, 'point': 10},
    {'letter': 'K', 'count': 7, 'point': 1},
    {'letter': 'L', 'count': 7, 'point': 1},
    {'letter': 'M', 'count': 4, 'point': 2},
    {'letter': 'N', 'count': 5, 'point': 1},
    {'letter': 'O', 'count': 3, 'point': 2},
    {'letter': 'Ö', 'count': 1, 'point': 7},
    {'letter': 'P', 'count': 1, 'point': 5},
    {'letter': 'R', 'count': 6, 'point': 1},
    {'letter': 'S', 'count': 3, 'point': 2},
    {'letter': 'Ş', 'count': 2, 'point': 4},
    {'letter': 'T', 'count': 5, 'point': 1},
    {'letter': 'U', 'count': 3, 'point': 2},
    {'letter': 'Ü', 'count': 2, 'point': 3},
    {'letter': 'V', 'count': 1, 'point': 7},
    {'letter': 'Y', 'count': 2, 'point': 3},
    {'letter': 'Z', 'count': 2, 'point': 4},
    {'letter': 'JOKER', 'count': 2, 'point': 0},
  ];

  int _player1Score = 0;
  int _player2Score = 0;

  @override
  void initState() {
    super.initState();
    loadWordList();
    _initializeBoard();
    _loadMyLetters();
    _loadOrCreateItems();

    FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final currentTurn = data['currentTurn'];
        final playerLettersData = data['playerLetters'];
        final myId = widget.myId;

        if (data['gameOver'] == true && !_gameEnded) {
          _gameEnded = true;
          final winnerId = data['winner'];
          final player1Id = widget.gameId.split('_')[0];
          //final player2Id = widget.gameId.split('_')[1];
          final player1Name = widget.player1Name;
          final player2Name = widget.player2Name;

          final winnerName = winnerId == player1Id ? player1Name : player2Name;
          final loserName = winnerId == player1Id ? player2Name : player1Name;
          final isWinner = widget.myId == winnerId;

          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text("Oyun Bitti"),
                content: Text(
                  isWinner
                      ? "Tebrikler, kazandınız!\n\nKazanan: $winnerName\nKaybeden: $loserName"
                      : "Süreniz doldu, oyunu kaybettiniz.\n\nKazanan: $winnerName\nKaybeden: $loserName",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => DashboardPage()),
                      );
                    },
                    child: const Text("Tamam"),
                  ),
                ],
              ),
            );
          });
        }

        if (currentTurn == widget.myId) {
          _startMoveTimer();
        } else {
          _moveTimer?.cancel();
        }

        if (playerLettersData != null && playerLettersData[myId] != null) {
          setState(() {
            myLetters = List<Map<String, dynamic>>.from(
              playerLettersData[myId],
            );
            print('Firestore Listener => myLetters: \$myLetters');
          });
        }

        setState(() {
          _player1Score = data['player1Score'] ?? 0;
          _player2Score = data['player2Score'] ?? 0;
        });

        if (data['placedLetters'] != null) {
          List placedLetters = List.from(data['placedLetters']);
          for (var item in placedLetters) {
            int r = item['row'];
            int c = item['col'];
            String letter = item['letter'];
            board[r][c] = letter;
          }
          setState(() {});
        }
      }
    });
  }

  Duration _getDurationFromSelection(String selectedDuration) {
    switch (selectedDuration) {
      case "2dk":
        return const Duration(minutes: 2);
      case "5dk":
        return const Duration(minutes: 5);
      case "12saat":
        return const Duration(hours: 12);
      case "24saat":
        return const Duration(hours: 24);
      default:
        return const Duration(minutes: 2);
    }
  }

  void _startMoveTimer() {
    _moveTimer?.cancel();
    _remainingTime = _getDurationFromSelection(widget.selectedDuration);

    _moveTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() {
        _remainingTime -= const Duration(seconds: 1);
      });

      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        await _handleTimeoutLoss();
      }
    });
  }

  void resetMoveTimer() {
    if (widget.myId == FirebaseFirestore.instance.collection('games').doc(widget.gameId).id.split('_')[0] ||
        widget.myId == FirebaseFirestore.instance.collection('games').doc(widget.gameId).id.split('_')[1]) {
      _startMoveTimer();
    }
  }

  Future<void> _handleTimeoutLoss() async {
    final uid = widget.myId;
    final gameRef = FirebaseFirestore.instance.collection('games').doc(widget.gameId);
    final loserId = uid;
    final player1Id = widget.gameId.split('_')[0];
    final player2Id = widget.gameId.split('_')[1];
    final winnerId = loserId == player1Id ? player2Id : player1Id;
    final winnerName = loserId == player1Id ? widget.player2Name : widget.player1Name;

    await gameRef.update({
      'gameOver': true,
      'winner': winnerId,
      'winnerName': winnerName,
      'status': 'finished',
    });

    final userRef = FirebaseFirestore.instance.collection('kullanicilar');

    await userRef.doc(winnerId).update({
      'kazanim_sayisi': FieldValue.increment(1),
    });
    await userRef.doc(loserId).update({
      'kayip_sayisi': FieldValue.increment(1),
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

 Widget buildTimerDisplay() {
  final minutes = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');

  return Text(
    "Kalan Süre: $minutes:$seconds",
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );
}

  // Bu fonksiyon onayla butonundan sonra çağrılmalı:
  void onPlayerConfirmedMove() {
    resetMoveTimer();
  }

   
  Future<void> loadWordList() async {
    final String wordData = await rootBundle.loadString(
      'assets/turkce_kelime_listesi.txt',
    );
    validWords =
        wordData
            .split('\n')
            .map((e) => e.trim().toLowerCase()) // Artık küçük harf
            .where((word) => word.isNotEmpty)
            .toSet();
  }

  void _initializeBoard() {
    List<List<int>> k3Positions = [
      [2, 0],
      [12, 0],
      [0, 2],
      [14, 2],
      [0, 12],
      [14, 12],
      [2, 14],
      [12, 14],
    ];
    List<List<int>> k2Positions = [
      [7, 2],
      [11, 3],
      [3, 3],
      [7, 12],
      [2, 7],
      [12, 7],
      [3, 11],
      [11, 11],
    ];
    List<List<int>> h2Positions = [
      [5, 0],
      [6, 1],
      [8, 1],
      [9, 0],
      [5, 5],
      [6, 6],
      [8, 6],
      [9, 5],
      [6, 8],
      [5, 9],
      [8, 8],
      [9, 9],
      [0, 5],
      [0, 9],
      [1, 6],
      [1, 8],
      [14, 5],
      [13, 6],
      [13, 8],
      [14, 9],
      [5, 14],
      [6, 13],
      [8, 13],
      [9, 14],
    ];
    List<List<int>> h3Positions = [
      [1, 1],
      [4, 4],
      [10, 10],
      [13, 13],
      [13, 1],
      [10, 4],
      [4, 10],
      [1, 13],
    ];

    for (var pos in k3Positions) {
      board[pos[0]][pos[1]] = 'K³';
    }
    for (var pos in k2Positions) {
      board[pos[0]][pos[1]] = 'K²';
    }
    for (var pos in h2Positions) {
      board[pos[0]][pos[1]] = 'H²';
    }
    for (var pos in h3Positions) {
      board[pos[0]][pos[1]] = 'H³';
    }
  }

  void _loadOrCreateItems() async {
    DocumentReference gameRef = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId);

    DocumentSnapshot snapshot = await gameRef.get();

    if (!snapshot.exists || snapshot.data() == null) return;

    var data = snapshot.data() as Map<String, dynamic>;

    bool allExist = [
      'mines',
      'mines2',
      'mines3',
      'mines4',
      'mines5',
      'prizes',
      'prizes2',
      'prizes3',
    ].every((key) => data.containsKey(key));

    if (!allExist) {
      if (widget.myId == widget.gameId.split('_')[0]) {
        // Sadece ilk oyuncu verileri oluşturur
        await _createAndSaveItems(gameRef);
      } else {
        // Bekle ve yeniden dene
        Future.delayed(const Duration(seconds: 1), () => _loadOrCreateItems());
      }
      return;
    }

    // Verileri yerleştir
    mines.addAll(
      List<Map<String, int>>.from(
        data['mines'].map((e) => Map<String, int>.from(e)),
      ),
    );
    mines2.addAll(
      List<Map<String, int>>.from(
        data['mines2'].map((e) => Map<String, int>.from(e)),
      ),
    );
    mines3.addAll(
      List<Map<String, int>>.from(
        data['mines3'].map((e) => Map<String, int>.from(e)),
      ),
    );
    mines4.addAll(
      List<Map<String, int>>.from(
        data['mines4'].map((e) => Map<String, int>.from(e)),
      ),
    );
    mines5.addAll(
      List<Map<String, int>>.from(
        data['mines5'].map((e) => Map<String, int>.from(e)),
      ),
    );
    prizes.addAll(
      List<Map<String, int>>.from(
        data['prizes'].map((e) => Map<String, int>.from(e)),
      ),
    );
    prizes2.addAll(
      List<Map<String, int>>.from(
        data['prizes2'].map((e) => Map<String, int>.from(e)),
      ),
    );
    prizes3.addAll(
      List<Map<String, int>>.from(
        data['prizes3'].map((e) => Map<String, int>.from(e)),
      ),
    );

    setState(() {});
  }

  Future<void> _createAndSaveItems(DocumentReference gameRef) async {
    Random random = Random();
    Set<String> usedPositions = {};

    List<Map<String, dynamic>> categories = [
      {'key': 'mines', 'list': mines, 'count': 5},
      {'key': 'mines2', 'list': mines2, 'count': 4},
      {'key': 'mines3', 'list': mines3, 'count': 3},
      {'key': 'mines4', 'list': mines4, 'count': 2},
      {'key': 'mines5', 'list': mines5, 'count': 2},
      {'key': 'prizes', 'list': prizes, 'count': 2},
      {'key': 'prizes2', 'list': prizes2, 'count': 3},
      {'key': 'prizes3', 'list': prizes3, 'count': 2},
    ];

    Map<String, dynamic> newData = {};

    for (var category in categories) {
      List<Map<String, int>> tempList = [];
      while (tempList.length < category['count']) {
        int row = random.nextInt(15);
        int col = random.nextInt(15);
        String key = "$row,$col";

        if (!usedPositions.contains(key) && board[row][col] == '') {
          usedPositions.add(key);
          tempList.add({'row': row, 'col': col});
        }
      }
      newData[category['key']] = tempList;
      (category['list'] as List<Map<String, int>>).addAll(tempList);
    }

    // Letter pool ve currentTurn'u da ekle
    newData['letterPool'] = letterPool;
    newData['currentTurn'] =
        widget.myId; // Oyunu başlatan oyuncu ilk sırayı alır

    await gameRef.update(newData);
    await _assignInitialLettersToPlayers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('myLetters: $myLetters');
    bool isPlayer1 = widget.myId == widget.gameId.split('_')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.player1Name} vs ${widget.player2Name}"),
        backgroundColor: const Color(0xFF0A2A62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPlayerInfo(
                  isPlayer1 ? widget.player1Name : widget.player2Name,
                  isPlayer1 ? _player1Score : _player2Score,
                ),
                _buildPlayerInfo(
                  isPlayer1 ? widget.player2Name : widget.player1Name,
                  isPlayer1 ? _player2Score : _player1Score,
                ),
              ],
            ),
            const SizedBox(height: 8),
            buildTimerDisplay(),
            const SizedBox(height: 20),

            // Oyuncunun harflerini gösteren butonlar
            Column(
              children: [
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children:
                      myLetters.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> letterData = entry.value;
                        String letter = letterData['letter'];
                        int point = letterData['point'];
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedLetter = letter;
                              selectedLetterIndex = index;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedLetterIndex == index
                                    ? Colors.green
                                    : null,
                          ),
                          child: Text('$letter ($point)'),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),

            // Onay Butonu
            ElevatedButton(
              onPressed:
                  isCurrentWordValid && tempPlacedLetters.isNotEmpty
                      ? () async {
                        final gameRef = FirebaseFirestore.instance
                            .collection('games')
                            .doc(widget.gameId);
                        final currentUserId =
                            FirebaseAuth.instance.currentUser!.uid;

                        List<Map<String, dynamic>> wordData =
                            tempPlacedLetters.entries.map((e) {
                              var parts = e.key.split(',');
                              return {
                                'row': int.parse(parts[0]),
                                'col': int.parse(parts[1]),
                                'letter': e.value,
                              };
                            }).toList();

                        String formedWord = _getCurrentWordFromTempLetters();

                        final player1Id = widget.gameId.split('_')[0];
                        final player2Id = widget.gameId.split('_')[1];
                        final nextTurn =
                            currentUserId == player1Id ? player2Id : player1Id;

                        // 📌 Harf puanlarını topla
                        int totalPoints = 0;
                        for (var letterData in wordData) {
                          String letter = letterData['letter'];
                          int point =
                              myLetters.firstWhere(
                                (item) => item['letter'] == letter,
                                orElse: () => {'point': 0},
                              )['point'] ??
                              0;
                          totalPoints += point;
                        }

                        // 📌 Güncel Firestore verilerini çek
                        final snapshot = await gameRef.get();
                        int player1Score = snapshot['player1Score'] ?? 0;
                        int player2Score = snapshot['player2Score'] ?? 0;

                        // 📌 Güncellenmiş skoru sıradaki oyuncuya ekle
                        if (currentUserId == player1Id) {
                          player1Score += totalPoints;
                        } else {
                          player2Score += totalPoints;
                        }

                        // 📌 Yerleştirilen harfleri tahtaya kalıcı olarak yaz
                        for (var item in wordData) {
                          board[item['row']][item['col']] = item['letter'];
                        }

                        // 📌 Kullanılan harfleri düş ve eksik olanları tamamla
                        Set<String> usedLetters =
                            tempPlacedLetters.values.toSet();
                        myLetters.removeWhere(
                          (item) => usedLetters.contains(item['letter']),
                        );

                        int eksik = 7 - myLetters.length;
                        List<Map<String, dynamic>> pool =
                            List<Map<String, dynamic>>.from(
                              snapshot['letterPool'],
                            );
                        final Random random = Random();

                        while (eksik > 0) {
                          int index = random.nextInt(pool.length);
                          if (pool[index]['count'] > 0) {
                            myLetters.add({
                              'letter': pool[index]['letter'],
                              'point': pool[index]['point'],
                            });
                            pool[index]['count']--;
                            eksik--;
                          }
                        }

                        // 📌 Firestore'u güncelle
await gameRef.update({
  'lastMove': {
    'playerId': currentUserId,
    'word': formedWord,
    'letters': wordData,
    'timestamp': FieldValue.serverTimestamp(),
  },
  'placedLetters': FieldValue.arrayUnion(wordData),
  'letterPool': pool,
  'playerLetters': {currentUserId: myLetters},
  'currentTurn': nextTurn,
  'player1Score': player1Score,
  'player2Score': player2Score,
});

onPlayerConfirmedMove(); // 💥 BURAYA EKLE

// Arayüzü güncelle
setState(() {
  tempPlacedLetters.clear();
  isCurrentWordValid = true;
  selectedLetter = null;
  selectedLetterIndex = null;
});

                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrentWordValid ? Colors.green : Colors.grey,
              ),
              child: const Text("Onayla"),
            ),

            // Oyun tahtası
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 15,
                  childAspectRatio: 1.0,
                ),
                itemCount: 225,
                itemBuilder: (context, index) {
                  int row = index ~/ 15;
                  int col = index % 15;

                  String cellText = board[row][col];
                  Color cellColor = _getCellColor(row, col, cellText);

                  return GestureDetector(
                    onTap: () async {
                      if (!await isPlayerTurn(widget.gameId, widget.myId)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Sıra sizde değil!")),
                        );
                        return;
                      }

                      bool isFirstMove = board.every(
                        (row) => row.every(
                          (cell) =>
                              cell == '' ||
                              ['K²', 'K³', 'H²', 'H³'].contains(cell),
                        ),
                      );

                      if (isFirstMove) {
                        // Sadece yeni yerleştirilen harflerden biri 7,7'ye denk geliyorsa yeterlidir
                        bool willPlaceOnCenter =
                            tempPlacedLetters.keys.contains('7,7') ||
                            (row == 7 && col == 7);

                        if (!willPlaceOnCenter) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "İlk hamlede en az bir harf 7,7 konumuna yerleştirilmelidir.",
                              ),
                            ),
                          );
                          return;
                        }
                      } else {
                        // Sonraki hamlelerde yerleştirilen harfin komşusu olmalı
                        bool hasNeighbor = false;
                        for (var d in [
                          [-1, 0],
                          [1, 0],
                          [0, -1],
                          [0, 1],
                          [-1, -1],
                          [-1, 1],
                          [1, -1],
                          [1, 1],
                        ]) {
                          int nr = row + d[0];
                          int nc = col + d[1];
                          if (nr >= 0 && nr < 15 && nc >= 0 && nc < 15) {
                            String val = board[nr][nc];
                            if (val != '' &&
                                !['K²', 'K³', 'H²', 'H³'].contains(val)) {
                              hasNeighbor = true;
                              break;
                            }
                          }
                        }
                        if (!hasNeighbor) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Yeni kelime önceki harflerle komşu olmalıdır.",
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      if (selectedLetter != null &&
                          !_isLetterCell(row, col) &&
                          !tempPlacedLetters.containsKey('$row,$col')) {
                        setState(() {
                          board[row][col] = selectedLetter!;
                          tempPlacedLetters['$row,$col'] = selectedLetter!;
                          _validateCurrentWord();
                          print(
                            "Güncel kelime: ${_getCurrentWordFromTempLetters()}",
                          );
                          selectedLetter = null;
                          selectedLetterIndex = null;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      color: cellColor,
                      child: Center(
                        child: Text(
                          cellText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
         Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _gameEnded
                    ? null
                    : () async {
                        final myId = widget.myId;
                        final player1Id = widget.gameId.split('_')[0];
                        final player2Id = widget.gameId.split('_')[1];
                        final winnerId = myId == player1Id ? player2Id : player1Id;
                        final winnerName = myId == player1Id
                            ? widget.player2Name
                            : widget.player1Name;

                        final gameRef = FirebaseFirestore.instance
                            .collection('games')
                            .doc(widget.gameId);
                        final userRef = FirebaseFirestore.instance.collection('kullanicilar');

                        await gameRef.update({
                          'gameOver': true,
                          'winner': winnerId,
                          'winnerName': winnerName,
                          'status': 'finished',
                        });

                        await userRef.doc(winnerId).update({
                          'kazanim_sayisi': FieldValue.increment(1),
                        });
                        await userRef.doc(myId).update({
                          'kayip_sayisi': FieldValue.increment(1),
                        });

                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => AlertDialog(
                            title: const Text("Teslim Oldun"),
                            content: Text(
                              "Oyun sona erdi.\n\nKazanan: $winnerName\nKaybeden: Siz",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => DashboardPage()),
                                  );
                                },
                                child: const Text("Tamam"),
                              ),
                            ],
                          ),
                        );

                        setState(() {
                          _gameEnded = true;
                        });
                      },
                icon: const Icon(Icons.flag),
                label: const Text("Teslim Ol"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: () async {
  final gameRef = FirebaseFirestore.instance.collection('games').doc(widget.gameId);
  final gameSnap = await gameRef.get();
  if (!gameSnap.exists) return;

  final data = gameSnap.data()!;
  final myId = widget.myId;
  final player1Id = widget.gameId.split('_')[0];
  final player2Id = widget.gameId.split('_')[1];
  final opponentId = myId == player1Id ? player2Id : player1Id;

  final lastAction = data['lastAction'];
  final lastPassedPlayer = data['lastPassedPlayer'];

  // Eğer önceki pas da karşı oyuncudansa oyun biter
  if (lastAction == 'pass' && lastPassedPlayer == opponentId) {
    final player1Score = data['player1Score'] ?? 0;
    final player2Score = data['player2Score'] ?? 0;

    String winnerId = player1Score >= player2Score ? player1Id : player2Id;
    String winnerName = winnerId == player1Id ? widget.player1Name : widget.player2Name;
    String loserId = winnerId == player1Id ? player2Id : player1Id;
    String loserName = loserId == player1Id ? widget.player1Name : widget.player2Name;

    await gameRef.update({
      'gameOver': true,
      'winner': winnerId,
      'winnerName': winnerName,
      'status': 'finished',
    });

    await FirebaseFirestore.instance.collection('kullanicilar').doc(winnerId).update({
      'kazanim_sayisi': FieldValue.increment(1),
    });
    await FirebaseFirestore.instance.collection('kullanicilar').doc(loserId).update({
      'kayip_sayisi': FieldValue.increment(1),
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Oyun Bitti"),
        content: Text(
          "Her iki oyuncu da pas geçtiği için oyun sona erdi.\n\n"
          "Kazanan: $winnerName (${player1Score >= player2Score ? player1Score : player2Score} puan)\n"
          "Kaybeden: $loserName",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => DashboardPage()),
              );
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );

    setState(() {
      _gameEnded = true;
    });
  } else {
    // İlk pas ya da araya hamle yapılmış
    await gameRef.update({
      'lastAction': 'pass',
      'lastPassedPlayer': myId,
      'currentTurn': opponentId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pas geçildi, sıra rakibe geçti.")),
    );
  }
},

                icon: const Icon(Icons.skip_next),
                label: const Text("Pas"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  bool _isLetterCell(int row, int col) {
    String val = board[row][col];

    return val != '' && !['H²', 'H³', 'K²', 'K³'].contains(val);
  }

  Widget _buildPlayerInfo(String name, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text("Score: $score", style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Color _getCellColor(int row, int col, String cellText) {
    if (_positionExists(mines, row, col)) return Colors.red[200]!;
    if (_positionExists(mines2, row, col)) return Colors.blue[200]!;
    if (_positionExists(mines3, row, col)) return Colors.green[200]!;
    if (_positionExists(mines4, row, col)) return Colors.yellow[200]!;
    if (_positionExists(mines5, row, col)) return Colors.orange[200]!;

    if (_positionExists(prizes, row, col)) return Colors.purple[200]!;
    if (_positionExists(prizes2, row, col)) return Colors.pink[200]!;
    if (_positionExists(prizes3, row, col)) return Colors.deepPurple[100]!;

    if (cellText == 'K³') return Colors.brown[200]!;
    if (cellText == 'K²') return Colors.green[100]!;
    if (cellText == 'H²') return Colors.teal[200]!;
    if (cellText == 'H³') return Colors.purple[100]!;

    if (tempPlacedLetters.containsKey('$row,$col')) {
      return isCurrentWordValid ? Colors.greenAccent : Colors.redAccent;
    }

    return Colors.white;
  }

  bool _positionExists(List<Map<String, int>> list, int row, int col) {
    return list.any((pos) => pos['row'] == row && pos['col'] == col);
  }

  Future<void> _assignInitialLettersToPlayers() async {
    final gameRef = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId);
    final gameSnap = await gameRef.get();

    if (!gameSnap.exists) return;

    final data = gameSnap.data()!;
    final player1Id = data['player1'];
    final player2Id = data['player2'];

    List<Map<String, dynamic>> pool = List<Map<String, dynamic>>.from(
      data['letterPool'],
    );
    final Random random = Random();

    List<Map<String, dynamic>> drawLetters(List<Map<String, dynamic>> pool) {
      List<Map<String, dynamic>> result = [];
      int totalTries = 0;

      while (result.length < 7 && totalTries < 100) {
        totalTries++;
        int index = random.nextInt(pool.length);
        var item = pool[index];
        if (item['count'] > 0) {
          result.add({'letter': item['letter'], 'point': item['point']});
          item['count'] -= 1;
        }
      }
      return result;
    }

    List<Map<String, dynamic>> letters1 = drawLetters(pool);
    List<Map<String, dynamic>> letters2 = drawLetters(pool);

    await gameRef.update({
      'letterPool': pool,
      'playerLetters': {player1Id: letters1, player2Id: letters2},
    });

    print("Harfler atandı ve Firestore'a kaydedildi.");
  }

  Future<void> _loadMyLetters() async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final playerLettersData = data['playerLetters'];
    final myId = widget.myId;

    if (playerLettersData != null && playerLettersData[myId] != null) {
      setState(() {
        myLetters = List<Map<String, dynamic>>.from(playerLettersData[myId]);
        print('Initial Load => myLetters: $myLetters');
      });
    }
  }

  void validatePlacedWords() {
    if (tempPlacedLetters.isEmpty) return;

    bool allValid = true;

    for (var key in tempPlacedLetters.keys) {
      var parts = key.split(',');
      int row = int.parse(parts[0]);
      int col = int.parse(parts[1]);

      String horizontal = '';
      int c = col;
      while (c >= 0 && board[row][c] != '') c--;
      c++;
      while (c < 15 && board[row][c] != '') {
        horizontal += board[row][c];
        c++;
      }

      String vertical = '';
      int r = row;
      while (r >= 0 && board[r][col] != '') r--;
      r++;
      while (r < 15 && board[r][col] != '') {
        vertical += board[r][col];
        r++;
      }

      if ((horizontal.length > 1 && !validWords.contains(horizontal)) ||
          (vertical.length > 1 && !validWords.contains(vertical))) {
        allValid = false;
        break;
      }
    }

    setState(() {
      isCurrentWordValid = allValid;
    });
  }

  String _getCurrentWordFromTempLetters() {
    if (tempPlacedLetters.isEmpty) return '';

    List<List<int>> coords =
        tempPlacedLetters.keys.map((pos) {
          var parts = pos.split(',');
          return [int.parse(parts[0]), int.parse(parts[1])];
        }).toList();

    coords.sort((a, b) => a[1].compareTo(b[1]));
    int row = coords[0][0];

    if (!coords.every((c) => c[0] == row)) return ''; // yalnızca yatay için

    // soldan geri git
    int startCol = coords[0][1];
    while (startCol > 0 &&
        board[row][startCol - 1] != '' &&
        !_isSpecialCell(board[row][startCol - 1])) {
      startCol--;
    }

    // sağa doğru kelimeyi topla
    String word = '';
    int col = startCol;
    while (col < 15 &&
        board[row][col] != '' &&
        !_isSpecialCell(board[row][col])) {
      word += board[row][col];
      col++;
    }

    print("Güncel kelime: $word");
    return word;
  }

  bool _isSpecialCell(String value) {
    return ['K²', 'K³', 'H²', 'H³'].contains(value);
  }

  void _validateCurrentWord() {
    if (tempPlacedLetters.isEmpty) return;

    // Koordinatları al
    List<List<int>> coords =
        tempPlacedLetters.keys.map((pos) {
          var parts = pos.split(',');
          return [int.parse(parts[0]), int.parse(parts[1])];
        }).toList();

    // Koordinatları sırala (önce satır, sonra sütun)
    coords.sort((a, b) {
      int rowComp = a[0].compareTo(b[0]);
      return rowComp != 0 ? rowComp : a[1].compareTo(b[1]);
    });

    // İlk hamle kontrolü
    bool isFirstMove = board.every(
      (row) => row.every((cell) => cell == '' || _isSpecialCell(cell)),
    );
    if (isFirstMove) {
      bool containsCenter = coords.any(
        (coord) => coord[0] == 7 && coord[1] == 7,
      );
      if (!containsCenter) {
        setState(() => isCurrentWordValid = false);
        return;
      }
    } else {
      // Komşu kontrolü (önceden yerleştirilmiş harflerle temas)
      bool hasNeighbor = coords.any((coord) {
        int r = coord[0];
        int c = coord[1];
        return [
          if (r > 0 &&
              board[r - 1][c] != '' &&
              !_isSpecialCell(board[r - 1][c]))
            true,
          if (r < 14 &&
              board[r + 1][c] != '' &&
              !_isSpecialCell(board[r + 1][c]))
            true,
          if (c > 0 &&
              board[r][c - 1] != '' &&
              !_isSpecialCell(board[r][c - 1]))
            true,
          if (c < 14 &&
              board[r][c + 1] != '' &&
              !_isSpecialCell(board[r][c + 1]))
            true,
        ].contains(true);
      });

      if (!hasNeighbor) {
        setState(() => isCurrentWordValid = false);
        return;
      }
    }

    List<String> collectedWords = [];

    // ➤ Yatay kelime
    if (coords.every((c) => c[0] == coords[0][0])) {
      int row = coords[0][0];
      int startCol = coords.map((c) => c[1]).reduce(min);
      while (startCol > 0 && board[row][startCol - 1] != '') startCol--;

      String word = '';
      int col = startCol;
      while (col < 15 && board[row][col] != '') {
        final cell = board[row][col];
        if (_isSpecialCell(cell)) {
          if (tempPlacedLetters.containsKey('$row,$col') ||
              RegExp(r'^[A-ZÇŞĞÜİÖ]{1}\$').hasMatch(cell)) {
            word += cell;
          } else {
            break;
          }
        } else {
          word += cell;
        }
        col++;
      }

      if (word.length > 1) collectedWords.add(word.toLowerCase());
    }

    // ➤ Dikey kelime
    if (coords.every((c) => c[1] == coords[0][1])) {
      int col = coords[0][1];
      int startRow = coords.map((c) => c[0]).reduce(min);
      while (startRow > 0 && board[startRow - 1][col] != '') startRow--;

      String word = '';
      int row = startRow;
      while (row < 15 && board[row][col] != '') {
        final cell = board[row][col];
        if (_isSpecialCell(cell)) {
          if (tempPlacedLetters.containsKey('$row,$col') ||
              RegExp(r'^[A-ZÇŞĞÜİÖ]{1}\$').hasMatch(cell)) {
            word += cell;
          } else {
            break;
          }
        } else {
          word += cell;
        }
        row++;
      }

      if (word.length > 1) collectedWords.add(word.toLowerCase());
    }

    // ➤ Çapraz kelimeleri kontrol et (sol üst → sağ alt)
    _checkDiagonalWords(coords, collectedWords);

    print("📌 Toplanan kelimeler: $collectedWords");

    // ➤ Doğruluk kontrolü
    bool allValid =
        collectedWords.isNotEmpty &&
        collectedWords.every((word) => validWords.contains(word));
    setState(() => isCurrentWordValid = allValid);
  }

  void _checkDiagonalWords(
    List<List<int>> coords,
    List<String> collectedWords,
  ) {
    for (var coord in coords) {
      int row = coord[0];
      int col = coord[1];

      // Başlangıç noktasına kadar geri git (sol üst)
      int r = row;
      int c = col;
      while (r > 0 && c > 0 && board[r - 1][c - 1] != '') {
        r--;
        c--;
      }

      String word = '';
      while (r < 15 && c < 15) {
        final cell = board[r][c];
        if (cell == '') break;

        if (_isSpecialCell(cell)) {
          if (tempPlacedLetters.containsKey('$r,$c') ||
              RegExp(r'^[A-ZÇŞĞÜİÖ]{1}\$').hasMatch(cell)) {
            word += cell;
          } else {
            break;
          }
        } else {
          word += cell;
        }

        r++;
        c++;
      }

      if (word.length > 1 && !collectedWords.contains(word.toLowerCase())) {
        collectedWords.add(word.toLowerCase());
      }
    }
  }

  Future<bool> isPlayerTurn(String gameId, String myId) async {
    final gameDoc =
        await FirebaseFirestore.instance.collection('games').doc(gameId).get();
    if (gameDoc.exists) {
      final currentTurn = gameDoc.data()!['currentTurn'];
      return currentTurn == myId;
    }
    return false;
  }
}
