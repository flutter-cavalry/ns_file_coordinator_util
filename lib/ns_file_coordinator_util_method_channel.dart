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
  Future<List<NsFileCoordinatorEntity>> listContents(String path) async {
    var entityMaps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('listContents', {
      'src': path,
    });
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
  Future<bool> exists(String path) async {
    return await methodChannel.invokeMethod<bool>('exists', {'src': path}) ??
        false;
  }

  @override
  Future<void> mkdir(String path) async {
    await methodChannel.invokeMethod<void>('mkdir', {'src': path});
  }
}
