import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/org_member.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/member_repository.dart';
import '../state/async_list_notifier.dart';

class MemberProvider extends AsyncListNotifier<OrgMember>
    with SessionAwareNotifier<OrgMember> {
  MemberProvider(this._repository);

  final MemberRepository _repository;

  Map<String, OrgMember> _directory = const {};
  Organization? _organization;

  Organization? get organization => _organization;

  @override
  Future<Result<Snapshot<List<OrgMember>>>> fetch(
    CancellationToken cancelToken,
  ) {
    return _repository.getMembers(cancelToken: cancelToken);
  }

  @override
  void onLoaded(List<OrgMember> data) {
    _directory = {for (final member in data) member.userId: member};
  }

  AppUser? userById(String? userId) =>
      userId == null ? null : _directory[userId]?.user;

  OrgMember? memberById(String? userId) =>
      userId == null ? null : _directory[userId];

  bool isMember(String userId) => _directory.containsKey(userId);

  Future<void> loadOrganizationIfNeeded() async {
    if (_organization != null) return;

    final result = await _repository.getOrganization();
    final organization = result.valueOrNull;
    if (organization == null) return;

    _organization = organization;
    notifyListeners();
  }

  @override
  void onSessionCleared() {
    _organization = null;
    _directory = const {};
  }
}
