import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'game_page.dart';

class WaitingPage extends StatefulWidget {
  final String selectedDuration;

  const WaitingPage({super.key, required this.selectedDuration});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String currentUserId;
  bool matched = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    _addUserToWaitingList();
    _startMatchingListener();
  }

  // Kullanıcıyı bekleyen oyuncular listesine ekler
  Future<void> _addUserToWaitingList() async {
    await _firestore.collection('waiting_players').doc(currentUserId).set({
      'uid': currentUserId,
      'duration': widget.selectedDuration,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Eşleşme için dinleyici başlatılır
  void _startMatchingListener() {
    _subscription = _firestore
        .collection('waiting_players')
        .where('duration', isEqualTo: widget.selectedDuration)
        .snapshots()
        .listen((snapshot) async {
          if (!matched) {
            final otherPlayers =
                snapshot.docs.where((doc) => doc.id != currentUserId).toList();

            if (otherPlayers.isNotEmpty) {
              matched = true; // Eşleşmeyi kilitle

              final matchedPlayer = otherPlayers.first;

              try {
                // Oyuncu ID'lerini küçükten büyüğe sırala
                List<String> sortedPlayers = [
                  currentUserId,
                  matchedPlayer['uid'],
                ];
                sortedPlayers.sort();

                String gameId =
                    '${sortedPlayers[0]}_${sortedPlayers[1]}_${widget.selectedDuration}';

                final gameRef = _firestore.collection('games').doc(gameId);

                final gameSnapshot = await gameRef.get();

                if (!gameSnapshot.exists) {
                  // Eğer oyun yoksa oluştur
                  await gameRef.set({
                    'player1': sortedPlayers[0],
                    'player2': sortedPlayers[1],
                    'duration': widget.selectedDuration,
                    'start_time': FieldValue.serverTimestamp(),
                    'current_turn': sortedPlayers[0],
                    'player1Score': 0,
                    'player2Score': 0,
                    'status': 'started',
                  });
                }

                // Oyun başladığında her iki oyuncuyu da "waiting_players" listesinden sil
                await Future.wait([
                  _firestore
                      .collection('waiting_players')
                      .doc(currentUserId)
                      .delete(),
                  _firestore
                      .collection('waiting_players')
                      .doc(matchedPlayer.id)
                      .delete(),
                ]);

                // Oyuncular eşleşti ve oyun başladı
                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => GamePage(
                          gameId: gameRef.id,
                          myId: currentUserId,
                          selectedDuration: widget.selectedDuration,
                        ),
                  ),
                );
              } catch (e) {
                matched = false; // Hata durumunda eşleşmeyi sıfırla
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bir hata oluştu: $e')),
                  );
                }
              }
            }
          }
        });
  }

  // Bekleme listesinden çıkma işlemi
  Future<void> _cancelWaiting() async {
    await _firestore.collection('waiting_players').doc(currentUserId).delete();
    await _subscription?.cancel();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0A2A62)),
            const SizedBox(height: 24),
            const Text(
              "Oyuncu eşleşmesi bekleniyor...",
              style: TextStyle(fontSize: 18, color: Color(0xFF0A2A62)),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _cancelWaiting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Vazgeç",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
