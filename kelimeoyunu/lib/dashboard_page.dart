import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_duration_page.dart';
import 'completed_games_page.dart';
import 'active_games_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = "Yükleniyor...";
  String email = "";
  double successPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(user.uid)
              .get();

      final data = doc.data();
      final kazan = (data?['kazanim_sayisi'] ?? 0) as int;
      final kayip = (data?['kayip_sayisi'] ?? 0) as int;
      final toplam = kazan + kayip;

      setState(() {
        username = data?['kullaniciAdi'] ?? 'Kullanıcı Adı';
        email = user.email ?? 'E-posta bulunamadı';
        successPercentage = toplam > 0 ? (kazan / toplam) * 100 : 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        backgroundColor: const Color(0xFF0A2A62),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Kullanıcı Bilgileri Kartı
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF0A2A62),
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Başarı Yüzdesi Progress Bar
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Başarı Yüzdesi",
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: successPercentage / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text("%${successPercentage.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Butonlar
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectDurationPage(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Yeni Oyun"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2A62),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ActiveGamesPage(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          username: username,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.gamepad),
              label: const Text("Aktif Oyunlar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3273DC),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CompletedGamesPage(
                          userId: FirebaseAuth.instance.currentUser!.uid,
                          username: username,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text("Biten Oyunlar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
