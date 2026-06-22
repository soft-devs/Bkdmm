import 'dart:convert';

/// Data migration service - Handles version-to-version data transformations
///
/// Provides a migration system for upgrading older project file formats
/// to newer versions while preserving data integrity.
class DataMigrationService {
  /// List of registered migrations sorted by version
  final List<DataMigration> _migrations = [];

  /// Current data format version
  static const String currentVersion = '1.0.0';

  /// Register a migration
  void registerMigration(DataMigration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => _compareVersions(a.fromVersion, b.fromVersion));
  }

  /// Get all registered migrations
  List<DataMigration> get migrations => List.unmodifiable(_migrations);

  /// Migrate data to current version
  ///
  /// Takes a JSON map and applies all necessary migrations to bring
  /// it to the current version.
  Map<String, dynamic> migrateToCurrent(Map<String, dynamic> data) {
    final dataVersion = _extractVersion(data);
    return migrate(data, fromVersion: dataVersion);
  }

  /// Migrate data to a specific target version
  Map<String, dynamic> migrate(
    Map<String, dynamic> data, {
    String? fromVersion,
  }) {
    final startVersion = fromVersion ?? _extractVersion(data);
    var currentData = Map<String, dynamic>.from(data);

    for (final migration in _migrations) {
      if (_compareVersions(migration.fromVersion, startVersion) >= 0) {
        currentData = migration.migrate(currentData);
      }
    }

    // Ensure version is updated
    currentData['version'] = currentVersion;
    return currentData;
  }

  /// Check if migration is needed
  bool needsMigration(Map<String, dynamic> data) {
    final dataVersion = _extractVersion(data);
    return _compareVersions(dataVersion, currentVersion) < 0;
  }

  /// Get required migrations for a version
  List<DataMigration> getRequiredMigrations(String fromVersion) {
    return _migrations
        .where((m) => _compareVersions(m.fromVersion, fromVersion) >= 0)
        .toList();
  }

  /// Extract version from data
  String _extractVersion(Map<String, dynamic> data) {
    return data['version'] as String? ?? '0.9.0';
  }

  /// Compare two semantic versions
  ///
  /// Returns:
  /// - negative if v1 < v2
  /// - 0 if v1 == v2
  /// - positive if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    // Normalize to 3 parts
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (var i = 0; i < 3; i++) {
      if (parts1[i] != parts2[i]) {
        return parts1[i].compareTo(parts2[i]);
      }
    }
    return 0;
  }
}

/// Abstract migration class
///
/// Extend this class to create specific version migrations.
abstract class DataMigration {
  /// The version this migration migrates FROM
  String get fromVersion;

  /// The version this migration migrates TO
  String get toVersion;

  /// Human-readable description of this migration
  String get description;

  /// Execute the migration
  ///
  /// Takes the original data and returns the migrated data.
  Map<String, dynamic> migrate(Map<String, dynamic> data);
}

/// Migration from version 0.9.0 to 1.0.0
///
/// This migration handles the initial version upgrade with:
/// - Adding missing required fields with defaults
/// - Converting old field formats
/// - Restructuring data type definitions
class Migration_0_9_0_to_1_0_0 extends DataMigration {
  @override
  String get fromVersion => '0.9.0';

  @override
  String get toVersion => '1.0.0';

