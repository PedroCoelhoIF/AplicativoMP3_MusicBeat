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
  
  // Usa URL como identificador único
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
    // Usa hash da URL para nome do arquivo
    final hash = url.hashCode.abs();
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    return '${hash}_$cleanTitle.mp3';
  }
}

enum DownloadStatus {
  idle,
  downloading,
  buffering,
  completed,
  error,
}

enum PlaybackStatus {
  idle,
  playing,
  paused,
  stopped,
  buffering,
  error,
}

class SongState {
  final Song song;
  final DownloadStatus downloadStatus;
  final PlaybackStatus playbackStatus;
  final double downloadProgress;
  final double bufferProgress;
  final String? errorMessage;
  final String? localPath;
  
  SongState({
    required this.song,
    this.downloadStatus = DownloadStatus.idle,
    this.playbackStatus = PlaybackStatus.idle,
    this.downloadProgress = 0.0,
    this.bufferProgress = 0.0,
    this.errorMessage,
    this.localPath,
  });
  
  SongState copyWith({
    Song? song,
    DownloadStatus? downloadStatus,
    PlaybackStatus? playbackStatus,
    double? downloadProgress,
    double? bufferProgress,
    String? errorMessage,
    String? localPath,
  }) {
    return SongState(
      song: song ?? this.song,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      bufferProgress: bufferProgress ?? this.bufferProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      localPath: localPath ?? this.localPath,
    );
  }
}