import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

enum SimulatedFault {
  none('None'),
  serverError('Server error (500)'),
  timeout('Network timeout'),
  notFound('Not found (404)'),
  unauthorized('Expired token (401)');

  const SimulatedFault(this.label);

  final String label;
}

class SimulationSettings extends ChangeNotifier {
  SimulationSettings(this._prefs);

  static const _kOffline = 'sim.offline';
  static const _kLatency = 'sim.latency_enabled';
  static const _kFault = 'sim.fault';
  static const _kOneShot = 'sim.fault_one_shot';

  final SharedPreferences _prefs;

  bool _offline = false;
  bool _latencyEnabled = true;
  SimulatedFault _fault = SimulatedFault.none;
  bool _faultIsOneShot = true;

  bool get isOffline => _offline;
  bool get isOnline => !_offline;
  bool get latencyEnabled => _latencyEnabled;
  SimulatedFault get fault => _fault;
  bool get faultIsOneShot => _faultIsOneShot;

  Duration get latency => _latencyEnabled
      ? AppConfig.minLatency +
            (AppConfig.maxLatency - AppConfig.minLatency) ~/ 2
      : Duration.zero;

  void restore() {
    _offline = _prefs.getBool(_kOffline) ?? false;
    _latencyEnabled = _prefs.getBool(_kLatency) ?? true;
    _faultIsOneShot = _prefs.getBool(_kOneShot) ?? true;
    final stored = _prefs.getString(_kFault);
    _fault = SimulatedFault.values.firstWhere(
      (f) => f.name == stored,
      orElse: () => SimulatedFault.none,
    );
    notifyListeners();
  }

  void setOffline(bool value) {
    if (_offline == value) return;
    _offline = value;
    _prefs.setBool(_kOffline, value);
    notifyListeners();
  }

  void toggleOffline() => setOffline(!_offline);

  void setLatencyEnabled(bool value) {
    _latencyEnabled = value;
    _prefs.setBool(_kLatency, value);
    notifyListeners();
  }

  void setFault(SimulatedFault value, {bool oneShot = true}) {
    _fault = value;
    _faultIsOneShot = oneShot;
    _prefs
      ..setString(_kFault, value.name)
      ..setBool(_kOneShot, oneShot);
    notifyListeners();
  }

  SimulatedFault takeFault() {
    final current = _fault;
    if (current != SimulatedFault.none && _faultIsOneShot) {
      _fault = SimulatedFault.none;
      _prefs.setString(_kFault, SimulatedFault.none.name);

      Future.microtask(notifyListeners);
    }
    return current;
  }

  void reset() {
    _offline = false;
    _latencyEnabled = true;
    _fault = SimulatedFault.none;
    _faultIsOneShot = true;
    _prefs
      ..remove(_kOffline)
      ..remove(_kLatency)
      ..remove(_kFault)
      ..remove(_kOneShot);
    notifyListeners();
  }
}
