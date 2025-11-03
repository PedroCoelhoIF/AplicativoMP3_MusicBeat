import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'viewmodels/music_viewmodel.dart';
import 'views/music_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late MusicViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detecta quando o app é fechado
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App está sendo fechado - limpa player compartilhado
      MusicViewModel.disposeSharedPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        _viewModel = MusicViewModel();
        _viewModel.initialize();
        return _viewModel;
      },
      child: MaterialApp(
        title: 'Music Beat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const PermissionWrapper(),
      ),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({Key? key}) : super(key: key);

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _permissionsChecked = false;
  String _permissionStatus = 'Verificando permissões...';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Aguarda para garantir que a Activity está pronta
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;

    try {
      // 1. Notificações (necessária para controles de mídia)
      setState(() => _permissionStatus = 'Solicitando permissão de notificações...');
      await Permission.notification.request();

      // 2. Armazenamento (para salvar músicas)
      if (await Permission.storage.isDenied) {
        setState(() => _permissionStatus = 'Solicitando permissão de armazenamento...');
        await Permission.storage.request();
      }

      // 3. Áudio (Android 13+)
      if (await Permission.audio.isDenied) {
        setState(() => _permissionStatus = 'Solicitando permissão de áudio...');
        await Permission.audio.request();
      }

      // 4. Localização (para Easter Egg) 
      setState(() => _permissionStatus = 'Solicitando permissão de localização...');
      PermissionStatus locationStatus = await Permission.location.request();
      
      if (locationStatus.isDenied) {
        
        debugPrint('⚠️ Localização negada - Easter Egg não funcionará');
      }

    } catch (e) {
      debugPrint('⚠️ Erro ao solicitar permissões: $e');
    }

    if (mounted) {
      setState(() {
        _permissionsChecked = true;
        _permissionStatus = 'Pronto!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsChecked) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.shade900,
                Colors.blue.shade900,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Ícone
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Music Beat',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _permissionStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const MusicListView();
  }
}