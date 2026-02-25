import 'package:cloud_firestore/cloud_firestore.dart';
import '../../projects/domain/financial_project_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository(this._firestore);

  // Collection Reference: projects/{projectId}
  CollectionReference<Map<String, dynamic>> get _projectsRef {
    return _firestore.collection('projects');
  }

  Future<void> createProject(String userId, FinancialProject project) async {
    // Ensuring the accessible user logic aligns with new architecture
    final data = project.toMap();
    await _projectsRef.doc(project.id).set(data);
  }

  Future<void> updateProject(String userId, FinancialProject project) async {
    await _projectsRef.doc(project.id).update(project.toMap());
  }

  Future<void> deleteProject(String userId, String projectId) async {
    await _projectsRef.doc(projectId).delete();
  }

  Stream<List<FinancialProject>> watchProjects(String userId) {
    return _projectsRef
        .where('accessibleUserIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FinancialProject.fromFirestore(doc))
              .toList();
        });
  }

  Future<FinancialProject?> getProject(String userId, String projectId) async {
    final doc = await _projectsRef.doc(projectId).get();
    if (doc.exists) {
      return FinancialProject.fromFirestore(doc);
    }
    return null;
  }
}
