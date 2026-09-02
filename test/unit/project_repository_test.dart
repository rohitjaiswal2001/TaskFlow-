import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/config/simulation_settings.dart';
import 'package:taskflow/core/errors/api_exception.dart';
import 'package:taskflow/core/errors/failure.dart';
import 'package:taskflow/data/dto/project_dto.dart';
import 'package:taskflow/domain/entities/project.dart';
import 'package:taskflow/domain/repositories/project_repository.dart';

import '../support/test_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestBackend backend;

  setUp(() async => backend = await TestBackend.create());
  tearDown(() => backend.dispose());

  group('org scoping', () {
    test('a user only sees their own organization projects', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      final nimbus = await backend.projectRepository.getProjects();

      expect(nimbus.valueOrNull!.value.map((p) => p.name), [
        'Mobile App v2',
        'Website Relaunch',
      ]);

      await backend.authRepository.logout();
      await backend.signIn(TestAccounts.orgBAdmin);
      final harborlight = await backend.projectRepository.getProjects();

      expect(harborlight.valueOrNull!.value.map((p) => p.name), [
        'Client Onboarding Revamp',
      ]);
    });

    test('another org project is a 404, not a 403', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      final result = await backend.projectRepository.getProject('proj_1003');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('an unknown id is a not-found failure', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      final result = await backend.projectRepository.getProject(
        'proj_does_not_exist',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('task counts are derived, not trusted from the stored row', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      final projects = await backend.projectRepository.getProjects();

      final relaunch = projects.valueOrNull!.value.firstWhere(
        (project) => project.id == 'proj_1001',
      );

      expect(relaunch.taskCount, 6);
    });
  });

  group('authorization', () {
    test('an admin can create, edit and delete', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      final created = await backend.projectRepository.createProject(
        const ProjectDraft(name: 'Design System', description: 'Shared UI kit'),
      );
      final project = created.valueOrNull!;
      expect(project.taskCount, 0);
      expect(project.orgId, 'org_a1b2c3');

      final edited = await backend.projectRepository.updateProject(
        project.id,
        const ProjectDraft(
          name: 'Design System v2',
          description: 'Shared UI kit',
          status: ProjectStatus.archived,
        ),
      );
      expect(edited.valueOrNull!.name, 'Design System v2');
      expect(edited.valueOrNull!.status, ProjectStatus.archived);

      final deleted = await backend.projectRepository.deleteProject(project.id);
      expect(deleted.isOk, isTrue);

      final after = await backend.projectRepository.getProjects();
      expect(after.valueOrNull!.value.any((p) => p.id == project.id), isFalse);
    });

    test('a member is refused by the business logic layer', () async {
      await backend.signIn(TestAccounts.orgAMember);

      final create = await backend.projectRepository.createProject(
        const ProjectDraft(name: 'Sneaky', description: 'Should not exist'),
      );
      final delete = await backend.projectRepository.deleteProject('proj_1001');

      expect(create.failureOrNull, isA<PermissionFailure>());
      expect(delete.failureOrNull, isA<PermissionFailure>());
    });

    test(
      'the simulated backend refuses a member even if the UI guard is bypassed',
      () async {
        await backend.signIn(TestAccounts.orgAMember);

        expect(
          () => backend.api.deleteProject('proj_1001'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
          ),
        );

        expect(
          () => backend.api.createProject(
            const CreateProjectRequest(
              name: 'Sneaky',
              description: '',
              status: 'active',
            ),
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
          ),
        );
      },
    );

    test('deleting a project takes its tasks with it', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      await backend.projectRepository.deleteProject('proj_1001');
      final tasks = await backend.taskRepository.getTasks();

      expect(
        tasks.valueOrNull!.value.any((task) => task.projectId == 'proj_1001'),
        isFalse,
      );
    });
  });

  group('validation and simulated failures', () {
    test('a name containing #invalid comes back as a field error', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      final result = await backend.projectRepository.createProject(
        const ProjectDraft(name: 'Broken #invalid', description: 'nope'),
      );

      final failure = result.failureOrNull;
      expect(failure, isA<ValidationFailure>());
      expect((failure! as ValidationFailure).fieldErrors, contains('name'));
    });

    test('a name containing #500 surfaces a server failure', () async {
      await backend.signIn(TestAccounts.orgAAdmin);

      final result = await backend.projectRepository.createProject(
        const ProjectDraft(name: 'Kaboom #500', description: 'nope'),
      );

      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('an armed fault fails exactly one request', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      backend.simulation.setFault(SimulatedFault.serverError);

      final first = await backend.projectRepository.getProjects();
      final second = await backend.projectRepository.getProjects();

      expect(first.failureOrNull, isA<ServerFailure>());
      expect(second.isOk, isTrue);
    });
  });

  group('offline', () {
    test('falls back to the cached copy and marks it stale', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      final online = await backend.projectRepository.getProjects();
      expect(online.valueOrNull!.isStale, isFalse);

      backend.simulation.setOffline(true);
      final offline = await backend.projectRepository.getProjects();

      expect(offline.isOk, isTrue);
      expect(offline.valueOrNull!.isStale, isTrue);
      expect(
        offline.valueOrNull!.value.map((p) => p.id),
        online.valueOrNull!.value.map((p) => p.id),
      );
    });

    test('reports the offline failure when nothing was cached first', () async {
      await backend.signIn(TestAccounts.orgAAdmin);
      backend.simulation.setOffline(true);

      final result = await backend.projectRepository.getProjects();

      expect(result.failureOrNull, isA<OfflineFailure>());
    });
  });
}
