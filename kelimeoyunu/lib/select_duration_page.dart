import 'package:flutter/material.dart';
import 'waiting_page.dart';

class SelectDurationPage extends StatefulWidget {
  const SelectDurationPage({super.key});

  @override
  State<SelectDurationPage> createState() => _SelectDurationPageState();
}

class _SelectDurationPageState extends State<SelectDurationPage>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _offsetAnimations;

  final List<String> durations = ["2dk", "5dk", "12saat", "24saat"];
  final List<bool> isQuickGame = [true, true, false, false];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(durations.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _offsetAnimations =
        _controllers.map((controller) {
          return Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
        }).toList();

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (var controller in _controllers) {
      await Future.delayed(const Duration(milliseconds: 200));
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Süre Seç"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Hızlı Oyun",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: buildAnimatedButton(0)),
                const SizedBox(width: 12),
                Expanded(child: buildAnimatedButton(1)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Genişletilmiş Oyun",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: buildAnimatedButton(2)),
                const SizedBox(width: 12),
                Expanded(child: buildAnimatedButton(3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnimatedButton(int index) {
  return SlideTransition(
    position: _offsetAnimations[index],
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor:
            isQuickGame[index] ? Colors.blueAccent : Colors.deepPurpleAccent,
        shadowColor: const Color.fromRGBO(0, 0, 0, 0.2),
        elevation: 6,
        textStyle: const TextStyle(fontSize: 18),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingPage(
              selectedDuration: durations[index], 
            ),
          ),
        );
      },
      icon: Icon(
        isQuickGame[index] ? Icons.flash_on : Icons.access_time,
        size: 24,
      ),
      label: Text(durations[index]), 
    ),
  );
}
}

