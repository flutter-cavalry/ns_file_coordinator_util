[![pub package](https://img.shields.io/pub/v/ns_file_coordinator_util.svg)](https://pub.dev/packages/ns_file_coordinator_util)

Helper functions for `NSFileCoordinator` (iOS/macOS only).

## Usage

NOTE: this plugin doesn't automatically call `startAccessingSecurityScopedResource`. You can call it yourself with [accessing_security_scoped_resource](https://pub.dev/packages/accessing_security_scoped_resource);

```dart
/// Reads an iCloud [srcUrl] file and copies it to [destUrl].
Future<void> readFile(String srcUrl, String destUrl);

/// Returns information about the given [url].
Future<NsFileCoordinatorEntity> stat(String url);

/// Gets the contents of an iCloud directory [url] and returns an array of [NsFileCoordinatorEntity].
///
/// [recursive] whether to list subdirectories recursively.
/// [filesOnly] return files only.
Future<List<NsFileCoordinatorEntity>> listContents(String url,
    {bool? recursive, bool? filesOnly});

/// Deletes the given iCloud [url].
Future<void> delete(String url);

/// Moves [srcUrl] url to [destUrl].
Future<void> move(String srcUrl, String destUrl);

/// Copies [srcUrl] url to iCloud [destUrl].
Future<void> copy(String srcUrl, String destUrl);

/// Checks if the given iCloud [url] is a directory.
/// Returns true if the url is a directory, or false if it's a file.
/// `null` if the url doesn't exist.
Future<bool?> isDirectory(String url);

/// Creates a directory [url] like [mkdir -p].
Future<void> mkdir(String url);

/// Checks if the directory [url] is empty.
Future<bool> isEmptyDirectory(String url);
```

Example:

```dart
final plugin = NsFileCoordinatorUtil();
await plugin.readFile(src, dest);
```
