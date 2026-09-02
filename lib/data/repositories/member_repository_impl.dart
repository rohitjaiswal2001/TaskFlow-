import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/local/cache_store.dart';
import '../datasources/remote/api_call_runner.dart';
import '../datasources/remote/taskflow_api.dart';
import '../dto/member_dto.dart';
import '../session/session_manager.dart';
import 'cache_fallback.dart';

class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl({
    required TaskFlowApi remoteApi,
    required ApiCallRunner callRunner,
    required SessionManager sessionManager,
    required CacheFallback cacheFallback,
  }) : _api = remoteApi,
       _run = callRunner,
       _session = sessionManager,
       _cache = cacheFallback;

  final TaskFlowApi _api;
  final ApiCallRunner _run;
  final SessionManager _session;
  final CacheFallback _cache;

  @override
  Future<Result<Snapshot<List<OrgMember>>>> getMembers({
    CancellationToken? cancelToken,
  }) {
    final session = _session.requireCurrent;

    return _cache.load<OrgMember, MemberResponse>(
      key: CacheKeys.members(session.orgId),
      fetch: () async {
        final response = await _run.run(
          () => _api.getMembers(cancelToken: cancelToken),
        );
        return response.data;
      },
      encode: (model) => model.toJson(),
      decode: MemberResponse.fromJson,
      toEntity: (model) => model.toEntity(),
    );
  }

  @override
  Future<Result<Organization>> getOrganization() {
    return Result.guard(() async {
      final response = await _run.run(() => _api.getOrganization());
      return response.data.toEntity();
    });
  }
}
