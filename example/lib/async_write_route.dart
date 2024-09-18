import 'dart:convert';
import 'package:darwin_url/darwin_url.dart';
import 'package:flutter/material.dart';
import 'package:ns_file_coordinator_util/ns_file_coordinator_util.dart';
import 'package:ns_file_coordinator_util_example/alert_util.dart';

class AsyncWriteTask {
  final String name;
  final String url;

  double? progress;
  String? doneMsg;
  bool cancelled = false;

  AsyncWriteTask(this.name, this.url);

  Future<void> write(
      NsFileCoordinatorUtil plugin, void Function() callback) async {
    progress = 0.0;
    callback();
    final session = await plugin.startWriteStream(url);
    for (var i = 0; i < 10; i++) {
      if (cancelled) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      await plugin.writeChunk(session, utf8.encode('😡 $i'));
      progress = i / 10;
      callback();
    }
    await plugin.endWriteStream(session);
    if (cancelled) {
      doneMsg = 'Cancelled';
    } else {
      doneMsg = 'Async write done';
    }
    callback();
  }
}

class AsyncWriteRoute extends StatefulWidget {
  final String dirUrl;

  const AsyncWriteRoute({super.key, required this.dirUrl});

  @override
  State<AsyncWriteRoute> createState() => _AsyncWriteRouteState();
}

class _AsyncWriteRouteState extends State<AsyncWriteRoute> {
  final _plugin = NsFileCoordinatorUtil();
  final _darwinUrl = DarwinUrl();
  final _tasks = <AsyncWriteTask>[];
  var _pendingSessions = '';

  String _nextFileName(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.txt';
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        Widget content;
        if (task.doneMsg == null) {
          content = Text('🟢 ${task.progress?.toStringAsFixed(2)}');
        } else {
          content = Text(task.doneMsg ?? '');
        }
        Widget w = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(task.name)),
                OutlinedButton(
                    onPressed: task.progress == null ||
                            task.doneMsg != null ||
                            task.cancelled
                        ? null
                        : () {
                            setState(() {
                              task.cancelled = true;
                            });
                          },
                    child: Text(task.cancelled ? 'Cancelling' : 'Cancel')),
              ],
            ),
            content,
          ],
        );
        w = Padding(padding: const EdgeInsets.all(8), child: w);
        return w;
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const Text(
                  'NOTE: All read operations have a 0.5s delay for debugging.',
                  style: TextStyle(color: Colors.red)),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 8,
                  ),
                  OutlinedButton(
                      onPressed: () async {
                        final sessions =
                            await _plugin.getPendingWritingSessions();
                        setState(() {
                          _pendingSessions =
                              sessions.isEmpty ? '<none>' : sessions.toString();
                        });
                      },
                      child: const Text('Get pending write sessions')),
                  const SizedBox(
                    width: 8,
                  ),
                  OutlinedButton(
                      onPressed: () async {
                        final fileName = _nextFileName('w_async');
                        final url = await _darwinUrl
                            .append(widget.dirUrl, [fileName], isDir: false);
                        final task = AsyncWriteTask(fileName, url);
                        setState(() {
                          _tasks.add(task);
                        });
                        await task.write(_plugin, () {
                          setState(() {});
                        });
                      },
                      child: const Text('Write async')),
                  const SizedBox(
                    width: 8,
                  ),
                  OutlinedButton(
                      onPressed: () async {
                        try {
                          final fileName = _nextFileName('w_sync');
                          final url = await _darwinUrl
                              .append(widget.dirUrl, [fileName], isDir: false);
                          await _plugin.writeFile(
                              url, utf8.encode('Hello, world!'));
                          if (!context.mounted) {
                            return;
                          }
                          showInfoAlert(context, 'File written: $url');
                        } catch (e) {
                          showErrorAlert(context, e);
                        }
                      },
                      child: const Text('Write sync'))
                ],
              ),
              if (_pendingSessions.isNotEmpty) ...[
                const SizedBox(
                  height: 8,
                ),
                Text('Pending sessions: $_pendingSessions'),
              ],
              const SizedBox(
                height: 8,
              ),
              Expanded(child: body),
            ],
          )),
    );
  }
}
