/// Base exception for UI Market errors.
abstract class UIMarketException implements Exception {
  final String message;
  final String? details;

  const UIMarketException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return '$message\n$details';
    }
    return message;
  }
}

/// Exception for validation errors.
class ValidationException extends UIMarketException {
  final List<String> errors;

  ValidationException(super.message, {this.errors = const []});

  @override
  String toString() {
    if (errors.isEmpty) return message;
    final errorList = errors.map((e) => '  • $e').join('\n');
    return '$message\n$errorList';
  }
}

/// Exception for manifest parsing errors.
class ManifestException extends UIMarketException {
  const ManifestException(super.message, [super.details]);
}

/// Exception for registry errors.
class RegistryException extends UIMarketException {
  const RegistryException(super.message, [super.details]);
}

/// Exception for pack not found errors.
class PackNotFoundException extends UIMarketException {
  final String packId;

  PackNotFoundException(this.packId)
      : super(
          "Pack '$packId' not found in registry.",
          "Run 'ui_market search $packId' to find similar packs.",
        );
}

/// Exception for version conflict errors.
class VersionConflictException extends UIMarketException {
  final String packId;
  final String requiredVersion;
  final String? currentVersion;

  VersionConflictException({
    required this.packId,
    required this.requiredVersion,
    this.currentVersion,
  }) : super(
          "Version conflict for pack '$packId'",
          currentVersion != null
              ? "Pack requires Flutter $requiredVersion, but you have $currentVersion."
              : "Pack requires Flutter $requiredVersion.",
        );
}

/// Exception for dependency conflict errors.
class DependencyConflictException extends UIMarketException {
  final String dependency;
  final String requiredVersion;
  final String currentVersion;

  DependencyConflictException({
    required this.dependency,
    required this.requiredVersion,
    required this.currentVersion,
  }) : super(
          "Dependency conflict for '$dependency'",
          "Pack requires '$dependency: $requiredVersion', but your project uses '$currentVersion'. Resolve manually.",
        );
}

/// Exception for code validation errors.
class CodeValidationException extends UIMarketException {
  final String file;
  final int? line;
  final String violation;

  CodeValidationException({
    required this.file,
    this.line,
    required this.violation,
  }) : super(line != null ? "$file:$line - $violation" : "$file - $violation");
}

/// Exception for upload errors.
class UploadException extends UIMarketException {
  const UploadException(super.message, [super.details]);
}

/// Exception for duplicate version errors.
class DuplicateVersionException extends UIMarketException {
  final String packId;
  final String version;

  DuplicateVersionException({required this.packId, required this.version})
      : super(
          "Pack '$packId' version $version already exists.",
          "Increment version in ui_manifest.json to publish a new release.",
        );
}

/// Exception for configuration errors.
class ConfigException extends UIMarketException {
  const ConfigException(super.message, [super.details]);
}

/// Exception for file operation errors.
class FileOperationException extends UIMarketException {
  const FileOperationException(super.message, [super.details]);
}

/// Exception for network errors.
class NetworkException extends UIMarketException {
  final int? statusCode;

  NetworkException(String message, {this.statusCode, String? details})
      : super(message, details);
}
