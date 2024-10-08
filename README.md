# ns_file_coordinator_util

[![pub package](https://img.shields.io/pub/v/ns_file_coordinator_util.svg)](https://pub.dev/packages/ns_file_coordinator_util)

A Flutter plugin to call iOS/macOS `NSFileCoordinator` APIs.

## Usage

NOTE: this plugin doesn't automatically call `startAccessingSecurityScopedResource`. You can call it yourself with [accessing_security_scoped_resource](https://pub.dev/packages/accessing_security_scoped_resource);

```dart
class NsFileCoordinatorUtil {
  /// Reads an iCloud [srcUrl] file and return a [Uint8List].
  ///
  /// [start] and [count] are optional parameters to read only a part of the file.
  Future<Uint8List> readFileSync(String srcUrl, {int? start, int? count}) {
    return NsFileCoordinatorUtilPlatform.instance
        .readFileSync(srcUrl, start: start, count: count);
  }

  /// Writes the specified [data] to the iCloud [destUrl] file.
  Future<void> writeFile(String destUrl, Uint8List data) {
    return NsFileCoordinatorUtilPlatform.instance.writeFile(destUrl, data);
  }

  /// Reads an iCloud [srcUrl] file and returns a stream of [Uint8List].
  Future<Stream<Uint8List>> readFileStream(String srcUrl,
      {int? bufferSize, double? debugDelay, int? start}) {
    return NsFileCoordinatorUtilPlatform.instance.readFileStream(srcUrl,
        bufferSize: bufferSize, debugDelay: debugDelay, start: start);
  }

  /// Returns information about the given [url].
  Future<NsFileCoordinatorEntity?> stat(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.stat(url);
  }

  /// Gets the contents of an iCloud directory [url] and returns an array of [NsFileCoordinatorEntity].
  ///
  /// [recursive] whether to list subdirectories recursively.
  /// [filesOnly] return files only.
  /// [relativePathInfo] return relative path info.
  Future<List<NsFileCoordinatorEntity>> listContents(String url,
      {bool? recursive, bool? filesOnly, bool? relativePathInfo}) async {
    return NsFileCoordinatorUtilPlatform.instance.listContents(url,
        recursive: recursive,
        filesOnly: filesOnly,
        relativePathInfo: relativePathInfo);
  }

  /// Returns all files in the given iCloud directory [url] and returns an array of [NsFileCoordinatorFileURL]. Faster than [listContents] if you only need file URLs.
  Future<List<NsFileCoordinatorFileURL>> listContentFiles(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.listContentFiles(
      url,
    );
  }

  /// Deletes the given iCloud [url].
  Future<void> delete(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.delete(url);
  }

  /// Moves [srcUrl] url to [destUrl].
  Future<void> move(String srcUrl, String destUrl) {
    return NsFileCoordinatorUtilPlatform.instance.move(srcUrl, destUrl);
  }

  /// Copies [srcUrl] url to iCloud [destUrl].
  ///
  /// [overwrite] whether to overwrite the destination file if it already exists.
  Future<void> copyPath(String srcUrl, String destUrl, {bool? overwrite}) {
    return NsFileCoordinatorUtilPlatform.instance
        .copyPath(srcUrl, destUrl, overwrite: overwrite);
  }

  /// Checks if the given iCloud [url] is a directory.
  /// Returns true if the url is a directory, or false if it's a file.
  /// `null` if the url doesn't exist.
  Future<bool?> isDirectory(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.isDirectory(url);
  }

  /// Creates a directory [url] like `mkdir -p`.
  Future<String> mkdirp(String url, List<String> components) async {
    return NsFileCoordinatorUtilPlatform.instance.mkdirp(url, components);
  }

  /// Checks if the directory [url] is empty.
  Future<bool> isEmptyDirectory(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.isEmptyDirectory(url);
  }

  /// Returns a session ID. Call [writeChunk] with the returned session to
  /// write data into the destination stream. Call [endWriteStream] to close
  /// the destination stream.
  Future<int> startWriteStream(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.startWriteStream(url);
  }

  /// Writes the given [data] to an out stream identified by the given [session].
  Future<void> writeChunk(int session, Uint8List data) async {
    return NsFileCoordinatorUtilPlatform.instance.writeChunk(session, data);
  }

  /// Closes an out stream identified by the given [session].
  Future<void> endWriteStream(int session) async {
    return NsFileCoordinatorUtilPlatform.instance.endWriteStream(session);
  }

  /// Returns a list of pending writing sessions.
  Future<List<int>> getPendingWritingSessions() async {
    return NsFileCoordinatorUtilPlatform.instance.getPendingWritingSessions();
  }
}
```
