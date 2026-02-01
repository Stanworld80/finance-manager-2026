import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_manager_2026/core/providers.dart';
import 'package:finance_manager_2026/features/projects/data/project_providers.dart';
import '../../projects/domain/financial_project_model.dart';
import 'package:uuid/uuid.dart';

class ProjectService {
  final Ref ref;

  ProjectService(this.ref);

  Future<void> createProject({
    required String name,
    required String description,
    required double targetBudget,
    DateTime? targetDate,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");

    final project = FinancialProject(
      id: const Uuid().v4(),
      ownerId: user.uid,
      name: name,
      description: description,
      targetBudget: targetBudget,
      targetDate: targetDate,
    );

    await ref.read(projectRepositoryProvider).createProject(user.uid, project);
  }

  Future<void> updateProject(FinancialProject project) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");
    await ref.read(projectRepositoryProvider).updateProject(user.uid, project);
  }

  Future<void> deleteProject(String projectId) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception("User not authenticated");
    await ref
        .read(projectRepositoryProvider)
        .deleteProject(user.uid, projectId);
  }

  Future<void> addEnvelopeToProject(
    FinancialProject project,
    String envelopeId,
  ) async {
    if (project.linkedVirtualAccountIds.contains(envelopeId)) return;

    final updatedList = [...project.linkedVirtualAccountIds, envelopeId];
    final updatedProject = project.copyWith(
      linkedVirtualAccountIds: updatedList,
    );

    await updateProject(updatedProject);
  }

  Future<void> removeEnvelopeFromProject(
    FinancialProject project,
    String envelopeId,
  ) async {
    final updatedList = project.linkedVirtualAccountIds
        .where((id) => id != envelopeId)
        .toList();
    final updatedProject = project.copyWith(
      linkedVirtualAccountIds: updatedList,
    );

    await updateProject(updatedProject);
  }
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(ref);
});
