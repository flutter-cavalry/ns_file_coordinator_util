import 'ns_file_coordinator_util_platform_interface.dart';

class NsFileCoordinatorUtil {
  /// Reads an iCloud [src] file and copies it to [dest].
  Future<void> readFile(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.readFile(src, dest);
  }

  /// Returns information about the given [path].
  Future<NsFileCoordinatorEntity> stat(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.stat(path);
  }

  /// Gets the contents of an iCloud directory [path] and returns an array of [NsFileCoordinatorEntity].
  ///
  /// [recursive] whether to list subdirectories recursively.
  /// [filesOnly] return files only.
  Future<List<NsFileCoordinatorEntity>> listContents(String path,
      {bool? recursive, bool? filesOnly}) async {
    return NsFileCoordinatorUtilPlatform.instance
        .listContents(path, recursive: recursive, filesOnly: filesOnly);
  }

  /// Deletes the given iCloud [path].
  Future<void> delete(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.delete(path);
  }

  /// Moves [src] path to [dest].
  Future<void> move(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.move(src, dest);
  }

  /// Copies [src] path to iCloud [dest].
  Future<void> copy(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.copy(src, dest);
  }

  /// Checks if the given iCloud [path] exists.
  /// Returns true if the path is a directory, or false for files. `null` if
  /// the path doesn't exist.
  Future<bool?> entityType(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.entityType(path);
  }

  /// Creates a directory [path] like [mkdir -p].
  Future<void> mkdir(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.mkdir(path);
  }

  /// Checks if the directory [path] is empty.
  Future<bool> isEmptyDirectory(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.isEmptyDirectory(path);
  }
}
