import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util_platform_interface.dart';

enum AsyncReadTaskState {
  reading,
  done,
}

class AsyncReadTask {
  final NsFileCoordinatorEntity entity;
  AsyncReadTaskState? state;
  BytesBuilder? bytes;
  String? doneMsg;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              Widget? content;
              if (task.state != null) {
                if (task.state == AsyncReadTaskState.reading) {
                  content =
                      Text('${task.bytes!.length} / ${task.entity.length}');
                } else {
                  content = Text(task.doneMsg ?? 'Done');
                }
              }
              Widget w = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(task.entity.name)),
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            final stream = await _plugin.readFileAsync(
                                task.entity.url,
                                bufferSize: 1024 * 500);
                            task.state = AsyncReadTaskState.reading;
                            task.bytes = BytesBuilder();
                            setState(() {});
                            await for (final bytes in stream) {
                              task.bytes!.add(bytes);
                              setState(() {});
                            }
                            setState(() {
                              task.state = AsyncReadTaskState.done;
                              task.doneMsg = 'Done';
                            });
                          } catch (e) {
                            task.state = AsyncReadTaskState.done;
                            task.doneMsg = 'Error: $e';
                            setState(() {});
                          }
                        },
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                  if (content != null) content,
                ],
              );
              w = Padding(padding: const EdgeInsets.all(8), child: w);
              return w;
            },
          )),
    );
  }
}

bool listEquals<E>(List<E> list1, List<E> list2) {
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
