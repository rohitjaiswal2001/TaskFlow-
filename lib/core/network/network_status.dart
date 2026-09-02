import '../config/simulation_settings.dart';

abstract interface class NetworkStatus {
  bool get isOnline;
}

class SimulatedNetworkStatus implements NetworkStatus {
  SimulatedNetworkStatus(this._settings);

  final SimulationSettings _settings;

  @override
  bool get isOnline => _settings.isOnline;
}
