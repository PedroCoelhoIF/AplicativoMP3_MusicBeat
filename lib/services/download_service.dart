import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class DownloadService {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  
  Future<String> getDownloadPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/music');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }
  
  Future<bool> isFileDownloaded(Song song) async {
    final path = await getDownloadPath();
    final file = File('$path/${song.fileName}');
    return await file.exists();
  }
  
  Future<String?> getLocalFilePath(Song song) async {
    final path = await getDownloadPath();
    final file = File('$path/${song.fileName}');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }
  
  Future<void> downloadFile(
    Song song,
    Function(double) onProgress,
    Function(String) onComplete,
    Function(String) onError,
  ) async {
    try {
      final path = await getDownloadPath();
      final filePath = '$path/${song.fileName}';
      final file = File(filePath);
      
      // Check if already downloaded
      if (await file.exists()) {
        onComplete(filePath);
        return;
      }
      
      // Create cancel token
      final cancelToken = CancelToken();
      _cancelTokens[song.id] = cancelToken;
      
      // Download with progress
      await _dio.download(
        song.url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );
      
      _cancelTokens.remove(song.id);
      onComplete(filePath);
    } catch (e) {
      _cancelTokens.remove(song.id);
      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          onError('Download cancelado');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          onError('Tempo de conexão esgotado');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          onError('Tempo de recebimento esgotado');
        } else {
          onError('Erro de rede: ${e.message}');
        }
      } else {
        onError('Erro ao baixar: $e');
      }
    }
  }
  
  void cancelDownload(String songId) {
    final token = _cancelTokens[songId];
    if (token != null) {
      token.cancel('Cancelado pelo usuário');
      _cancelTokens.remove(songId);
    }
  }
  
  Future<void> deleteFile(Song song) async {
    try {
      final path = await getDownloadPath();
      final file = File('$path/${song.fileName}');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erro ao deletar arquivo: $e');
    }
  }
  
  void dispose() {
    for (var token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
    _dio.close();
  }
}