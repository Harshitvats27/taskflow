class OrgMemberModel {
  final String orgId;
  final String userId;
  final String role;

  const OrgMemberModel({
    required this.orgId,
    required this.userId,
    required this.role,
  });

  factory OrgMemberModel.fromJson(Map<String, dynamic> json) {
    return OrgMemberModel(
      orgId: json['org_id'],
      userId: json['user_id'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'org_id': orgId,
      'user_id': userId,
      'role': role,
    };
  }
}