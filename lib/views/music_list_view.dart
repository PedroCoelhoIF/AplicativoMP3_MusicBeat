import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/music_viewmodel.dart';
import '../models/song.dart';
import 'package:flutter/foundation.dart';

class MusicListView extends StatelessWidget {
  const MusicListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicViewModel>(
      builder: (context, musicViewModel, child) {
        if (musicViewModel.error != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Music Beat')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Erro ao carregar a playlist: ${musicViewModel.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (musicViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (musicViewModel.playlist.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Music Beat')),
            body: const Center(
              child: Text('Nenhuma música encontrada.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/img/music_beat_logo.jpg',
                  height: 32, 
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("❌ Imagem do logo não encontrada em assets/img/music_beat_logo.jpg");
                    return const Icon(Icons.music_video, color: Color(0xFFBB86FC), size: 32);
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Music Beat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  musicViewModel.isShuffleEnabled ? Icons.shuffle_on : Icons.shuffle,
                  color: musicViewModel.isShuffleEnabled ? Theme.of(context).primaryColor : Colors.white,
                ),
                onPressed: musicViewModel.toggleShuffle,
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: musicViewModel.playlist.length,
            itemBuilder: (context, index) {
              final Song song = musicViewModel.playlist[index];
              final SongState? state = musicViewModel.getSongState(song.id);
              final isPlaying = state?.playbackStatus == PlaybackStatus.playing || state?.playbackStatus == PlaybackStatus.buffering;
              
              return MusicListTile(
                song: song,
                state: state,
                isPlaying: isPlaying,
                onPlayPause: () {
                  if (isPlaying || state?.playbackStatus == PlaybackStatus.paused) {
                      musicViewModel.pauseSong(song.id);
                  } else {
                      musicViewModel.playSong(song.id);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}


class MusicListTile extends StatelessWidget {
  final Song song;
  final SongState? state;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const MusicListTile({
    required this.song,
    required this.onPlayPause,
    this.state,
    this.isPlaying = false,
    super.key,
  });


  Color get titleColor => isPlaying ? const Color(0xFFBB86FC) : Colors.white;


  Widget _buildLeadingIcon(BuildContext context) {
    if (state?.downloadStatus == DownloadStatus.downloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: state!.downloadProgress,
          strokeWidth: 2.5,
          color: Colors.greenAccent,
        ),
      );
    }
    return Icon(
      isPlaying ? Icons.volume_up : Icons.music_note,
      color: isPlaying ? const Color(0xFFBB86FC) : Colors.grey,
      size: 24,
    );
  }


  Widget _buildTrailingAction(BuildContext context) {
    if (state?.playbackStatus == PlaybackStatus.buffering) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        color: titleColor,
        size: 32,
      ),
      onPressed: onPlayPause,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlayPause,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [

            _buildLeadingIcon(context),
            const SizedBox(width: 15),
            Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        song.title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      if (state?.downloadStatus == DownloadStatus.downloading)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: state!.downloadProgress,
              color: Colors.greenAccent,
              backgroundColor: Colors.grey.shade800,
            ),
            const SizedBox(height: 2),
            Text(
              'Baixando... (${(state!.downloadProgress * 100).toStringAsFixed(0)}%)',
              style: TextStyle(color: Colors.green.shade400, fontSize: 11),
            ),
          ],
        )
      else
        Text(
          song.author,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ],
  ),
),
            
            if (song.duration != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  song.duration!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            _buildTrailingAction(context),
          ],
        ),
      ),
    );
  }
}