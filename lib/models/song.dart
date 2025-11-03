class Song {
  final String title;
  final String author;
  final String url;
  final String? duration;
  
  Song({
    required this.title,
    required this.author,
    required this.url,
    this.duration,
  });
  
  String get id => url;
  
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title']?.toString() ?? 'Unknown',
      author: json['author']?.toString() ?? 'Unknown',
      url: json['url']?.toString() ?? '',
      duration: json['duration']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'url': url,
      if (duration != null) 'duration': duration,
    };
  }
  
  String get fileName {
    final hash = url.hashCode.abs();
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '${hash}_$cleanTitle.mp3';
  }
}

enum DownloadStatus {
  idle,           // Nada acontecendo
  downloading,    // Baixando arquivo
  buffering,      // Enchendo buffer inicial
  completed,      // Download completo
  error,          // Erro no download
}

enum PlaybackStatus {
  idle,              // Parado
  playing,           // Tocando normalmente
  paused,            // Pausado pelo usuário
  stopped,           // Parado completamente
  buffering,         // Enchendo buffer
  waitingForBuffer,  // ⚡ NOVO: Esperando buffer encher
  error,             // Erro na reprodução
}

class SongState {
  final Song song;
  final DownloadStatus downloadStatus;
  final PlaybackStatus playbackStatus;
  final double downloadProgress;      // 0.0 a 1.0 - progresso do download
  final double bufferProgress;        // ⚡ 0.0 a 1.0 - quanto do buffer está cheio
  final bool isBufferSufficient;      // ⚡ Se tem buffer suficiente para tocar
  final String? errorMessage;
  final String? localPath;
  
  SongState({
    required this.song,
    this.downloadStatus = DownloadStatus.idle,
    this.playbackStatus = PlaybackStatus.idle,
    this.downloadProgress = 0.0,
    this.bufferProgress = 0.0,
    this.isBufferSufficient = false,
    this.errorMessage,
    this.localPath,
  });
  
  SongState copyWith({
    Song? song,
    DownloadStatus? downloadStatus,
    PlaybackStatus? playbackStatus,
    double? downloadProgress,
    double? bufferProgress,
    bool? isBufferSufficient,
    String? errorMessage,
    String? localPath,
  }) {
    return SongState(
      song: song ?? this.song,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      bufferProgress: bufferProgress ?? this.bufferProgress,
      isBufferSufficient: isBufferSufficient ?? this.isBufferSufficient,
      errorMessage: errorMessage ?? this.errorMessage,
      localPath: localPath ?? this.localPath,
    );
  }
}