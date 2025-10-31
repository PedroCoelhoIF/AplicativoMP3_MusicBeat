import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/music_viewmodel.dart';
import '../models/song.dart';

class MusicListView extends StatelessWidget {
  const MusicListView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.purple.shade900, Colors.blue.shade900]
                  : [Colors.purple.shade400, Colors.blue.shade400],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.music_note, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Music Beat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<MusicViewModel>(
            builder: (context, viewModel, _) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.shuffle,
                      isActive: viewModel.isShuffleEnabled,
                      onPressed: viewModel.toggleShuffle,
                      tooltip: 'Aleatório',
                    ),
                    _buildControlButton(
                      icon: Icons.repeat_one,
                      isActive: viewModel.isRepeatOneEnabled,
                      onPressed: viewModel.toggleRepeatOne,
                      tooltip: 'Repetir Uma',
                    ),
                    _buildControlButton(
                      icon: Icons.repeat,
                      isActive: viewModel.isRepeatAllEnabled,
                      onPressed: viewModel.toggleRepeatAll,
                      tooltip: 'Repetir Todas',
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.purple.shade900.withOpacity(0.3), Colors.black]
                : [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: Consumer<MusicViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Carregando suas músicas...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            if (viewModel.error != null) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline, 
                          size: 64, 
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Ops! Algo deu errado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        viewModel.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: viewModel.loadPlaylist,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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
            
            if (viewModel.playlist.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off,
                      size: 80,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma música encontrada',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                const SizedBox(height: 100), // Espaço para AppBar
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: viewModel.playlist.length,
                    itemBuilder: (context, index) {
                      final song = viewModel.playlist[index];
                      return MusicListItem(song: song, index: index);
                    },
                  ),
                ),
                // Mini Player
                _MiniPlayer(),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: isActive ? Colors.white : Colors.white54,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

class MusicListItem extends StatefulWidget {
  final Song song;
  final int index;
  
  const MusicListItem({
    Key? key, 
    required this.song,
    required this.index,
  }) : super(key: key);
  
  @override
  State<MusicListItem> createState() => _MusicListItemState();
}

