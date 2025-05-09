import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompletedGamesPage extends StatelessWidget {
  final String userId;
  final String username;

  const CompletedGamesPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final gamesRef = FirebaseFirestore.instance.collection('games');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Biten Oyunlar"),
        backgroundColor: const Color(0xFF0A2A62),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: gamesRef.where('status', isEqualTo: 'finished').get(),
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
            return const Center(child: Text("Henüz biten oyun yok."));
          }

          return ListView.builder(
            itemCount: userGames.length,
            itemBuilder: (context, index) {
              final data = userGames[index].data() as Map<String, dynamic>;

              final player1Id = data['player1'];
              final player2Id = data['player2'];
              final player1Score = data['player1Score'] ?? 0;
              final player2Score = data['player2Score'] ?? 0;
              final winnerId = data['winner'];
              final winnerNameFromData = data['winnerName'];

              // Kartın rengini belirle
              Color cardColor;
              String statusEmoji;
              String displayWinner;

              if (winnerId == null) {
                cardColor = Colors.grey[300]!;
                statusEmoji = '🤝';
                displayWinner = 'Berabere';
              } else if (winnerId == userId) {
                cardColor = Colors.green[100]!;
                statusEmoji = '🎉';
                displayWinner = winnerNameFromData ?? 'Sen';
              } else {
                cardColor = Colors.red[100]!;
                statusEmoji = '😞';
                displayWinner = winnerNameFromData ?? 'Rakip';
              }

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

                      final player1Data =
                          player1Snapshot.data!.data() as Map<String, dynamic>;
                      final player2Data =
                          player2Snapshot.data!.data() as Map<String, dynamic>;

                      final player1Name = player1Data['kullaniciAdi'] ?? 'Oyuncu 1';
                      final player2Name = player2Data['kullaniciAdi'] ?? 'Oyuncu 2';

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: Text(
                            statusEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            '$player1Name ($player1Score) vs $player2Name ($player2Score)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Kazanan: $displayWinner'),
                          trailing: const Icon(Icons.emoji_events, color: Colors.amber),
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
