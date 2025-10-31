import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/audio_service_handler.dart';

class MusicViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DownloadService _downloadService = DownloadService();
  AudioPlayerHandler? _audioHandler;
  AudioPlayer? _simplePlayer; // Player simples para quando não tiver AudioService
  
  List<Song> _playlist = [];
  Map<String, SongState> _songStates = {};
  String? _currentPlayingSongId;
  bool _isLoading = false;
  String? _error;
  bool _isShuffleEnabled = false;
  bool _isRepeatOneEnabled = false;
  bool _isRepeatAllEnabled = false;
  
  List<Song> get playlist => _playlist;
  Map<String, SongState> get songStates => _songStates;
  String? get currentPlayingSongId => _currentPlayingSongId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatOneEnabled => _isRepeatOneEnabled;
  bool get isRepeatAllEnabled => _isRepeatAllEnabled;
  
  SongState? getSongState(String songId) => _songStates[songId];
  
  Future<void> initialize() async {
    print('🎵 Inicializando player sem AudioService (modo simplificado)');
    _audioHandler = null;
    await loadPlaylist();
  }
  
  Future<void> loadPlaylist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _playlist = await _apiService.fetchPlaylist();
      
      for (var song in _playlist) {
        final localPath = await _downloadService.getLocalFilePath(song);
        _songStates[song.id] = SongState(
          song: song,
          downloadStatus: localPath != null 
              ? DownloadStatus.completed 
              : DownloadStatus.idle,
          localPath: localPath,
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
  
  Future<void> playSong(String songId) async {
    final state = _songStates[songId];
    if (state == null) {
      print('❌ Estado da música não encontrado: $songId');
      return;
    }
    
    print('🎵 Iniciando reprodução: ${state.song.title}');

    if (_currentPlayingSongId != null && _currentPlayingSongId != songId) {
      print('⏹️ Parando música atual: $_currentPlayingSongId');
      await stopSong(_currentPlayingSongId!);
    }

    _currentPlayingSongId = songId;

    if (state.localPath != null) {
      print('✅ Arquivo já baixado, reproduzindo do cache: ${state.localPath}');
      await _playLocalFile(state);
    } else {
      print('⬇️ Arquivo não baixado, iniciando streaming progressivo');
      await _playWithProgressiveStreaming(state);
    }
  }

  Future<void> _playLocalFile(SongState state) async {
    print('🎵 Reproduzindo arquivo local: ${state.localPath}');
    
    _updateSongState(
      state.song.id,
      playbackStatus: PlaybackStatus.playing,
    );

    if (_audioHandler != null) {
      print('🔊 AudioHandler disponível, carregando áudio...');
      await _audioHandler?.loadAndPlay(
        state.localPath!,
        state.song.title,
        state.song.author,
      );
      print('✅ Comando de reprodução enviado');
    } else {
      print('⚠️ AudioHandler não disponível, usando just_audio diretamente');
      await _playWithoutAudioService(state.localPath!);
    }
  }

  Future<void> _playWithoutAudioService(String filePath) async {
    try {
      print('🎵 Criando player simples...');
      
      _simplePlayer ??= AudioPlayer();
      
      print('📂 Carregando arquivo: $filePath');
      await _simplePlayer!.setFilePath(filePath);
      
      print('▶️ Iniciando reprodução...');
      await _simplePlayer!.play();
      
      print('✅ Reprodução iniciada com sucesso!');
      print('🔊 Volume: ${_simplePlayer!.volume}');
      print('⏱️ Duração: ${_simplePlayer!.duration}');
      
      _simplePlayer!.playerStateStream.listen((state) {
        print('🎵 Estado do player: ${state.playing ? "Tocando" : "Pausado"} - ${state.processingState}');
        
        if (state.processingState == ProcessingState.completed) {
          print('✅ Música finalizada');
          _onSongCompleted();
        }
      });
      
      _simplePlayer!.positionStream.listen((position) {
        if (position.inSeconds % 5 == 0) {
          print('⏱️ Posição: ${position.inSeconds}s');
        }
      });
      
    } catch (e) {
      print('❌ Erro ao reproduzir com player simples: $e');
      _updateSongState(
        _currentPlayingSongId!,
        playbackStatus: PlaybackStatus.error,
        errorMessage: 'Erro ao reproduzir: $e',
      );
    }
  }

  Future<void> _playWithProgressiveStreaming(SongState state) async {
    print('🌊 Iniciando streaming progressivo para: ${state.song.title}');
    
    _updateSongState(
      state.song.id,
      downloadStatus: DownloadStatus.downloading,
      playbackStatus: PlaybackStatus.buffering,
    );

    _downloadService.downloadFile(
      state.song,
      (progress) {
        print('⬇️ Download: ${(progress * 100).toStringAsFixed(1)}%');
        _updateSongState(
          state.song.id,
          downloadProgress: progress,
        );

        if (progress >= 0.2 && 
            _songStates[state.song.id]?.playbackStatus == PlaybackStatus.buffering) {
          print('🎯 Buffer de 20% atingido, iniciando reprodução');
          _startStreamingPlayback(state);
        }
      },
      (filePath) {
        print('✅ Download completo: $filePath');
        _updateSongState(
          state.song.id,
          downloadStatus: DownloadStatus.completed,
          downloadProgress: 1.0,
          localPath: filePath,
        );
      },
      (errorMsg) {
        print('❌ Erro no download: $errorMsg');
        _updateSongState(
          state.song.id,
          downloadStatus: DownloadStatus.error,
          playbackStatus: PlaybackStatus.error,
          errorMessage: errorMsg,
        );
      },
    );
  }

  Future<void> _startStreamingPlayback(SongState state) async {
    print('🎬 Tentando iniciar reprodução em streaming...');
    final localPath = await _downloadService.getLocalFilePath(state.song);
    
    if (localPath != null) {
      print('📂 Arquivo encontrado: $localPath');
      _updateSongState(
        state.song.id,
        playbackStatus: PlaybackStatus.playing,
        localPath: localPath,
      );

      if (_audioHandler != null) {
        print('🔊 Usando AudioHandler para reprodução');
        await _audioHandler?.loadAndPlay(
          localPath,
          state.song.title,
          state.song.author,
        );
      } else {
        print('🔊 Usando just_audio diretamente');
        await _playWithoutAudioService(localPath);
      }
    } else {
      print('❌ Arquivo não encontrado após download parcial');
    }
  }

  Future<void> pauseSong(String songId) async {
    if (_audioHandler != null) {
      await _audioHandler?.pause();
    } else if (_simplePlayer != null) {
      print('⏸️ Pausando player simples');
      await _simplePlayer!.pause();
    }
    _updateSongState(songId, playbackStatus: PlaybackStatus.paused);
  }

  Future<void> resumeSong(String songId) async {
    if (_audioHandler != null) {
      await _audioHandler?.play();
    } else if (_simplePlayer != null) {
      print('▶️ Retomando player simples');
      await _simplePlayer!.play();
    }
    _updateSongState(songId, playbackStatus: PlaybackStatus.playing);
  }

  Future<void> stopSong(String songId) async {
    if (_audioHandler != null) {
      await _audioHandler?.stop();
    } else if (_simplePlayer != null) {
      print('⏹️ Parando player simples');
      await _simplePlayer!.stop();
      await _simplePlayer!.seek(Duration.zero);
    }
    _updateSongState(songId, playbackStatus: PlaybackStatus.stopped);
    if (_currentPlayingSongId == songId) {
      _currentPlayingSongId = null;
    }
  }
  
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }
  
  void toggleRepeatOne() {
    _isRepeatOneEnabled = !_isRepeatOneEnabled;
    if (_isRepeatOneEnabled) {
      _isRepeatAllEnabled = false;
    }
    notifyListeners();
  }
  
  void toggleRepeatAll() {
    _isRepeatAllEnabled = !_isRepeatAllEnabled;
    if (_isRepeatAllEnabled) {
      _isRepeatOneEnabled = false;
    }
    notifyListeners();
  }
  
  Future<void> _onSongCompleted() async {
    if (_currentPlayingSongId == null) return;
    
    if (_isRepeatOneEnabled) {
      await playSong(_currentPlayingSongId!);
    } else if (_isRepeatAllEnabled || _playlist.isNotEmpty) {
      await playNext();
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
  
  void _updateSongState(
    String songId, {
    DownloadStatus? downloadStatus,
    PlaybackStatus? playbackStatus,
    double? downloadProgress,
    double? bufferProgress,
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
      errorMessage: errorMessage,
      localPath: localPath,
    );
    notifyListeners();
  }
  
  @override
  void dispose() {
    _downloadService.dispose();
    _audioHandler?.dispose();
    _simplePlayer?.dispose();
    super.dispose();
  }
}