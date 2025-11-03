import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class ApiService {
  static const String baseUrl = 'https://www.rafaelamorim.com.br/mobile2/musicas/list.json';
  
  Future<List<Song>> fetchPlaylist() async {
    try {
      print('🌐 Tentando acessar: $baseUrl');
      
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tempo de conexão esgotado');
        },
      );
      
      print('📡 Status da resposta: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Limpa o JSON removendo caracteres problemáticos
        String jsonString = response.body.trim();
        
        print('🔧 Corrigindo JSON malformado...');
        
        // Remove espaços extras e tabs
        jsonString = jsonString.replaceAll('\t', ' ');
        
        // Corrige vírgulas faltantes entre objetos usando regex mais robusto
        // Procura por "}\n" ou "}" seguido de espaços e "{" 
        jsonString = jsonString.replaceAllMapped(
          RegExp(r'\}\s*\n\s*\{'),
          (match) => '},\n   {',
        );
        
        print('📄 Tentando decodificar JSON...');
        
        try {
          final dynamic jsonResponse = json.decode(jsonString);
          
          print('✅ JSON decodificado com sucesso');
          print('🔍 Tipo do JSON: ${jsonResponse.runtimeType}');
          
          List<dynamic> songsJson;
          
          if (jsonResponse is Map<String, dynamic>) {
            print('📦 É um Map, procurando chaves...');
            print('🔑 Chaves disponíveis: ${jsonResponse.keys.toList()}');
            
            if (jsonResponse.containsKey('musicas')) {
              songsJson = jsonResponse['musicas'] as List;
            } else if (jsonResponse.containsKey('songs')) {
              songsJson = jsonResponse['songs'] as List;
            } else {
              final firstList = jsonResponse.values.firstWhere(
                (value) => value is List,
                orElse: () => [jsonResponse],
              );
              songsJson = firstList is List ? firstList : [jsonResponse];
            }
          } else if (jsonResponse is List) {
            print('📋 É uma Lista direta com ${jsonResponse.length} itens');
            songsJson = jsonResponse;
          } else {
            songsJson = [jsonResponse];
          }
          
          print('🎵 Total de músicas encontradas: ${songsJson.length}');
          
          final songs = <Song>[];
          for (var i = 0; i < songsJson.length; i++) {
            try {
              final song = Song.fromJson(songsJson[i]);
              songs.add(song);
              print('✅ Música ${i + 1}: ${song.title} - ${song.author}');
            } catch (e) {
              print('⚠️ Erro ao processar música $i: $e');
            }
          }
          
          print('🎉 ${songs.length} músicas carregadas com sucesso!');
          return songs;
          
        } catch (e) {
          print('❌ Erro ao decodificar JSON: $e');
          print('📝 JSON problemático:');
          print(jsonString.substring(0, jsonString.length > 500 ? 500 : jsonString.length));
          throw Exception('Erro ao processar JSON: $e');
        }
      } else {
        throw Exception('Erro ao carregar playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro geral: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Sem conexão com a internet');
      }
      rethrow;
    }
  }
}