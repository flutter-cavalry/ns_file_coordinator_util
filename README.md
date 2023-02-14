[![pub package](https://img.shields.io/pub/v/ns_file_coordinator_util.svg)](https://pub.dev/packages/ns_file_coordinator_util)

Helper functions for `NSFileCoordinator` (iOS/macOS only).

## Usage

NOTE: this plugin doesn't automatically call `startAccessingSecurityScopedResource`. You can call it yourself with [accessing_security_scoped_resource](https://pub.dev/packages/accessing_security_scoped_resource);

```dart
/// Reads an iCloud [src] file and copies it to [dest].
Future<void> readFile(String src, String dest);

/// Gets the contents of an iCloud directory [path] and returns an array of [NsFileCoordinatorEntity].
///
/// [recursive] whether to list subdirectories recursively.
/// [filesOnly] return files only.
Future<List<NsFileCoordinatorEntity>> listContents(String path);

/// Deletes the given iCloud [path].
Future<void> delete(String path) async;

/// Moves [src] path to [dest].
Future<void> move(String src, String dest);

/// Copies [src] path to iCloud [dest].
Future<void> copy(String src, String dest);

/// Checks if the given iCloud [path] exists.
/// Returns true if the path is a directory, or false for files. `null` if
/// the path doesn't exist.
Future<bool?> entityType(String path) async;

/// Creates a directory [path] like [mkdir -p].
Future<void> mkdir(String path) async;

/// Checks if the directory [path] is empty.
Future<void> isEmptyDirectory(String path);
```

Example:

```dart
final plugin = NsFileCoordinatorUtil();
await plugin.readFile(src, dest);
```
