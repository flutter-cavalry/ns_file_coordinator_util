import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ns_file_coordinator_util_method_channel.dart';

class NsFileCoordinatorEntity {
  final String path;
  final String name;
  final bool isDir;
  final int length;

  NsFileCoordinatorEntity(this.path, this.name, this.isDir, this.length);

  NsFileCoordinatorEntity.fromJson(Map<dynamic, dynamic> json)
      : path = json['path'] as String,
        name = json['name'] as String,
        isDir = json['isDir'] as bool,
        length = json['length'] as int;

  @override
  String toString() {
    return '${isDir ? 'D' : 'F'}|$name${isDir ? '' : '|$length'}';
  }
}

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

  Future<List<NsFileCoordinatorEntity>> listContents(String src) async {
    throw UnimplementedError('listContents() has not been implemented.');
  }

  Future<void> delete(String src) async {
    throw UnimplementedError('delete() has not been implemented.');
  }

  Future<void> move(String src, String dest) {
    throw UnimplementedError('move() has not been implemented.');
  }

  Future<void> writeFile(String src, String dest) {
    throw UnimplementedError('writeFile() has not been implemented.');
  }
}
