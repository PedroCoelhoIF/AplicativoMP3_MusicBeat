import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double CAMPUS_LATITUDE = -30.900789853798763;
  static const double CAMPUS_LONGITUDE = -55.53282373246195;
  static const double RAIO_METROS = 50.0;

  // Cache da última verificação
  DateTime? _lastCheck;
  bool? _lastResult;
  static const Duration _cacheValidity = Duration(minutes: 5); //  Cache de 5 minutos

  /// Verifica se o usuário está próximo ao Campus (com cache)
  Future<bool> isNearCampus() async {
    // Retorna resultado em cache se ainda válido
    if (_lastCheck != null && _lastResult != null) {
      final timeSinceCheck = DateTime.now().difference(_lastCheck!);
      if (timeSinceCheck < _cacheValidity) {
        return _lastResult!;
      }
    }

    try {
      // Verificação rápida de serviço
      if (!await Geolocator.isLocationServiceEnabled()) {
        _cacheResult(false);
        return false;
      }

      // Verificação de permissões (sem solicitar se negada)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        _cacheResult(false);
        return false;
      }

      // Obtém posição com timeout curto
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Precisão baixa é mais rápida
        timeLimit: Duration(seconds: 5), // Timeout reduzido
      );

      // Calcula distância
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        CAMPUS_LATITUDE,
        CAMPUS_LONGITUDE,
      );

      bool isNear = distanceInMeters <= RAIO_METROS;
      _cacheResult(isNear);
      return isNear;
      
    } catch (e) {
      _cacheResult(false);
      return false;
    }
  }

  void _cacheResult(bool result) {
    _lastCheck = DateTime.now();
    _lastResult = result;
  }

  /// Limpa o cache (útil ao retomar o app)
  void clearCache() {
    _lastCheck = null;
    _lastResult = null;
  }

  /// Solicita permissão de localização
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }
}
