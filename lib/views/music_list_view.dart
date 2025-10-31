import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/music_viewmodel.dart';
import '../models/song.dart';

class MusicListView extends StatelessWidget {
  const MusicListView({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Beat'),
        actions: [
          Consumer<MusicViewModel>(
            builder: (context, viewModel, _) {
              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: viewModel.isShuffleEnabled 
                          ? Colors.blue 
                          : Colors.grey,
                    ),
                    onPressed: viewModel.toggleShuffle,
                    tooltip: 'Shuffle',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.repeat_one,
                      color: viewModel.isRepeatOneEnabled 
                          ? Colors.blue 
                          : Colors.grey,
                    ),
                    onPressed: viewModel.toggleRepeatOne,
                    tooltip: 'Repeat One',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: viewModel.isRepeatAllEnabled 
                          ? Colors.blue 
                          : Colors.grey,
                    ),
                    onPressed: viewModel.toggleRepeatAll,
                    tooltip: 'Repeat All',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MusicViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Carregando playlist',
              ),
            );
          }
          
          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${viewModel.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.loadPlaylist,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          
          if (viewModel.playlist.isEmpty) {
            return const Center(
              child: Text('Nenhuma música encontrada'),
            );
          }
          
          return ListView.builder(
            itemCount: viewModel.playlist.length,
            itemBuilder: (context, index) {
              final song = viewModel.playlist[index];
              return MusicListItem(song: song);
            },
          );
        },
      ),
    );
  }
}

class MusicListItem extends StatelessWidget {
  final Song song;
  
  const MusicListItem({Key? key, required this.song}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MusicViewModel>(
      builder: (context, viewModel, _) {
        final state = viewModel.getSongState(song.id);
        if (state == null) return const SizedBox.shrink();
        
        final isCurrentSong = viewModel.currentPlayingSongId == song.id;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isCurrentSong ? 4 : 1,
          color: isCurrentSong ? Colors.blue.shade50 : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            semanticsLabel: 'Título: ${song.title}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.author,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            semanticsLabel: 'Artista: ${song.author}',
                          ),
                        ],
                      ),
                    ),
                    _buildPlaybackControls(context, viewModel, state),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatusIndicator(state),
                if (state.downloadStatus == DownloadStatus.downloading ||
                    state.playbackStatus == PlaybackStatus.buffering)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: state.downloadProgress,
                        backgroundColor: Colors.grey[300],
                        semanticsLabel: 'Progresso do download: ${(state.downloadProgress * 100).toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(state.downloadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPlaybackControls(
    BuildContext context,
    MusicViewModel viewModel,
    SongState state,
  ) {
    final isCurrentSong = viewModel.currentPlayingSongId == song.id;
    
    if (state.playbackStatus == PlaybackStatus.playing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => viewModel.pauseSong(song.id),
            tooltip: 'Pausar',
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => viewModel.stopSong(song.id),
            tooltip: 'Parar',
          ),
        ],
      );
    } else if (state.playbackStatus == PlaybackStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => viewModel.resumeSong(song.id),
            tooltip: 'Retomar',
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => viewModel.stopSong(song.id),
            tooltip: 'Parar',
          ),
        ],
      );
    } else if (state.playbackStatus == PlaybackStatus.buffering) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () => viewModel.playSong(song.id),
        tooltip: 'Reproduzir',
      );
    }
  }
  
  Widget _buildStatusIndicator(SongState state) {
    String statusText = '';
    Color statusColor = Colors.grey;
    
    if (state.playbackStatus == PlaybackStatus.playing) {
      statusText = '▶ Reproduzindo';
      statusColor = Colors.green;
    } else if (state.playbackStatus == PlaybackStatus.paused) {
      statusText = '⏸ Pausado';
      statusColor = Colors.orange;
    } else if (state.playbackStatus == PlaybackStatus.buffering) {
      statusText = '⏳ Buffering...';
      statusColor = Colors.blue;
    } else if (state.downloadStatus == DownloadStatus.downloading) {
      statusText = '⬇ Baixando...';
      statusColor = Colors.blue;
    } else if (state.downloadStatus == DownloadStatus.completed) {
      statusText = '✓ Baixado';
      statusColor = Colors.green;
    } else if (state.downloadStatus == DownloadStatus.error ||
               state.playbackStatus == PlaybackStatus.error) {
      statusText = '✗ Erro';
      statusColor = Colors.red;
    } else {
      statusText = '⏹ Pronto';
      statusColor = Colors.grey;
    }
    
    return Text(
      statusText,
      style: TextStyle(
        fontSize: 12,
        color: statusColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}