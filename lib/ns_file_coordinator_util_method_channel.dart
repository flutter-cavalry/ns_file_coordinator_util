import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ns_file_coordinator_util_platform_interface.dart';

/// An implementation of [NsFileCoordinatorUtilPlatform] that uses method channels.
class MethodChannelNsFileCoordinatorUtil extends NsFileCoordinatorUtilPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ns_file_coordinator_util');

  @override
  Future<void> readFile(Uri src, Uri dest) async {
    await methodChannel.invokeMethod<void>(
        'readFile', {'src': src.toString(), 'dest': dest.toString()});
  }

  @override
  Future<NsFileCoordinatorEntity> stat(Uri path) async {
    var map = await methodChannel
        .invokeMapMethod<dynamic, dynamic>('stat', {'path': path.toString()});
    return NsFileCoordinatorEntity.fromJson(map ?? {});
  }

  @override
  Future<List<NsFileCoordinatorEntity>> listContents(Uri path,
      {bool? recursive, bool? filesOnly}) async {
    var entityMaps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('listContents', {
      'path': path.toString(),
      'recursive': recursive,
      'filesOnly': filesOnly
    });
    if (entityMaps == null) {
      return [];
    }
    return entityMaps.map((e) => NsFileCoordinatorEntity.fromJson(e)).toList();
  }

  @override
  Future<void> delete(Uri path) async {
    await methodChannel.invokeMethod<void>('delete', {'path': path.toString()});
  }

  @override
  Future<void> move(Uri src, Uri dest) async {
    await methodChannel.invokeMethod<void>(
        'move', {'src': src.toString(), 'dest': dest.toString()});
  }

  @override
  Future<void> copy(Uri src, Uri dest) async {
    await methodChannel.invokeMethod<void>(
        'copy', {'src': src.toString(), 'dest': dest.toString()});
  }

  @override
  Future<bool?> isDirectory(Uri path) async {
    return await methodChannel
        .invokeMethod<bool>('isDirectory', {'path': path.toString()});
  }

  @override
  Future<void> mkdir(Uri path) async {
    await methodChannel.invokeMethod<void>('mkdir', {'path': path.toString()});
  }

  @override
  Future<bool> isEmptyDirectory(Uri path) async {
    return await methodChannel.invokeMethod<bool>(
            'isEmptyDirectory', {'path': path.toString()}) ??
        false;
  }
}
