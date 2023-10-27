import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ns_file_coordinator_util_platform_interface.dart';

/// An implementation of [NsFileCoordinatorUtilPlatform] that uses method channels.
class MethodChannelNsFileCoordinatorUtil extends NsFileCoordinatorUtilPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ns_file_coordinator_util');

  @override
  Future<void> readFile(String srcUrl, String destUrl,
      {bool scoped = true}) async {
    await methodChannel.invokeMethod<void>('readFile', {
      'src': srcUrl.toString(),
      'dest': destUrl.toString(),
      'scoped': scoped,
    });
  }

  @override
  Future<NsFileCoordinatorEntity?> stat(String url,
      {bool scoped = true}) async {
    var map = await methodChannel.invokeMapMethod<dynamic, dynamic>(
        'stat', {'url': url.toString(), 'scoped': scoped});
    if (map == null) {
      return null;
    }
    return NsFileCoordinatorEntity.fromJson(map);
  }

  @override
  Future<List<NsFileCoordinatorEntity>> listContents(String url,
      {bool? recursive, bool? filesOnly, bool scoped = true}) async {
    var entityMaps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('listContents', {
      'url': url.toString(),
      'recursive': recursive,
      'filesOnly': filesOnly,
      'scoped': scoped
    });
    if (entityMaps == null) {
      return [];
    }
    return entityMaps.map((e) => NsFileCoordinatorEntity.fromJson(e)).toList();
  }

  @override
  Future<void> delete(String url, {bool scoped = true}) async {
    await methodChannel.invokeMethod<void>(
        'delete', {'url': url.toString(), 'scoped': scoped});
  }

  @override
  Future<void> move(String srcUrl, String destUrl, {bool scoped = true}) async {
    await methodChannel.invokeMethod<void>('move', {
      'src': srcUrl.toString(),
      'dest': destUrl.toString(),
      'scoped': scoped
    });
  }

  @override
  Future<void> copy(String srcUrl, String destUrl, {bool scoped = true}) async {
    await methodChannel.invokeMethod<void>('copy', {
      'src': srcUrl.toString(),
      'dest': destUrl.toString(),
      'scoped': scoped
    });
  }

  @override
  Future<bool?> isDirectory(String url, {bool scoped = true}) async {
    return await methodChannel.invokeMethod<bool>(
        'isDirectory', {'url': url.toString(), 'scoped': scoped});
  }

  @override
  Future<void> mkdir(String url, {bool scoped = true}) async {
    await methodChannel
        .invokeMethod<void>('mkdir', {'url': url.toString(), 'scoped': scoped});
  }

  @override
  Future<bool> isEmptyDirectory(String url, {bool scoped = true}) async {
    return await methodChannel.invokeMethod<bool>(
            'isEmptyDirectory', {'url': url.toString(), 'scoped': scoped}) ??
        false;
  }
}
