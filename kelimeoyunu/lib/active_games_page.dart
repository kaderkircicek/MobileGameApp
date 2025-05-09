import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActiveGamesPage extends StatelessWidget {
  final String userId;
  final String username;

  const ActiveGamesPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final gamesRef = FirebaseFirestore.instance.collection('games');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aktif Oyunlar"),
        backgroundColor: const Color(0xFF3273DC),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: gamesRef.where('status', isEqualTo: 'started').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final allGames = snapshot.data?.docs ?? [];

          final userGames = allGames.where((game) {
            final data = game.data() as Map<String, dynamic>;
            return data['player1'] == userId || data['player2'] == userId;
          }).toList();

          if (userGames.isEmpty) {
            return const Center(child: Text("Aktif oyun bulunamadı."));
          }

          return ListView.builder(
            itemCount: userGames.length,
            itemBuilder: (context, index) {
              final data = userGames[index].data() as Map<String, dynamic>;

              final player1Id = data['player1'];
              final player2Id = data['player2'];
              final player1Score = data['player1Score'] ?? 0;
              final player2Score = data['player2Score'] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('kullanicilar')
                    .doc(player1Id)
                    .get(),
                builder: (context, player1Snapshot) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('kullanicilar')
                        .doc(player2Id)
                        .get(),
                    builder: (context, player2Snapshot) {
                      if (!player1Snapshot.hasData || !player2Snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final player1Data = player1Snapshot.data!.data() as Map<String, dynamic>;
                      final player2Data = player2Snapshot.data!.data() as Map<String, dynamic>;

                      final player1Name = player1Data['kullaniciAdi'] ?? 'Oyuncu 1';
                      final player2Name = player2Data['kullaniciAdi'] ?? 'Oyuncu 2';

                      return Card(
                        color: Colors.blue[50],
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          leading: const Icon(Icons.play_circle_fill, color: Colors.blue, size: 30),
                          title: Text(
                            '$player1Name ($player1Score) vs $player2Name ($player2Score)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Durum: Oyun Devam Ediyor'),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
