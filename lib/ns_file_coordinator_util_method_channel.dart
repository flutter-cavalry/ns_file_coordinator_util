import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ns_file_coordinator_util_platform_interface.dart';

/// An implementation of [NsFileCoordinatorUtilPlatform] that uses method channels.
class MethodChannelNsFileCoordinatorUtil extends NsFileCoordinatorUtilPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ns_file_coordinator_util');

  @override
  Future<void> readFile(String src, String dest) async {
    await methodChannel
        .invokeMethod<void>('readFile', {'src': src, 'dest': dest});
  }
}
