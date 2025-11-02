import 'package:geolocator/geolocator.dart';

class LocationService {
  // 📍 Coordenadas do IFSul Campus Santana do Livramento
  // Rua Paul Harris, 410 - Centro
  static const double CAMPUS_LATITUDE = -30.900789853798763;
  static const double CAMPUS_LONGITUDE = -55.53282373246195;
  static const double RAIO_METROS = 50.0;

  /// Verifica se o usuário está próximo ao Campus (dentro de 50 metros)
  Future<bool> isNearCampus() async {
    try {
      // 1️⃣ Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Serviço de localização desabilitado');
        return false;
      }

      // 2️⃣ Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Solicita permissão
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Permissão de localização negada');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Permissão de localização negada permanentemente');
        return false;
      }

      // 3️⃣ Obtém posição atual
      print('📍 Obtendo localização atual...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      print(
          '📍 Posição atual: Lat ${position.latitude}, Long ${position.longitude}');

      // 4️⃣ Calcula distância até o Campus
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        CAMPUS_LATITUDE,
        CAMPUS_LONGITUDE,
      );

      print(
          '📏 Distância até o Campus: ${distanceInMeters.toStringAsFixed(2)} metros');

      // 5️⃣ Verifica se está dentro do raio
      bool isNear = distanceInMeters <= RAIO_METROS;

      if (isNear) {
        print('🎉 EASTER EGG DESBLOQUEADO! Você está no Campus!');
      } else {
        print(
            '❌ Você está longe do Campus (${distanceInMeters.toStringAsFixed(0)}m)');
      }

      return isNear;
    } catch (e) {
      print('❌ Erro ao obter localização: $e');
      return false;
    }
  }

  /// Obtém a distância atual até o Campus (em metros)
  /// Útil para debug/testes
  Future<double?> getDistanceToCampus() async {
    try {
      Position position = await Geolocator.getCurrentPosition();

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        CAMPUS_LATITUDE,
        CAMPUS_LONGITUDE,
      );

      return distance;
    } catch (e) {
      print('❌ Erro ao calcular distância: $e');
      return null;
    }
  }

  /// Verifica o status das permissões (útil para UI)
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }
}