  @override
  String get description =>
      'Initial migration from legacy format to version 1.0.0';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);

    // Ensure version is set
    migrated['version'] = toVersion;

    // Add profile if missing
    if (!migrated.containsKey('profile')) {
      migrated['profile'] = {
        'defaultFields': <String>[],
        'defaultFieldsType': '1',
        'defaultDatabase': null,
        'settings': <String, dynamic>{},
      };
    }

    // Add dataTypeDomains if missing
    if (!migrated.containsKey('dataTypeDomains')) {
      migrated['dataTypeDomains'] = {
        'datatype': _getDefaultDataTypes(),
        'database': <dynamic>[],
      };
    }

    // Migrate modules
    if (migrated.containsKey('modules')) {
      final modules = migrated['modules'] as List<dynamic>;
      migrated['modules'] = modules.map((module) {
        final moduleMap = Map<String, dynamic>.from(module as Map);

        // Add graphCanvas if missing
        if (!moduleMap.containsKey('graphCanvas')) {
          moduleMap['graphCanvas'] = {
            'nodes': <dynamic>[],
            'edges': <dynamic>[],
            'viewport': null,
          };
        }

        // Migrate entities
        if (moduleMap.containsKey('entities')) {
          final entities = moduleMap['entities'] as List<dynamic>;
          moduleMap['entities'] = entities.map((entity) {
            final entityMap = Map<String, dynamic>.from(entity as Map);

            // Ensure timestamps
            if (!entityMap.containsKey('createdAt')) {
              entityMap['createdAt'] = DateTime.now().toIso8601String();
            }
            if (!entityMap.containsKey('updatedAt')) {
              entityMap['updatedAt'] = DateTime.now().toIso8601String();
            }

            // Ensure indexes array exists
            if (!entityMap.containsKey('indexes')) {
              entityMap['indexes'] = <dynamic>[];
            }

            // Migrate fields
            if (entityMap.containsKey('fields')) {
              final fields = entityMap['fields'] as List<dynamic>;
              entityMap['fields'] = fields.map((field) {
                final fieldMap = Map<String, dynamic>.from(field as Map);

                // Ensure required field properties
                if (!fieldMap.containsKey('pk')) {
                  fieldMap['pk'] = false;
                }
                if (!fieldMap.containsKey('notNull')) {
                  fieldMap['notNull'] = false;
                }
                if (!fieldMap.containsKey('autoIncrement')) {
                  fieldMap['autoIncrement'] = false;
                }

                return fieldMap;
              }).toList();
            }

            return entityMap;
          }).toList();
        }

        return moduleMap;
      }).toList();
    }

    // Ensure versionHistory exists
    if (!migrated.containsKey('versionHistory')) {
      migrated['versionHistory'] = <dynamic>[];
    }

    // Ensure timestamps
    if (!migrated.containsKey('createdAt')) {
      migrated['createdAt'] = DateTime.now().toIso8601String();
    }
    if (!migrated.containsKey('updatedAt')) {
      migrated['updatedAt'] = DateTime.now().toIso8601String();
    }

    return migrated;
  }

  List<Map<String, dynamic>> _getDefaultDataTypes() {
    return [
      {
        'id': '1',
        'name': 'IdOrKey',
        'chnname': 'Identifier Key',
        'apply': {'MYSQL': 'VARCHAR(32)'},
      },
      {
        'id': '2',
        'name': 'Name',
        'chnname': 'Name',
        'apply': {'MYSQL': 'VARCHAR(128)'},
      },
      {
        'id': '3',
        'name': 'Intro',
        'chnname': 'Introduction',
        'apply': {'MYSQL': 'VARCHAR(512)'},
      },
      {
        'id': '4',
        'name': 'LongText',
        'chnname': 'Long Text',
        'apply': {'MYSQL': 'TEXT'},
      },
      {
        'id': '5',
        'name': 'Integer',
        'chnname': 'Integer',
        'apply': {'MYSQL': 'INT'},
      },
      {
        'id': '6',
        'name': 'Long',
        'chnname': 'Long Integer',
        'apply': {'MYSQL': 'BIGINT'},
      },
      {
        'id': '7',
        'name': 'Money',
        'chnname': 'Money',
        'apply': {'MYSQL': 'DECIMAL(32,8)'},
      },
      {
        'id': '8',
        'name': 'DateTime',
        'chnname': 'Date Time',
        'apply': {'MYSQL': 'DATETIME'},
      },
      {
        'id': '9',
        'name': 'YesNo',
        'chnname': 'Yes/No',
        'apply': {'MYSQL': 'VARCHAR(1)'},
      },
      {
        'id': '10',
        'name': 'Dict',
        'chnname': 'Dictionary',
        'apply': {'MYSQL': 'VARCHAR(32)'},
      },
    ];
  }
}

