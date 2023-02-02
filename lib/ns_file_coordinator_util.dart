import 'ns_file_coordinator_util_platform_interface.dart';

class NsFileCoordinatorUtil {
  /// Calls [coordinate(readingItemAt:options:error:byAccessor:)] and copies [src] to [dest].
  Future<void> readFile(String src, String dest) {
    return NsFileCoordinatorUtilPlatform.instance.readFile(src, dest);
  }
}
