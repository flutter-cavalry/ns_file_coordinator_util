import 'ns_file_coordinator_util_platform_interface.dart';

class NsFileCoordinatorUtil {
  /// Reads an iCloud [src] file and copies it to [dest].
  Future<void> readFile(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.readFile(src, dest);
  }

  /// Gets the contents of an iCloud [src] directory and returns an array of [NsFileCoordinatorEntity].
  Future<List<NsFileCoordinatorEntity>> listContents(String src) async {
    return NsFileCoordinatorUtilPlatform.instance.listContents(src);
  }

  /// Deletes the given iCloud path.
  Future<void> delete(String src) async {
    return NsFileCoordinatorUtilPlatform.instance.delete(src);
  }

  /// Moves [src] path to [dest].
  Future<void> move(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.move(src, dest);
  }

  /// Copies [src] file to iCloud [dest].
  Future<void> writeFile(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.writeFile(src, dest);
  }
}
