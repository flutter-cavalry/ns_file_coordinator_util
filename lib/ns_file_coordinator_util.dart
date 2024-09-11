import 'dart:typed_data';

import 'ns_file_coordinator_util_platform_interface.dart';

class NsFileCoordinatorUtil {
  /// Reads an iCloud [srcUrl] file and copies it to [destUrl].
  Future<void> readFile(String srcUrl, String destUrl) {
    return NsFileCoordinatorUtilPlatform.instance.readFile(srcUrl, destUrl);
  }

  /// Reads an iCloud [srcUrl] file and returns a stream of [Uint8List].
  Future<Stream<Uint8List>> readFileAsync(String srcUrl,
      {int? bufferSize, double? debugDelay}) {
    return NsFileCoordinatorUtilPlatform.instance
        .readFileAsync(srcUrl, bufferSize: bufferSize, debugDelay: debugDelay);
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

  /// Copies [srcUrl] url to iCloud [dest].
  Future<void> copy(String srcUrl, String destUrl) {
    return NsFileCoordinatorUtilPlatform.instance.copy(srcUrl, destUrl);
  }

  /// Checks if the given iCloud [url] is a directory.
  /// Returns true if the url is a directory, or false if it's a file.
  /// `null` if the url doesn't exist.
  Future<bool?> isDirectory(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.isDirectory(url);
  }

  /// Creates a directory [url] like [mkdir -p].
  Future<void> mkdir(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.mkdir(url);
  }

  /// Checks if the directory [url] is empty.
  Future<bool> isEmptyDirectory(String url) async {
    return NsFileCoordinatorUtilPlatform.instance.isEmptyDirectory(url);
  }
}
