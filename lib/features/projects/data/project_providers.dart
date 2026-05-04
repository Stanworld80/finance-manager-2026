import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/features/projects/data/project_repository.dart';
import '../../projects/domain/financial_project_model.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(firestoreProvider));
});

final projectsStreamProvider =
    StreamProvider.autoDispose<List<FinancialProject>>((ref) {
      final user = ref.watch(firebaseAuthProvider).currentUser;
      if (user == null) return Stream.value([]);
      return ref.read(projectRepositoryProvider).watchProjects(user.uid);
    });

final projectByIdProvider =
    Provider.family.autoDispose<AsyncValue<FinancialProject?>, String>((
      ref,
      projectId,
    ) {
      return ref.watch(projectsStreamProvider).whenData((projects) {
        return projects.where((p) => p.id == projectId).firstOrNull;
      });
    });
