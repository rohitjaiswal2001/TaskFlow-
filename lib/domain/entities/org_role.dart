enum OrgRole {
  orgAdmin('org_admin', 'Admin'),
  member('member', 'Member');

  const OrgRole(this.wireName, this.label);

  final String wireName;
  final String label;

  static OrgRole fromWire(String? value) => OrgRole.values.firstWhere(
    (role) => role.wireName == value,
    orElse: () => OrgRole.member,
  );

  bool get isAdmin => this == OrgRole.orgAdmin;
}
