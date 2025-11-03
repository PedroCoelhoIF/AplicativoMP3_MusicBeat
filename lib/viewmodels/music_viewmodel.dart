import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/location_service.dart';

class MusicViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DownloadService _downloadService = DownloadService();
  final LocationService _locationService = LocationService();
  
  //  Player único compartilhado
  static AudioPlayer? _sharedPlayer;
  AudioPlayer get player {
    _sharedPlayer ??= AudioPlayer();
    return _sharedPlayer!;
  }
  
  Timer? _locationTimer;
  Timer? _bufferMonitorTimer; // Timer para monitorar buffer
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _bufferPositionSubscription; // Monitora buffer do player

  List<Song> _playlist = [];
  Map<String, SongState> _songStates = {};
  String? _currentPlayingSongId;
  bool _isLoading = false;
  String? _error;
  bool _isShuffleEnabled = false;
  bool _isRepeatOneEnabled = false;
  bool _isRepeatAllEnabled = false;
  bool _easterEggUnlocked = false;
  Song? _easterEggSong;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _bufferedPosition = Duration.zero; // Posição bufferizada

  // Getters
  List<Song> get playlist => _playlist;
  Map<String, SongState> get songStates => _songStates;
  String? get currentPlayingSongId => _currentPlayingSongId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatOneEnabled => _isRepeatOneEnabled;
  bool get isRepeatAllEnabled => _isRepeatAllEnabled;
  bool get easterEggUnlocked => _easterEggUnlocked;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  Duration get bufferedPosition => _bufferedPosition;

  SongState? getSongState(String songId) => _songStates[songId];

  Future<void> initialize() async {
    if (kDebugMode) print('🎵 Inicializando Music Beat com Streaming Progressivo...');
    
    _setupPlayerListeners();
    await loadPlaylist();
    startLocationMonitoring();
  }

  void _setupPlayerListeners() {
    // Listener de estado
    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (_currentPlayingSongId != null) {
        PlaybackStatus status;
        
        switch (state.processingState) {
          case ProcessingState.idle:
            status = PlaybackStatus.idle;
            break;
          case ProcessingState.loading:
          case ProcessingState.buffering:
            status = PlaybackStatus.buffering;
            break;
          case ProcessingState.ready:
            status = state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
            break;
          case ProcessingState.completed:
            status = PlaybackStatus.idle;
            _onSongCompleted();
            break;
        }
        
        _updateSongState(_currentPlayingSongId!, playbackStatus: status);
      }
    });

    // Listener de posição
    _positionSubscription = player.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listener de duração
    _durationSubscription = player.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // Listener de posição bufferizada
    _bufferPositionSubscription = player.bufferedPositionStream.listen((buffered) {
      _bufferedPosition = buffered;
      
      // Calcula percentual de buffer
      if (_totalDuration.inMilliseconds > 0) {
        final bufferPercent = buffered.inMilliseconds / _totalDuration.inMilliseconds;
        
        if (_currentPlayingSongId != null) {
          _updateSongState(
            _currentPlayingSongId!,
            bufferProgress: bufferPercent,
            isBufferSufficient: bufferPercent > 0.05,
          );
        }
      }
    });
  }

  void startLocationMonitoring() {
    _checkLocation();
    _locationTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _checkLocation();
    });
  }

  Future<void> _checkLocation() async {
    try {
      bool isNear = await _locationService.isNearCampus();
      
      if (isNear && !_easterEggUnlocked) {
        _addEasterEggSong();
      } else if (!isNear && _easterEggUnlocked) {
        _removeEasterEggSong();
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao verificar localização: $e');
    }
  }

  void _addEasterEggSong() {
    if (_easterEggUnlocked) return;

    _easterEggSong = Song(
      title: "🎉 Easter Egg - Os Bilias",
      author: "Os Bilias",
      url: "https://www.rafaelamorim.com.br/mobile2/musicas/osbilias-nome-da-faixa-faixa-5.mp3",
      duration: "03:14",
    );

    _playlist.insert(0, _easterEggSong!);
    _songStates[_easterEggSong!.id] = SongState(
      song: _easterEggSong!,
      downloadStatus: DownloadStatus.idle,
    );

    _easterEggUnlocked = true;
    notifyListeners();
    
    if (kDebugMode) print('🎉 Easter Egg desbloqueado!');
  }

  void _removeEasterEggSong() {
    if (!_easterEggUnlocked || _easterEggSong == null) return;

    if (_currentPlayingSongId == _easterEggSong!.id) {
      stopSong(_easterEggSong!.id);
    }

    _playlist.removeWhere((song) => song.id == _easterEggSong!.id);
    _songStates.remove(_easterEggSong!.id);
    _easterEggUnlocked = false;
    _easterEggSong = null;
    notifyListeners();
  }

  Future<void> loadPlaylist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playlist = await _apiService.fetchPlaylist();
      _checkLocation();

      for (var song in _playlist) {
        if (_songStates.containsKey(song.id)) continue;

        final localPath = await _downloadService.getLocalFilePath(song);
        _songStates[song.id] = SongState(
          song: song,
          downloadStatus: localPath != null 
              ? DownloadStatus.completed 
              : DownloadStatus.idle,
          localPath: localPath,
          isBufferSufficient: localPath != null,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // STREAMING PROGRESSIVO COM GERENCIAMENTO DE BUFFER
  Future<void> playSong(String songId) async {
    final state = _songStates[songId];
    if (state == null) return;

    try {
      // Para música anterior
      if (_currentPlayingSongId != null && _currentPlayingSongId != songId) {
        await player.stop();
        _stopBufferMonitoring();
        _updateSongState(_currentPlayingSongId!, playbackStatus: PlaybackStatus.stopped);
      }

      _currentPlayingSongId = songId;

      if (state.localPath != null) {
        // ✅ Arquivo já baixado - reproduz imediatamente
        if (kDebugMode) print('📂 Reproduzindo arquivo local: ${state.song.title}');
        await player.setFilePath(state.localPath!);
        await player.play();
        _updateSongState(songId, playbackStatus: PlaybackStatus.playing);
        
      } else {
        // 🌊 STREAMING PROGRESSIVO
        if (kDebugMode) print('🌊 Iniciando streaming progressivo: ${state.song.title}');
        
        _updateSongState(
          songId,
          downloadStatus: DownloadStatus.buffering,
          playbackStatus: PlaybackStatus.buffering,
        );
        
        await _startProgressiveStreaming(state.song);
      }

    } catch (e) {
      if (kDebugMode) print('❌ Erro ao reproduzir: $e');
      _updateSongState(
        songId,
        playbackStatus: PlaybackStatus.error,
        errorMessage: 'Erro ao reproduzir',
      );
    }
  }

  // Inicia streaming progressivo com gerenciamento de buffer
  Future<void> _startProgressiveStreaming(Song song) async {
    bool hasStartedPlaying = false;
    
    _downloadService.downloadFileWithBuffer(
      song,
      // Callback de progresso do download
      (downloadProgress) {
        _updateSongState(
          song.id,
          downloadProgress: downloadProgress,
        );
      },
      // Callback de atualização do buffer
      (bufferLevel, isSufficient) {
        _updateSongState(
          song.id,
          bufferProgress: bufferLevel,
          isBufferSufficient: isSufficient,
        );
      },
      // Callback quando buffer inicial está pronto (15%)
      (filePath) async {
        if (!hasStartedPlaying && _currentPlayingSongId == song.id) {
          hasStartedPlaying = true;
          
          if (kDebugMode) print('🎬 Buffer inicial pronto - Iniciando reprodução');
          
          try {
            // Carrega e reproduz o arquivo parcialmente baixado
            await player.setFilePath(filePath);
            await player.play();
            
            _updateSongState(
              song.id,
              playbackStatus: PlaybackStatus.playing,
              downloadStatus: DownloadStatus.downloading,
              localPath: filePath,
            );
            
            // Inicia monitoramento de buffer durante reprodução
            _startBufferMonitoring(song);
            
          } catch (e) {
            if (kDebugMode) print('❌ Erro ao iniciar reprodução: $e');
            _updateSongState(
              song.id,
              playbackStatus: PlaybackStatus.error,
              errorMessage: 'Erro ao reproduzir',
            );
          }
        }
      },
      // Callback quando download completa
      (filePath) {
        if (kDebugMode) print('✅ Download completo: ${song.title}');
        _updateSongState(
          song.id,
          downloadStatus: DownloadStatus.completed,
          downloadProgress: 1.0,
          localPath: filePath,
          isBufferSufficient: true,
        );
        _stopBufferMonitoring();
      },
      // Callback de erro
      (errorMsg) {
        if (kDebugMode) print('❌ Erro no download: $errorMsg');
        _updateSongState(
          song.id,
          downloadStatus: DownloadStatus.error,
          playbackStatus: PlaybackStatus.error,
          errorMessage: errorMsg,
        );
        _stopBufferMonitoring();
      },
    );
  }

  // Monitora buffer durante reprodução
  void _startBufferMonitoring(Song song) {
    _stopBufferMonitoring();
    
    _bufferMonitorTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_currentPlayingSongId != song.id) {
        timer.cancel();
        return;
      }

      final state = _songStates[song.id];
      if (state == null || state.downloadStatus == DownloadStatus.completed) {
        timer.cancel();
        return;
      }

      // Verifica se há buffer suficiente
      final hasBuffer = await _downloadService.checkBufferLevel(
        song,
        _currentPosition.inSeconds.toDouble(),
        _totalDuration.inSeconds.toDouble(),
      );

      if (!hasBuffer && player.playing) {
        // Buffer esgotado - pausa automaticamente
        if (kDebugMode) print('⏸️ Buffer esgotado - Pausando automaticamente');
        await player.pause();
        _updateSongState(
          song.id,
          playbackStatus: PlaybackStatus.waitingForBuffer,
        );
      } else if (hasBuffer && state.playbackStatus == PlaybackStatus.waitingForBuffer) {
        // Buffer reabastecido - retoma reprodução
        if (kDebugMode) print('▶️ Buffer reabastecido - Retomando reprodução');
        await player.play();
        _updateSongState(
          song.id,
          playbackStatus: PlaybackStatus.playing,
        );
      }
    });
  }

  void _stopBufferMonitoring() {
    _bufferMonitorTimer?.cancel();
    _bufferMonitorTimer = null;
  }

  Future<void> pauseSong(String songId) async {
    try {
      await player.pause();
      _updateSongState(songId, playbackStatus: PlaybackStatus.paused);
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao pausar: $e');
    }
  }

  Future<void> resumeSong(String songId) async {
    try {
      await player.play();
      _updateSongState(songId, playbackStatus: PlaybackStatus.playing);
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao retomar: $e');
    }
  }

  Future<void> stopSong(String songId) async {
    try {
      await player.stop();
      await player.seek(Duration.zero);
      _stopBufferMonitoring();
      _updateSongState(songId, playbackStatus: PlaybackStatus.stopped);
      
      if (_currentPlayingSongId == songId) {
        _currentPlayingSongId = null;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao parar: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await player.seek(position);
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao buscar posição: $e');
    }
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleRepeatOne() {
    _isRepeatOneEnabled = !_isRepeatOneEnabled;
    if (_isRepeatOneEnabled) _isRepeatAllEnabled = false;
    notifyListeners();
  }

  void toggleRepeatAll() {
    _isRepeatAllEnabled = !_isRepeatAllEnabled;
    if (_isRepeatAllEnabled) _isRepeatOneEnabled = false;
    notifyListeners();
  }

  Future<void> _onSongCompleted() async {
    if (_currentPlayingSongId == null) return;

    _stopBufferMonitoring();

    if (_isRepeatOneEnabled) {
      await playSong(_currentPlayingSongId!);
    } else if (_isRepeatAllEnabled || _isShuffleEnabled) {
      await playNext();
    } else {
      _currentPlayingSongId = null;
      notifyListeners();
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentPlayingSongId == null) return;

    final currentIndex = _playlist.indexWhere((s) => s.id == _currentPlayingSongId);
    if (currentIndex == -1) return;

    int nextIndex;
    if (_isShuffleEnabled) {
      nextIndex = Random().nextInt(_playlist.length);
    } else {
      nextIndex = (currentIndex + 1) % _playlist.length;
    }

    await playSong(_playlist[nextIndex].id);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentPlayingSongId == null) return;

    final currentIndex = _playlist.indexWhere((s) => s.id == _currentPlayingSongId);
    if (currentIndex == -1) return;

    int prevIndex;
    if (_isShuffleEnabled) {
      prevIndex = Random().nextInt(_playlist.length);
    } else {
      prevIndex = (currentIndex - 1 + _playlist.length) % _playlist.length;
    }

    await playSong(_playlist[prevIndex].id);
  }

  void _updateSongState(
    String songId, {
    DownloadStatus? downloadStatus,
    PlaybackStatus? playbackStatus,
    double? downloadProgress,
    double? bufferProgress,
    bool? isBufferSufficient,
    String? errorMessage,
    String? localPath,
  }) {
    final currentState = _songStates[songId];
    if (currentState == null) return;

    _songStates[songId] = currentState.copyWith(
      downloadStatus: downloadStatus,
      playbackStatus: playbackStatus,
      downloadProgress: downloadProgress,
      bufferProgress: bufferProgress,
      isBufferSufficient: isBufferSufficient,
      errorMessage: errorMessage,
      localPath: localPath,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    if (kDebugMode) print('🧹 Limpando recursos...');
    
    _locationTimer?.cancel();
    _bufferMonitorTimer?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferPositionSubscription?.cancel();
    _downloadService.dispose();
    
    super.dispose();
  }

  static Future<void> disposeSharedPlayer() async {
    if (_sharedPlayer != null) {
      await _sharedPlayer!.dispose();
      _sharedPlayer = null;
      if (kDebugMode) print('🗑️ Player compartilhado descartado');
    }
  }
}