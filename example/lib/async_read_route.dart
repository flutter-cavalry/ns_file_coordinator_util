import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util_platform_interface.dart';
import 'package:pretty_bytes/pretty_bytes.dart';

class AsyncReadTask {
  final NsFileCoordinatorEntity entity;
  bool working = false;
  BytesBuilder? bytes;
  String? doneMsg;
  bool cancelled = false;

  AsyncReadTask(this.entity);
}

class AsyncReadRoute extends StatefulWidget {
  final String dirUrl;

  const AsyncReadRoute({super.key, required this.dirUrl});

  @override
  State<AsyncReadRoute> createState() => _AsyncReadRouteState();
}

class _AsyncReadRouteState extends State<AsyncReadRoute> {
  final _plugin = NsFileCoordinatorUtil();
  final _tasks = <AsyncReadTask>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final files = (await _plugin.listContents(widget.dirUrl))
          .where((e) => !e.isDir)
          .toList();
      for (final file in files) {
        _tasks.add(AsyncReadTask(file));
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            Widget content;
            if (task.working) {
              content = Text(
                  '🟢 ${prettyBytes(task.bytes!.length.toDouble())} / ${prettyBytes(task.entity.length.toDouble())}');
            } else {
              content = Text(task.doneMsg ?? '');
            }
            Widget w = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                            '${prettyBytes(task.entity.length.toDouble())} | ${task.entity.name}')),
                    OutlinedButton(
                      onPressed: task.working
                          ? null
                          : () async {
                              try {
                                task.bytes = BytesBuilder();
                                setState(() {
                                  task.working = true;
                                });
                                final stream = await _plugin.readFileStream(
                                    task.entity.url,
                                    bufferSize: 1024 * 300,
                                    debugDelay: 0.5);
                                await for (final bytes in stream) {
                                  if (task.cancelled) {
                                    break;
                                  }
                                  task.bytes!.add(bytes);
                                  setState(() {});
                                }
                                if (task.cancelled) {
                                  task.doneMsg = 'Cancelled';
                                } else {
                                  final expected =
                                      await _plugin.readFile(task.entity.url);
                                  final actual = task.bytes!.takeBytes();
                                  if (!_listEquals(actual, expected)) {
                                    task.doneMsg = 'Error: Mismatch';
                                  } else {
                                    task.doneMsg =
                                        'Async read: ${prettyBytes(actual.length.toDouble())}';
                                  }
                                }
                                task.working = false;
                                task.cancelled = false;
                                setState(() {});
                              } catch (e) {
                                task.working = false;
                                task.cancelled = false;
                                task.doneMsg = 'Error: $e';
                                setState(() {});
                              }
                            },
                      child: const Text('Async read'),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    OutlinedButton(
                        onPressed: !task.working || task.cancelled
                            ? null
                            : () {
                                setState(() {
                                  task.cancelled = true;
                                });
                              },
                        child: Text(task.cancelled ? 'Cancelling' : 'Cancel')),
                    const SizedBox(
                      width: 8,
                    ),
                    OutlinedButton(
                        onPressed: () async {
                          final bytes = await _plugin.readFile(task.entity.url);
                          setState(() {
                            task.doneMsg =
                                'Sync read: ${prettyBytes(bytes.length.toDouble())}';
                          });
                        },
                        child: const Text('Sync read')),
                  ],
                ),
                content,
              ],
            );
            w = Padding(padding: const EdgeInsets.all(8), child: w);
            return w;
          },
        ));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Column(
        children: [
          const Text(
              'NOTE: All read operations have a 0.5s delay for debugging.',
              style: TextStyle(color: Colors.red)),
          Expanded(child: body),
        ],
      ),
    );
  }
}

bool _listEquals<E>(List<E> list1, List<E> list2) {
  if (identical(list1, list2)) {
    return true;
  }

  if (list1.length != list2.length) {
    return false;
  }

  for (var i = 0; i < list1.length; i += 1) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }

  return true;
}