/// Migration that renames fields
class FieldRenameMigration extends DataMigration {
  @override
  String get fromVersion => '1.0.0';

  @override
  String get toVersion => '1.1.0';

  @override
  String get description => 'Renames fields for consistency';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);
    migrated['version'] = toVersion;

    // Example: rename 'chnname' to 'displayName' if needed in future versions
    // This is a placeholder for future migrations

    return migrated;
  }
}

/// Migration that adds new default fields
class DefaultFieldsMigration extends DataMigration {
  @override
  String get fromVersion => '1.1.0';

  @override
  String get toVersion => '1.2.0';

  @override
  String get description => 'Adds new default fields to profile';

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);
    migrated['version'] = toVersion;

    // Example: add new profile settings
    final profile = migrated['profile'] as Map<String, dynamic>?;
    if (profile != null && !profile.containsKey('autoSaveInterval')) {
      profile['autoSaveInterval'] = 30000; // 30 seconds
    }

    return migrated;
  }
}

/// Pre-configured migration service with all built-in migrations
class DefaultDataMigrationService extends DataMigrationService {
  DefaultDataMigrationService() {
    // Register all built-in migrations
    registerMigration(Migration_0_9_0_to_1_0_0());
    // Future migrations can be added here:
    // registerMigration(FieldRenameMigration());
    // registerMigration(DefaultFieldsMigration());
  }
}

/// Utility class for data version operations
class DataVersionUtils {
  DataVersionUtils._();

  /// Parse version string to parts
  static List<int> parseVersion(String version) {
    return version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  /// Compare two versions
  static int compareVersions(String v1, String v2) {
    final parts1 = parseVersion(v1);
    final parts2 = parseVersion(v2);

    // Normalize to 3 parts
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (var i = 0; i < 3; i++) {
      if (parts1[i] != parts2[i]) {
        return parts1[i].compareTo(parts2[i]);
      }
    }
    return 0;
  }

  /// Check if version is valid semantic version
  static bool isValidVersion(String version) {
    final parts = version.split('.');
    if (parts.length < 2 || parts.length > 3) return false;

    for (final part in parts) {
      if (int.tryParse(part) == null) return false;
    }
    return true;
  }

  /// Increment version (patch, minor, or major)
  static String incrementVersion(String version, {VersionIncrement increment = VersionIncrement.patch}) {
    final parts = parseVersion(version);
    while (parts.length < 3) parts.add(0);

    switch (increment) {
      case VersionIncrement.patch:
        parts[2]++;
        break;
      case VersionIncrement.minor:
        parts[1]++;
        parts[2] = 0;
        break;
      case VersionIncrement.major:
        parts[0]++;
        parts[1] = 0;
        parts[2] = 0;
        break;
    }

    return parts.join('.');
  }
}

/// Version increment types
enum VersionIncrement {
  patch,
  minor,
  major,
}

/// Migration result with details
class MigrationResult {
  final bool success;
  final String? error;
  final String fromVersion;
  final String toVersion;
  final List<String> appliedMigrations;
  final Map<String, dynamic> data;

  MigrationResult({
    required this.success,
    this.error,
    required this.fromVersion,
    required this.toVersion,
    required this.appliedMigrations,
    required this.data,
  });

  factory MigrationResult.success({
    required String fromVersion,
    required String toVersion,
    required List<String> appliedMigrations,
    required Map<String, dynamic> data,
  }) {
    return MigrationResult(
      success: true,
      fromVersion: fromVersion,
      toVersion: toVersion,
      appliedMigrations: appliedMigrations,
      data: data,
    );
  }

  factory MigrationResult.error({
    required String fromVersion,
    required String error,
    required Map<String, dynamic> data,
  }) {
    return MigrationResult(
      success: false,
      error: error,
      fromVersion: fromVersion,
      toVersion: fromVersion,
      appliedMigrations: [],
      data: data,
    );
  }
}