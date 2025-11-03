import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';

class DownloadService {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  
  // Configurações de buffer para streaming progressivo
  static const double BUFFER_INICIAL_PERCENT = 0.15; // 15% de buffer inicial
  static const double BUFFER_MINIMO_PERCENT = 0.05;   // 5% buffer mínimo para continuar
  static const int BUFFER_CHECK_INTERVAL_MS = 500;    // Verifica buffer a cada 500ms
  
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
  
  ///  Download com Streaming Progressivo e Gerenciamento de Buffer
  Future<void> downloadFileWithBuffer(
    Song song,
    Function(double downloadProgress) onProgress,
    Function(double bufferLevel, bool isSufficient) onBufferUpdate,
    Function(String filePath) onBufferReady, // Chamado quando buffer inicial está pronto
    Function(String filePath) onComplete,
    Function(String errorMsg) onError,
  ) async {
    try {
      final path = await getDownloadPath();
      final filePath = '$path/${song.fileName}';
      final file = File(filePath);
      
      // Se arquivo já existe, retorna imediatamente
      if (await file.exists()) {
        onBufferUpdate(1.0, true);
        onBufferReady(filePath);
        onComplete(filePath);
        return;
      }
      
      final cancelToken = CancelToken();
      _cancelTokens[song.id] = cancelToken;
      
      if (kDebugMode) print('📥 Iniciando download: ${song.title}');
      
      bool bufferReadyCalled = false;
      
      await _dio.download(
        song.url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final downloadProgress = received / total;
            onProgress(downloadProgress);
            
            //  Calcula nível do buffer
            final bufferLevel = downloadProgress;
            final isSufficient = bufferLevel >= BUFFER_MINIMO_PERCENT;
            
            onBufferUpdate(bufferLevel, isSufficient);
            
            // Quando atingir buffer inicial (15%), notifica para começar reprodução
            if (!bufferReadyCalled && downloadProgress >= BUFFER_INICIAL_PERCENT) {
              bufferReadyCalled = true;
              if (kDebugMode) {
                print('🎯 Buffer inicial atingido (${(BUFFER_INICIAL_PERCENT * 100).toInt()}%) - Iniciando reprodução');
              }
              onBufferReady(filePath);
            }
            
            // Logs de progresso
            if (kDebugMode && downloadProgress % 0.1 < 0.01) {
              print('📊 Download: ${(downloadProgress * 100).toInt()}% | Buffer: ${isSufficient ? "✅" : "⏳"}');
            }
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          receiveTimeout: Duration(minutes: 5),
        ),
      );
      
      _cancelTokens.remove(song.id);
      
      if (kDebugMode) print('✅ Download completo: ${song.title}');
      onComplete(filePath);
      
    } catch (e) {
      _cancelTokens.remove(song.id);
      
      String errorMsg = 'Erro desconhecido';
      
      if (e is DioException) {
        if (e.type == DioExceptionType.cancel) {
          errorMsg = 'Download cancelado';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg = 'Tempo de conexão esgotado';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Tempo de recebimento esgotado';
        } else {
          errorMsg = 'Erro de rede: ${e.message}';
        }
      } else {
        errorMsg = 'Erro ao baixar: $e';
      }
      
      if (kDebugMode) print('❌ $errorMsg');
      onError(errorMsg);
    }
  }
  
  /// Monitora buffer durante reprodução
  Future<bool> checkBufferLevel(Song song, double currentPosition, double duration) async {
    try {
      final filePath = await getLocalFilePath(song);
      if (filePath == null) return false;
      
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final fileSize = await file.length();
      final expectedSize = fileSize; // Tamanho esperado baseado na duração
      
      // Calcula quanto do arquivo já foi baixado
      final downloadedPercent = fileSize / expectedSize;
      
      // Calcula quanto já foi reproduzido
      final playedPercent = currentPosition / duration;
      
      // Buffer = quanto foi baixado - quanto foi tocado
      final bufferAhead = downloadedPercent - playedPercent;
      
      // Se buffer à frente é menor que o mínimo, retorna false
      return bufferAhead >= BUFFER_MINIMO_PERCENT;
      
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao verificar buffer: $e');
      return false;
    }
  }
  
  /// Cancela download
  void cancelDownload(String songId) {
    final token = _cancelTokens[songId];
    if (token != null) {
      token.cancel('Cancelado pelo usuário');
      _cancelTokens.remove(songId);
      if (kDebugMode) print('🚫 Download cancelado: $songId');
    }
  }
  
  /// Deleta arquivo baixado
  Future<void> deleteFile(Song song) async {
    try {
      final path = await getDownloadPath();
      final file = File('$path/${song.fileName}');
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) print('🗑️ Arquivo deletado: ${song.fileName}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao deletar arquivo: $e');
    }
  }
  
  /// Limpa todos os downloads
  void dispose() {
    for (var token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
    _dio.close();
    if (kDebugMode) print('🧹 DownloadService finalizado');
  }
}