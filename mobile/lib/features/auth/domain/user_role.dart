enum UserRole {
  client,
  technician,
  admin;

  String toSnakeCase() {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.technician:
        return 'technician';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'technician':
        return UserRole.technician;
      case 'admin':
        return UserRole.admin;
      case 'client':
      default:
        return UserRole.client;
    }
  }

  String get labelFr {
    switch (this) {
      case UserRole.client:
        return 'Client';
      case UserRole.technician:
        return 'Technicien / Artisan';
      case UserRole.admin:
        return 'Administrateur';
    }
  }
}
