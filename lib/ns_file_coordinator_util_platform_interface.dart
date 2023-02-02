import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ns_file_coordinator_util_method_channel.dart';

abstract class NsFileCoordinatorUtilPlatform extends PlatformInterface {
  /// Constructs a NsFileCoordinatorUtilPlatform.
  NsFileCoordinatorUtilPlatform() : super(token: _token);

  static final Object _token = Object();

  static NsFileCoordinatorUtilPlatform _instance =
      MethodChannelNsFileCoordinatorUtil();

  /// The default instance of [NsFileCoordinatorUtilPlatform] to use.
  ///
  /// Defaults to [MethodChannelNsFileCoordinatorUtil].
  static NsFileCoordinatorUtilPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NsFileCoordinatorUtilPlatform] when
  /// they register themselves.
  static set instance(NsFileCoordinatorUtilPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> readFile(String src, String dest) {
    throw UnimplementedError('readFile() has not been implemented.');
  }
}
