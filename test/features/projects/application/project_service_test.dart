import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/features/projects/application/project_service.dart';
import 'package:finance_manager_2026/features/projects/data/project_providers.dart';
import 'package:finance_manager_2026/features/projects/data/project_repository.dart';
import 'package:finance_manager_2026/features/projects/domain/financial_project_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'project_service_test.mocks.dart';

@GenerateMocks([ProjectRepository, User, FirebaseAuth])
void main() {
  late MockProjectRepository mockProjectRepository;
  late MockUser mockUser;
  late MockFirebaseAuth mockFirebaseAuth;
  late ProviderContainer container;

  setUp(() {
    mockProjectRepository = MockProjectRepository();
    mockUser = MockUser();
    mockFirebaseAuth = MockFirebaseAuth();

    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-id');

    container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(mockProjectRepository),
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ProjectService', () {
    test('createProject creates a project via repository', () async {
      final service = container.read(projectServiceProvider);

      when(
        mockProjectRepository.createProject(any, any),
      ).thenAnswer((_) async {});

      await service.createProject(
        name: 'Test Project',
        description: 'Test Desc',
        targetBudget: 1000.0,
      );

      verify(
        mockProjectRepository.createProject(
          'test-user-id',
          argThat(
            predicate<FinancialProject>(
              (p) => p.name == 'Test Project' && p.targetBudget == 1000.0,
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'addEnvelopeToProject updates project with new linked account',
      () async {
        final service = container.read(projectServiceProvider);
        final project = FinancialProject(
          id: 'p1',
          ownerId: 'test-user-id',
          name: 'Project 1',
          linkedVirtualAccountIds: [],
        );

        when(
          mockProjectRepository.updateProject(any, any),
        ).thenAnswer((_) async {});

        await service.addEnvelopeToProject(project, 'env1');

        verify(
          mockProjectRepository.updateProject(
            'test-user-id',
            argThat(
              predicate<FinancialProject>(
                (p) => p.linkedVirtualAccountIds.contains('env1'),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('removeEnvelopeFromProject removes linked account', () async {
      final service = container.read(projectServiceProvider);
      final project = FinancialProject(
        id: 'p1',
        ownerId: 'test-user-id',
        name: 'Project 1',
        linkedVirtualAccountIds: ['env1', 'env2'],
      );

      when(
        mockProjectRepository.updateProject(any, any),
      ).thenAnswer((_) async {});

      await service.removeEnvelopeFromProject(project, 'env1');

      verify(
        mockProjectRepository.updateProject(
          'test-user-id',
          argThat(
            predicate<FinancialProject>(
              (p) =>
                  !p.linkedVirtualAccountIds.contains('env1') &&
                  p.linkedVirtualAccountIds.contains('env2'),
            ),
          ),
        ),
      ).called(1);
    });
  });
}
