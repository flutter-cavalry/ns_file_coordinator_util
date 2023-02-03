[![pub package](https://img.shields.io/pub/v/ns_file_coordinator_util.svg)](https://pub.dev/packages/ns_file_coordinator_util)

Helper functions for `NSFileCoordinator` (iOS/macOS only).

## Usage

NOTE: this plugin doesn't automatically call `startAccessingSecurityScopedResource`. You can call it yourself with [accessing_security_scoped_resource](https://pub.dev/packages/accessing_security_scoped_resource);

```dart
/// Reads an iCloud [src] file and copies it to [dest].
Future<void> readFile(String src, String dest);

/// Gets the contents of an iCloud [src] directory and returns an array of [NsFileCoordinatorEntity].
Future<List<NsFileCoordinatorEntity>> listContents(String src);

/// Deletes the given iCloud path.
Future<void> delete(String src);

/// Moves [src] path to [dest].
Future<void> move(String src, String dest);

/// Copies [src] file to iCloud [dest].
Future<void> writeFile(String src, String dest);
```

Example:

```dart
final plugin = NsFileCoordinatorUtil();
await plugin.readFile(src, dest);
```
