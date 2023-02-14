import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ns_file_coordinator_util_method_channel.dart';

class NsFileCoordinatorEntity {
  final String path;
  final String name;
  final bool isDir;
  final int length;
  late final DateTime? lastMod;

  NsFileCoordinatorEntity(this.path, this.name, this.isDir, this.length);

  NsFileCoordinatorEntity.fromJson(Map<dynamic, dynamic> json)
      : path = json['path'] as String,
        name = json['name'] as String,
        isDir = json['isDir'] as bool,
        length = json['length'] as int {
    var lastModTimestamp = json['lastMod'] as int?;
    if (lastModTimestamp != null) {
      lastMod = DateTime.fromMillisecondsSinceEpoch(lastModTimestamp * 1000);
    }
  }

  @override
  String toString() {
    var s = '${isDir ? 'D' : 'F'}|$name${isDir ? '' : '|$length'}';
    if (lastMod != null) {
      s += '|${lastMod.toString()}';
    }
    return s;
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

  Future<List<NsFileCoordinatorEntity>> listContents(String path,
      {bool? recursive}) async {
    throw UnimplementedError('listContents() has not been implemented.');
  }

  Future<void> delete(String path) async {
    throw UnimplementedError('delete() has not been implemented.');
  }

  Future<void> move(String src, String dest) {
    throw UnimplementedError('move() has not been implemented.');
  }

  Future<void> copy(String src, String dest) {
    throw UnimplementedError('copy() has not been implemented.');
  }

  Future<bool?> entityType(String path) async {
    throw UnimplementedError('entityType() has not been implemented.');
  }

  Future<void> mkdir(String path) async {
    throw UnimplementedError('mkdir() has not been implemented.');
  }

  Future<bool> isEmptyDirectory(String path) async {
    throw UnimplementedError('isEmptyDirectory() has not been implemented.');
  }
}
