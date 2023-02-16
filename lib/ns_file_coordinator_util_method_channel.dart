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

  @override
  Future<NsFileCoordinatorEntity> stat(String path) async {
    var map = await methodChannel
        .invokeMapMethod<dynamic, dynamic>('stat', {'src': path});
    return NsFileCoordinatorEntity.fromJson(map ?? {});
  }

  @override
  Future<List<NsFileCoordinatorEntity>> listContents(String path,
      {bool? recursive, bool? filesOnly}) async {
    var entityMaps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('listContents',
            {'src': path, 'recursive': recursive, 'filesOnly': filesOnly});
    if (entityMaps == null) {
      return [];
    }
    return entityMaps.map((e) => NsFileCoordinatorEntity.fromJson(e)).toList();
  }

  @override
  Future<void> delete(String path) async {
    await methodChannel.invokeMethod<void>('delete', {'src': path});
  }

  @override
  Future<void> move(String src, String dest) async {
    await methodChannel.invokeMethod<void>('move', {'src': src, 'dest': dest});
  }

  @override
  Future<void> copy(String src, String dest) async {
    await methodChannel.invokeMethod<void>('copy', {'src': src, 'dest': dest});
  }

  @override
  Future<bool?> entityType(String path) async {
    return await methodChannel.invokeMethod<bool>('entityType', {'src': path});
  }

  @override
  Future<void> mkdir(String path) async {
    await methodChannel.invokeMethod<void>('mkdir', {'src': path});
  }

  @override
  Future<bool> isEmptyDirectory(String path) async {
    return await methodChannel
            .invokeMethod<bool>('isEmptyDirectory', {'src': path}) ??
        false;
  }
}
