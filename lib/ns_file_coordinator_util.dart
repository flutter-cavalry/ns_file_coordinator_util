import 'ns_file_coordinator_util_platform_interface.dart';

class NsFileCoordinatorUtil {
  /// Reads an iCloud [src] file and copies it to [dest].
  Future<void> readFile(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.readFile(src, dest);
  }

  /// Gets the contents of an iCloud directory [path] and returns an array of [NsFileCoordinatorEntity].
  Future<List<NsFileCoordinatorEntity>> listContents(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.listContents(path);
  }

  /// Deletes the given iCloud [path].
  Future<void> delete(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.delete(path);
  }

  /// Moves [src] path to [dest].
  Future<void> move(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.move(src, dest);
  }

  /// Copies [src] file to iCloud [dest].
  Future<void> writeFile(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.writeFile(src, dest);
  }

  /// Checks if the given iCloud [path] exists.
  Future<bool> exists(String path) async {
    return NsFileCoordinatorUtilPlatform.instance.exists(path);
  }
}
