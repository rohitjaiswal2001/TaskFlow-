import '../../core/errors/failure.dart';
import '../../core/errors/failure_mapper.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../datasources/local/cache_store.dart';

class CacheFallback {
  const CacheFallback(this._cache);

  final CacheStore _cache;

  Future<Result<Snapshot<List<E>>>> load<E, M>({
    required String key,
    required Future<List<M>> Function() fetch,
    required Map<String, dynamic> Function(M model) encode,
    required M Function(Map<String, dynamic> json) decode,
    required E Function(M model) toEntity,
  }) async {
    try {
      final models = await fetch();
      await _cache.write(key, models.map(encode).toList());

      return Ok(
        Snapshot.fresh(
          models.map(toEntity).toList(growable: false),
          fetchedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      final failure = mapExceptionToFailure(error);
      if (failure is! OfflineFailure && failure is! TimeoutFailure) {
        return Err(failure);
      }

      final cached = await _readCache(key, decode, toEntity);
      return cached ?? Err(failure);
    }
  }

  Future<Result<Snapshot<List<E>>>?> _readCache<E, M>(
    String key,
    M Function(Map<String, dynamic> json) decode,
    E Function(M model) toEntity,
  ) async {
    final entry = await _cache.read(key);
    final payload = entry?.payload;
    if (entry == null || payload is! List) return null;

    try {
      final models = payload
          .whereType<Map>()
          .map((row) => decode(row.cast<String, dynamic>()))
          .toList();

      return Ok(
        Snapshot.cached(
          models.map(toEntity).toList(growable: false),
          fetchedAt: entry.savedAt,
        ),
      );
    } catch (_) {
      await _cache.remove(key);
      return null;
    }
  }
}
