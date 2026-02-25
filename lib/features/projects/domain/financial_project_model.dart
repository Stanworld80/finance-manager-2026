import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus { active, archived }

class FinancialProject {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final DateTime? targetDate;
  final double targetBudget;
  final List<String>
  linkedVirtualAccountIds; // IDs of envelopes in this project
  final List<String> sharedWithUserIds;
  final ProjectStatus status;
  final DateTime createdAt;

  FinancialProject({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description = '',
    this.targetDate,
    this.targetBudget = 0.0,
    this.linkedVirtualAccountIds = const [],
    this.sharedWithUserIds = const [],
    this.status = ProjectStatus.active,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'targetDate': targetDate?.toIso8601String(),
      'targetBudget': targetBudget,
      'linkedVirtualAccountIds': linkedVirtualAccountIds,
      'sharedWithUserIds': sharedWithUserIds,
      'accessibleUserIds': [ownerId, ...sharedWithUserIds],
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FinancialProject.fromMap(Map<String, dynamic> map, String id) {
    return FinancialProject(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'])
          : null,
      targetBudget: (map['targetBudget'] ?? 0.0).toDouble(),
      linkedVirtualAccountIds: List<String>.from(
        map['linkedVirtualAccountIds'] ?? [],
      ),
      sharedWithUserIds: List<String>.from(map['sharedWithUserIds'] ?? []),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProjectStatus.active,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  factory FinancialProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinancialProject.fromMap(data, doc.id);
  }

  FinancialProject copyWith({
    String? name,
    String? description,
    DateTime? targetDate,
    double? targetBudget,
    List<String>? linkedVirtualAccountIds,
    ProjectStatus? status,
  }) {
    return FinancialProject(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      targetBudget: targetBudget ?? this.targetBudget,
      linkedVirtualAccountIds:
          linkedVirtualAccountIds ?? this.linkedVirtualAccountIds,
      sharedWithUserIds: sharedWithUserIds,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