class _MusicListItemState extends State<MusicListItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    // Animação de entrada escalonada
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Consumer<MusicViewModel>(
        builder: (context, viewModel, _) {
          final state = viewModel.getSongState(widget.song.id);
          if (state == null) return const SizedBox.shrink();
          
          final isCurrentSong = viewModel.currentPlayingSongId == widget.song.id;
          final isPlaying = state.playbackStatus == PlaybackStatus.playing;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isCurrentSong
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Colors.purple.shade800, Colors.blue.shade800]
                          : [Colors.purple.shade100, Colors.blue.shade100],
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isCurrentSong 
                      ? Colors.purple.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isCurrentSong ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: isCurrentSong 
                  ? Colors.transparent 
                  : (isDark ? Colors.grey.shade900 : Colors.white),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => viewModel.playSong(widget.song.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Thumbnail animado
                          _buildThumbnail(isPlaying, isCurrentSong, isDark),
                          const SizedBox(width: 16),
                          // Informações da música
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.song.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentSong 
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 14,
                                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.song.author,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Controles
                          _buildPlaybackControls(context, viewModel, state),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Status e progresso
                      _buildStatusSection(state, isDark),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildThumbnail(bool isPlaying, bool isCurrentSong, bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrentSong
              ? [Colors.purple.shade600, Colors.blue.shade600]
              : isDark
                  ? [Colors.grey.shade800, Colors.grey.shade700]
                  : [Colors.grey.shade300, Colors.grey.shade200],
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentSong
                ? Colors.purple.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.music_note,
            color: Colors.white,
            size: 28,
          ),
          if (isPlaying)
            Positioned.fill(
              child: _AnimatedEqualizer(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPlaybackControls(
    BuildContext context,
    MusicViewModel viewModel,
    SongState state,
  ) {
    if (state.playbackStatus == PlaybackStatus.playing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(
            icon: Icons.pause_circle_filled,
            onPressed: () => viewModel.pauseSong(widget.song.id),
            tooltip: 'Pausar',
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          _buildIconButton(
            icon: Icons.stop_circle,
            onPressed: () => viewModel.stopSong(widget.song.id),
            tooltip: 'Parar',
            color: Colors.red,
          ),
        ],
      );
    } else if (state.playbackStatus == PlaybackStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(
            icon: Icons.play_circle_filled,
            onPressed: () => viewModel.resumeSong(widget.song.id),
            tooltip: 'Retomar',
            color: Colors.green,
          ),
          const SizedBox(width: 4),
          _buildIconButton(
            icon: Icons.stop_circle,
            onPressed: () => viewModel.stopSong(widget.song.id),
            tooltip: 'Parar',
            color: Colors.red,
          ),
        ],
      );
    } else if (state.playbackStatus == PlaybackStatus.buffering) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    } else {
      return _buildIconButton(
        icon: Icons.play_circle_filled,
        onPressed: () => viewModel.playSong(widget.song.id),
        tooltip: 'Reproduzir',
        color: Colors.green,
      );
    }
  }
  
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 32),
      color: color,
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }
  
  Widget _buildStatusSection(SongState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusChip(state, isDark),
            const Spacer(),
            if (state.downloadStatus == DownloadStatus.completed)
              Icon(
                Icons.download_done,
                size: 16,
                color: Colors.green,
              ),
          ],
        ),
        if (state.downloadStatus == DownloadStatus.downloading ||
            state.playbackStatus == PlaybackStatus.buffering) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.downloadProgress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.playbackStatus == PlaybackStatus.buffering
                    ? Colors.blue
                    : Colors.purple,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatusChip(SongState state, bool isDark) {
    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    
    if (state.playbackStatus == PlaybackStatus.playing) {
      statusText = 'Reproduzindo';
      statusColor = Colors.green;
      statusIcon = Icons.play_arrow;
    } else if (state.playbackStatus == PlaybackStatus.paused) {
      statusText = 'Pausado';
      statusColor = Colors.orange;
      statusIcon = Icons.pause;
    } else if (state.playbackStatus == PlaybackStatus.buffering) {
      statusText = 'Carregando...';
      statusColor = Colors.blue;
      statusIcon = Icons.hourglass_empty;
    } else if (state.downloadStatus == DownloadStatus.downloading) {
      statusText = 'Baixando';
      statusColor = Colors.blue;
      statusIcon = Icons.download;
    } else if (state.downloadStatus == DownloadStatus.completed) {
      statusText = 'Pronto';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (state.downloadStatus == DownloadStatus.error ||
               state.playbackStatus == PlaybackStatus.error) {
      statusText = 'Erro';
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusText = 'Disponível';
      statusColor = isDark ? Colors.white54 : Colors.grey.shade600;
      statusIcon = Icons.music_note;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de equalizer animado
class _AnimatedEqualizer extends StatefulWidget {
  const _AnimatedEqualizer();
  
  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _EqualizerPainter(_controller.value),
        );
      },
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final double animation;
  
  _EqualizerPainter(this.animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final barWidth = size.width / 7;
    final maxHeight = size.height * 0.5;
    
    for (int i = 0; i < 3; i++) {
      final x = size.width / 2 + (i - 1) * barWidth;
      final height = maxHeight * (0.3 + 0.7 * (animation + i * 0.2) % 1);
      canvas.drawLine(
        Offset(x, size.height / 2 + height / 2),
        Offset(x, size.height / 2 - height / 2),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(_EqualizerPainter oldDelegate) => true;
}

// Mini Player fixo na parte inferior
class _MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<MusicViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.currentPlayingSongId == null) {
          return const SizedBox.shrink();
        }
        
        final state = viewModel.getSongState(viewModel.currentPlayingSongId!);
        if (state == null) return const SizedBox.shrink();
        
        final isPlaying = state.playbackStatus == PlaybackStatus.playing;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey.shade900, Colors.black]
                  : [Colors.white, Colors.grey.shade100],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade600, Colors.blue.shade600],
                      ),
                    ),
                    child: Icon(
                      isPlaying ? Icons.music_note : Icons.pause,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.song.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          state.song.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying)
                        IconButton(
                          icon: const Icon(Icons.pause_circle_filled),
                          iconSize: 36,
                          color: Colors.orange,
                          onPressed: () => viewModel.pauseSong(state.song.id),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.play_circle_filled),
                          iconSize: 36,
                          color: Colors.green,
                          onPressed: () => viewModel.resumeSong(state.song.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 32,
                        onPressed: viewModel.playNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}