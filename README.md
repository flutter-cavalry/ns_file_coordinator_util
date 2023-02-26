[![pub package](https://img.shields.io/pub/v/ns_file_coordinator_util.svg)](https://pub.dev/packages/ns_file_coordinator_util)

Helper functions for `NSFileCoordinator` (iOS/macOS only).

## Usage

NOTE: this plugin doesn't automatically call `startAccessingSecurityScopedResource`. You can call it yourself with [accessing_security_scoped_resource](https://pub.dev/packages/accessing_security_scoped_resource);

```dart
/// Reads an iCloud [src] file and copies it to [dest].
Future<void> readFile(Uri src, Uri dest);

/// Returns information about the given [path].
Future<NsFileCoordinatorEntity> stat(Uri path);

/// Gets the contents of an iCloud directory [path] and returns an array of [NsFileCoordinatorEntity].
///
/// [recursive] whether to list subdirectories recursively.
/// [filesOnly] return files only.
Future<List<NsFileCoordinatorEntity>> listContents(Uri path,
    {bool? recursive, bool? filesOnly});

/// Deletes the given iCloud [path].
Future<void> delete(Uri path);

/// Moves [src] path to [dest].
Future<void> move(Uri src, Uri dest);

/// Copies [src] path to iCloud [dest].
Future<void> copy(Uri src, Uri dest);

/// Checks if the given iCloud [path] is a directory.
/// Returns true if the path is a directory, or false if it's a file.
/// `null` if the path doesn't exist.
Future<bool?> isDirectory(Uri path);

/// Creates a directory [path] like [mkdir -p].
Future<void> mkdir(Uri path);

/// Checks if the directory [path] is empty.
Future<bool> isEmptyDirectory(Uri path);
```

Example:

```dart
final plugin = NsFileCoordinatorUtil();
await plugin.readFile(src, dest);
```
