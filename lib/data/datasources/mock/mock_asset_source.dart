import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';

abstract interface class MockAssetSource {
  Future<Map<String, dynamic>> load();
}

class BundledMockAssetSource implements MockAssetSource {
  BundledMockAssetSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  Map<String, dynamic>? _cached;

  @override
  Future<Map<String, dynamic>> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final raw = await _bundle.loadString(AppConfig.mockDataAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cached = decoded;
    return decoded;
  }
}

class StaticMockAssetSource implements MockAssetSource {
  StaticMockAssetSource(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> load() async => payload;
}
