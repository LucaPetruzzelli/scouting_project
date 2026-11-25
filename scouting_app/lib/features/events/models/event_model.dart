class EventModel {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String createdBy;
  final List<String> targetRoles;
  final List<String> targetBranches;
  final List<String> targetSquads;
  final List<String> targetUsers;
  final List<String> logisticsUserIds; // Gestito separatamente via event_logistics_members
  final String eventType;
  final double? fee;
  final bool hasGroups;
  final List<Map<String, dynamic>> groupsData;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    required this.createdBy,
    required this.targetRoles,
    required this.targetBranches,
    required this.targetSquads,
    required this.targetUsers,
    this.logisticsUserIds = const [],
    this.eventType = 'Riunione',
    this.fee,
    this.hasGroups = false,
    this.groupsData = const [],
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      location: json['location'] as String?,
      createdBy: json['created_by'] as String,
      targetRoles: List<String>.from(json['target_roles'] ?? []),
      targetBranches: List<String>.from(json['target_branches'] ?? []),
      targetSquads: List<String>.from(json['target_squads'] ?? []),
      targetUsers: List<String>.from(json['target_users'] ?? []),
      logisticsUserIds: List<String>.from(json['logistics_user_ids'] ?? []),
      eventType: json['event_type'] as String? ?? 'Riunione',
      fee: json['fee'] != null ? double.tryParse(json['fee'].toString()) : null,
      hasGroups: json['has_groups'] as bool? ?? false,
      groupsData: json['groups_data'] != null ? List<Map<String, dynamic>>.from(json['groups_data']) : [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'created_by': createdBy,
      'target_roles': targetRoles,
      'target_branches': targetBranches,
      'target_squads': targetSquads,
      'target_users': targetUsers,
      'event_type': eventType,
      'fee': fee,
      'has_groups': hasGroups,
      'groups_data': groupsData,
    };
  }

  /// Factory method to create event with logistics user IDs already loaded
  factory EventModel.withLogistics({
    required String id,
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
    required String createdBy,
    required List<String> targetRoles,
    required List<String> targetBranches,
    required List<String> targetSquads,
    required List<String> targetUsers,
    List<String> logisticsUserIds = const [],
    String eventType = 'Riunione',
    double? fee,
    bool hasGroups = false,
    List<Map<String, dynamic>> groupsData = const [],
    required DateTime createdAt,
  }) {
    return EventModel(
      id: id,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
      createdBy: createdBy,
      targetRoles: targetRoles,
      targetBranches: targetBranches,
      targetSquads: targetSquads,
      targetUsers: targetUsers,
      logisticsUserIds: logisticsUserIds,
      eventType: eventType,
      fee: fee,
      hasGroups: hasGroups,
      groupsData: groupsData,
      createdAt: createdAt,
    );
  }

  /// Check if a user is a logistics member for this event
  bool isLogisticsMember(String userId) => logisticsUserIds.contains(userId);
}
