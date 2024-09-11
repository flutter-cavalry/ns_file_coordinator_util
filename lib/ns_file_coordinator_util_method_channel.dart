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
  Future<void> readFile(String srcUrl, String destUrl) async {
    await methodChannel.invokeMethod<void>('readFile', {
      'src': srcUrl.toString(),
      'dest': destUrl.toString(),
    });
  }

  @override
  Future<Stream<Uint8List>> readFileAsync(String srcUrl,
      {int? bufferSize, double? debugDelay}) async {
    var session = _nextSession();
    await methodChannel.invokeMethod<dynamic>('readFileAsync', {
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
  Future<void> copy(String srcUrl, String destUrl) async {
    await methodChannel.invokeMethod<void>('copy', {
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

  int _nextSession() {
    return ++_session;
  }
}
