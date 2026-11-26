import 'package:flutter/material.dart';
import 'package:gwent_gta6/screens/home_menu_screen.dart';

void main() {
  runApp(const GwentGta6App());
}

class GwentGta6App extends StatelessWidget {
  const GwentGta6App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rockstar Gwent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeMenuScreen(),
    );
  }
}
