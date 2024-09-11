import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ns_file_coordinator_util_method_channel.dart';

class NsFileCoordinatorEntity {
  final String url;
  final String name;
  final bool isDir;
  final int length;
  final String? relativePath;
  late final DateTime? lastMod;

  NsFileCoordinatorEntity(this.url, this.name, this.isDir, this.length,
      {this.relativePath, this.lastMod});

  NsFileCoordinatorEntity.fromJson(Map<dynamic, dynamic> json)
      : url = json['url'] as String,
        name = json['name'] as String,
        isDir = json['isDir'] as bool,
        length = json['length'] as int,
        relativePath = json['relativePath'] as String? {
    var lastModTimestamp = json['lastMod'] as int?;
    if (lastModTimestamp != null) {
      lastMod = DateTime.fromMillisecondsSinceEpoch(lastModTimestamp * 1000);
    } else {
      lastMod = null;
    }
  }

  @override
  String toString() {
    var s = '${isDir ? 'D' : 'F'}|$name${isDir ? '' : '|$length'}';
    if (lastMod != null) {
      s += '|${lastMod.toString()}';
    }
    if (relativePath != null) {
      s += '|[REL]$relativePath';
    }
    return s;
  }

  String fullDescription() {
    var s = 'url: $url\nname: $name\nisDir: $isDir\nlength: $length';
    if (lastMod != null) {
      s += '\nlastMod: ${lastMod.toString()}';
    }
    if (relativePath != null) {
      s += '\nrelativePath: $relativePath';
    }
    return s;
  }
}

class NsFileCoordinatorFileURL {
  final String url;
  final String? relativePath;

  NsFileCoordinatorFileURL(this.url, this.relativePath);

  NsFileCoordinatorFileURL.fromJson(Map<dynamic, dynamic> json)
      : url = json['url'] as String,
        relativePath = json['relativePath'] as String?;

  @override
  String toString() {
    var s = url;
    if (relativePath != null) {
      s += '|[REL]$relativePath';
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

  Future<void> readFile(String srcUrl, String destUrl) {
    throw UnimplementedError('readFile() has not been implemented.');
  }

  Future<Stream<Uint8List>> readFileAsync(String srcUrl,
      {int? bufferSize, double? debugDelay}) {
    throw UnimplementedError('readFileAsync() has not been implemented.');
  }

  Future<NsFileCoordinatorEntity?> stat(String url) async {
    throw UnimplementedError('stat() has not been implemented.');
  }

  Future<List<NsFileCoordinatorEntity>> listContents(String url,
      {bool? recursive, bool? filesOnly, bool? relativePathInfo}) async {
    throw UnimplementedError('listContents() has not been implemented.');
  }

  Future<List<NsFileCoordinatorFileURL>> listContentFiles(String url) async {
    throw UnimplementedError('listContentFiles() has not been implemented.');
  }

  Future<void> delete(String url) async {
    throw UnimplementedError('delete() has not been implemented.');
  }

  Future<void> move(String srcUrl, String destUrl) {
    throw UnimplementedError('move() has not been implemented.');
  }

  Future<void> copy(String srcUrl, String destUrl) {
    throw UnimplementedError('copy() has not been implemented.');
  }

  Future<bool?> isDirectory(String url) async {
    throw UnimplementedError('isDirectory() has not been implemented.');
  }

  Future<void> mkdir(String url) async {
    throw UnimplementedError('mkdir() has not been implemented.');
  }

  Future<bool> isEmptyDirectory(String url) async {
    throw UnimplementedError('isEmptyDirectory() has not been implemented.');
  }
}
