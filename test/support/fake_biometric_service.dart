import 'package:taskflow/core/services/biometric_service.dart';

class FakeBiometricService extends BiometricService {
  FakeBiometricService({this.available = false, this.unlocks = true});

  final bool available;
  final bool unlocks;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String reason}) async => unlocks;
}
