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

final projectByIdProvider = StreamProvider.family.autoDispose<FinancialProject?, String>((
  ref,
  projectId,
) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);

  // Re-using the list stream to avoid multiple listeners or fetch specifically if needed
  // For simplicity watching the specific document might be better if detailed view opens efficiently
  // But given standard usage, filtering the list is often responsive enough for small datasets
  // However, let's implement a specific stream or future fetch if we had it in repo.
  // Repo only has watchProjects (all). So we can derived it:

  return ref.watch(projectsStreamProvider.stream).map((projects) {
    return projects.where((p) => p.id == projectId).firstOrNull;
  });
});
