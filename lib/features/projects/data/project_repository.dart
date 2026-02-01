import 'package:cloud_firestore/cloud_firestore.dart';
import '../../projects/domain/financial_project_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository(this._firestore);

  // Collection Reference: users/{userId}/projects/{projectId}
  CollectionReference<Map<String, dynamic>> _projectsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('projects');
  }

  Future<void> createProject(String userId, FinancialProject project) async {
    await _projectsRef(userId).doc(project.id).set(project.toMap());
  }

  Future<void> updateProject(String userId, FinancialProject project) async {
    await _projectsRef(userId).doc(project.id).update(project.toMap());
  }

  Future<void> deleteProject(String userId, String projectId) async {
    await _projectsRef(userId).doc(projectId).delete();
  }

  Stream<List<FinancialProject>> watchProjects(String userId) {
    return _projectsRef(
      userId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FinancialProject.fromFirestore(doc))
          .toList();
    });
  }

  Future<FinancialProject?> getProject(String userId, String projectId) async {
    final doc = await _projectsRef(userId).doc(projectId).get();
    if (doc.exists) {
      return FinancialProject.fromFirestore(doc);
    }
    return null;
  }
}
