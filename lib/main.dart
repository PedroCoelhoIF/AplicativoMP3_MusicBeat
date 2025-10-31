import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appmp3_musicbeat/viewmodels/music_viewmodel.dart';
import 'package:appmp3_musicbeat/views/music_list_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => MusicViewModel()..loadPlaylist(),
      child: const MusicBeatApp(),
    ),
  );
}

class MusicBeatApp extends StatelessWidget {
  const MusicBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Beat',
      debugShowCheckedModeBanner: false,
      

      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFBB86FC),
        scaffoldBackgroundColor: const Color(0xFF121212), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1D1D1D),
          elevation: 0,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: Color(0xFFBB86FC)),
        splashFactory: InkRipple.splashFactory,
      ),
      
      home: const MusicListView(),
    );
  }
}