import 'ns_file_coordinator_util_platform_interface.dart';

class NsFileCoordinatorUtil {
  /// Reads an iCloud [srcUrl] file and copies it to [destUrl].
  Future<void> readFile(String srcUrl, String destUrl, {bool scoped = true}) {
    return NsFileCoordinatorUtilPlatform.instance
        .readFile(srcUrl, destUrl, scoped: scoped);
  }

  /// Returns information about the given [url].
  Future<NsFileCoordinatorEntity?> stat(String url,
      {bool scoped = true}) async {
    return NsFileCoordinatorUtilPlatform.instance.stat(url, scoped: scoped);
  }

  /// Gets the contents of an iCloud directory [url] and returns an array of [NsFileCoordinatorEntity].
  ///
  /// [recursive] whether to list subdirectories recursively.
  /// [filesOnly] return files only.
  Future<List<NsFileCoordinatorEntity>> listContents(String url,
      {bool? recursive, bool? filesOnly, bool scoped = true}) async {
    return NsFileCoordinatorUtilPlatform.instance.listContents(url,
        recursive: recursive, filesOnly: filesOnly, scoped: scoped);
  }

  /// Deletes the given iCloud [url].
  Future<void> delete(String url, {bool scoped = true}) async {
    return NsFileCoordinatorUtilPlatform.instance.delete(url, scoped: scoped);
  }

  /// Moves [srcUrl] url to [destUrl].
  Future<void> move(String srcUrl, String destUrl, {bool scoped = true}) {
    return NsFileCoordinatorUtilPlatform.instance
        .move(srcUrl, destUrl, scoped: scoped);
  }

  /// Copies [srcUrl] url to iCloud [dest].
  Future<void> copy(String srcUrl, String destUrl, {bool scoped = true}) {
    return NsFileCoordinatorUtilPlatform.instance
        .copy(srcUrl, destUrl, scoped: scoped);
  }

  /// Checks if the given iCloud [url] is a directory.
  /// Returns true if the url is a directory, or false if it's a file.
  /// `null` if the url doesn't exist.
  Future<bool?> isDirectory(String url, {bool scoped = true}) async {
    return NsFileCoordinatorUtilPlatform.instance
        .isDirectory(url, scoped: scoped);
  }

  /// Creates a directory [url] like [mkdir -p].
  Future<void> mkdir(String url, {bool scoped = true}) async {
    return NsFileCoordinatorUtilPlatform.instance.mkdir(url, scoped: scoped);
  }

  /// Checks if the directory [url] is empty.
  Future<bool> isEmptyDirectory(String url, {bool scoped = true}) async {
    return NsFileCoordinatorUtilPlatform.instance
        .isEmptyDirectory(url, scoped: scoped);
  }
}
