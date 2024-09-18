import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ns_file_coordinator_util_platform_interface.dart';

/// An implementation of [NsFileCoordinatorUtilPlatform] that uses method channels.
class MethodChannelNsFileCoordinatorUtil extends NsFileCoordinatorUtilPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ns_file_coordinator_util');

  var _session = 0;

  @override
  Future<Uint8List> readFile(String srcUrl) async {
    final res = await methodChannel.invokeMethod<Uint8List>('readFile', {
      'src': srcUrl.toString(),
    });
    if (res == null) {
      throw Exception('Unexpected null result for file $srcUrl');
    }
    return res;
  }

  @override
  Future<void> writeFile(String destUrl, Uint8List data) async {
    await methodChannel.invokeMethod<bool>('writeFile', {
      'url': destUrl.toString(),
      'data': data,
    });
  }

  @override
  Future<Stream<Uint8List>> readFileStream(String srcUrl,
      {int? bufferSize, double? debugDelay}) async {
    var session = _nextSession();
    await methodChannel.invokeMethod<dynamic>('readFileStream', {
      'src': srcUrl.toString(),
      'bufferSize': bufferSize,
      'session': session,
      'debugDelay': debugDelay,
    });
    var stream = EventChannel('ns_file_coordinator_util/event/$session')
        .receiveBroadcastStream();
    return stream.map((e) => e as Uint8List);
  }

  @override
  Future<NsFileCoordinatorEntity?> stat(String url) async {
    var map = await methodChannel
        .invokeMapMethod<dynamic, dynamic>('stat', {'url': url.toString()});
    if (map == null) {
      return null;
    }
    return NsFileCoordinatorEntity.fromJson(map);
  }

  @override
  Future<List<NsFileCoordinatorEntity>> listContents(String url,
      {bool? recursive, bool? filesOnly, bool? relativePathInfo}) async {
    var entityMaps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('listContents', {
      'url': url.toString(),
      'recursive': recursive,
      'filesOnly': filesOnly,
      'relativePathInfo': relativePathInfo,
    });
    if (entityMaps == null) {
      return [];
    }
    return entityMaps.map((e) => NsFileCoordinatorEntity.fromJson(e)).toList();
  }

  @override
  Future<List<NsFileCoordinatorFileURL>> listContentFiles(String url) async {
    var fileURLs = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('listContentFiles', {
      'url': url.toString(),
    });
    if (fileURLs == null) {
      return [];
    }
    return fileURLs.map((e) => NsFileCoordinatorFileURL.fromJson(e)).toList();
  }

  @override
  Future<void> delete(String url) async {
    await methodChannel.invokeMethod<void>('delete', {'url': url.toString()});
  }

  @override
  Future<void> move(String srcUrl, String destUrl) async {
    await methodChannel.invokeMethod<void>('move', {
      'src': srcUrl.toString(),
      'dest': destUrl.toString(),
    });
  }

  @override
  Future<void> copyPath(String srcUrl, String destUrl) async {
    await methodChannel.invokeMethod<void>('copyPath', {
      'src': srcUrl.toString(),
      'dest': destUrl.toString(),
    });
  }

  @override
  Future<bool?> isDirectory(String url) async {
    return await methodChannel
        .invokeMethod<bool>('isDirectory', {'url': url.toString()});
  }

  @override
  Future<void> mkdir(String url) async {
    await methodChannel.invokeMethod<void>('mkdir', {'url': url.toString()});
  }

  @override
  Future<bool> isEmptyDirectory(String url) async {
    return await methodChannel
            .invokeMethod<bool>('isEmptyDirectory', {'url': url.toString()}) ??
        false;
  }

  @override
  Future<int> startWriteStream(String url) async {
    var session = _nextSession();
    await methodChannel.invokeMethod('startWriteStream', {
      'url': url,
      'session': session,
    });
    return session;
  }

  @override
  Future<void> writeChunk(int session, Uint8List data) async {
    await methodChannel.invokeMethod('writeChunk', {
      'session': session,
      'data': data,
    });
  }

  @override
  Future<void> endWriteStream(int session) async {
    await methodChannel.invokeMethod('endWriteStream', {
      'session': session,
    });
  }

  @override
  Future<List<int>> getPendingWritingSessions() async {
    // The empty map is needed to avoid a platform channel args error.
    return await methodChannel
            .invokeListMethod<int>('getPendingWritingSessions', {}) ??
        [];
  }

  int _nextSession() {
    return ++_session;
  }
}
