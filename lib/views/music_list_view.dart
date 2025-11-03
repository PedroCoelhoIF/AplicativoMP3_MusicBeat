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
      appBar: _buildAppBar(isDark),
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
              return _buildLoading(isDark);
            }
            
            if (viewModel.error != null) {
              return _buildError(viewModel, isDark);
            }
            
            if (viewModel.playlist.isEmpty) {
              return _buildEmpty(isDark);
            }
            
            return Column(
              children: [
                const SizedBox(height: 100),
                Expanded(
                  
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: viewModel.playlist.length,
                    itemBuilder: (context, index) {
                      final song = viewModel.playlist[index];
                      
                      return MusicListItem(song: song);
                    },
                  ),
                ),
                _MiniPlayer(),
              ],
            );
          },
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
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
                  ),
                  _buildControlButton(
                    icon: Icons.repeat_one,
                    isActive: viewModel.isRepeatOneEnabled,
                    onPressed: viewModel.toggleRepeatOne,
                  ),
                  _buildControlButton(
                    icon: Icons.repeat,
                    isActive: viewModel.isRepeatAllEnabled,
                    onPressed: viewModel.toggleRepeatAll,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: isActive ? Colors.white : Colors.white54,
      onPressed: onPressed,
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Carregando músicas...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MusicViewModel viewModel, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.loadPlaylist,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma música encontrada',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}


class MusicListItem extends StatelessWidget {
  final Song song;
  
  const MusicListItem({Key? key, required this.song}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<MusicViewModel>(
      builder: (context, viewModel, _) {
        final state = viewModel.getSongState(song.id);
        if (state == null) return const SizedBox.shrink();
        
        final isCurrentSong = viewModel.currentPlayingSongId == song.id;
        final isPlaying = state.playbackStatus == PlaybackStatus.playing;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrentSong
                ? (isDark ? Colors.purple.shade900 : Colors.purple.shade100)
                : (isDark ? Colors.grey.shade900 : Colors.white),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => viewModel.playSong(song.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    //  Thumbnail simples
                    _buildThumbnail(isPlaying, isCurrentSong, isDark),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.author,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Controles

                    _buildControls(viewModel, state, isDark),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildThumbnail(bool isPlaying, bool isCurrentSong, bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isCurrentSong
            ? Colors.purple.shade600
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
      ),
      child: Icon(
        isPlaying ? Icons.music_note : Icons.music_note,
        color: Colors.white,
        size: 24,
      ),
    );
  }
  
  // Widget para mostrar progresso do download
  Widget _buildDownloadProgress(SongState state, bool isDark) {
    final int percentage = (state.downloadProgress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.downloading, 
            size: 12, 
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Assinatura atualizada e lógica de exibição de progresso
  Widget _buildControls(MusicViewModel viewModel, SongState state, bool isDark) {
    
    // Mostra indicador de progresso centralizado
    // Se está bufferizando ou esperando buffer
    if (state.playbackStatus == PlaybackStatus.buffering ||
        state.playbackStatus == PlaybackStatus.waitingForBuffer) {
      
      final int percentage = (state.downloadProgress * 100).toInt();
      
      return SizedBox(
        width: 48, 
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              // Mostra progresso real se > 0, senão fica indeterminado (só girando)
              value: state.downloadProgress > 0 ? state.downloadProgress : null, 
              strokeWidth: 3,
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
    
    // Se está tocando
    if (state.playbackStatus == PlaybackStatus.playing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostra progresso se ainda estiver baixando
          if (state.downloadStatus == DownloadStatus.downloading)
            _buildDownloadProgress(state, isDark),
            
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => viewModel.pauseSong(song.id),
            color: Colors.orange,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => viewModel.stopSong(song.id),
            color: Colors.red,
          ),
        ],
      );
    } 
    
    // Se está pausado
    else if (state.playbackStatus == PlaybackStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Mostra progresso se ainda estiver baixando
          if (state.downloadStatus == DownloadStatus.downloading)
            _buildDownloadProgress(state, isDark),
            
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => viewModel.resumeSong(song.id),
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => viewModel.stopSong(song.id),
            color: Colors.red,
          ),
        ],
      );
    } 
    
    // Se está ocioso, parado ou erro
    else {
      // Verifica se está ocioso MAS o download foi iniciado
      if (state.downloadStatus == DownloadStatus.buffering || 
          state.downloadStatus == DownloadStatus.downloading) {
         
         // Reutiliza a lógica do progresso centralizado
         final int percentage = (state.downloadProgress * 100).toInt();
         return SizedBox(
          width: 48, 
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: state.downloadProgress > 0 ? state.downloadProgress : null, 
                strokeWidth: 3,
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        );
      }

      // Padrão (ocioso, parado, erro)
      return IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () => viewModel.playSong(song.id),
        color: Colors.green,
      );
    }
  }
}

// Mini Player
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
          color: isDark ? Colors.grey.shade900 : Colors.white,
          padding: const EdgeInsets.all(12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.purple.shade600,
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.song.author,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ⚡ NOVO: Mostra indicador de buffer no mini-player
                if (state.playbackStatus == PlaybackStatus.buffering ||
                    state.playbackStatus == PlaybackStatus.waitingForBuffer)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isPlaying)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: () => viewModel.pauseSong(state.song.id),
                    color: Colors.orange,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => viewModel.resumeSong(state.song.id),
                    color: Colors.green,
                  ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: viewModel.playNext,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}