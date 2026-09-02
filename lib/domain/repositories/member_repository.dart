import '../../core/network/cancellation_token.dart';
import '../../core/result/result.dart';
import '../../core/result/snapshot.dart';
import '../entities/org_member.dart';
import '../entities/organization.dart';

abstract interface class MemberRepository {
  Future<Result<Snapshot<List<OrgMember>>>> getMembers({
    CancellationToken? cancelToken,
  });

  Future<Result<Organization>> getOrganization();
}
