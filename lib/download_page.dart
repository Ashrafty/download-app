import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'download_task.dart';
import 'notifications.dart';

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final TextEditingController _urlController = TextEditingController();
  final List<DownloadTask> _downloadQueue = [];
  final List<DownloadTask> _completedDownloads = [];
  String _downloadPath = '';

  @override
  void initState() {
    super.initState();
    _initDownloadPath();
  }

  void _initDownloadPath() async {
    if (Platform.isAndroid) {
      _downloadPath = '/storage/emulated/0/Download';
    } else if (Platform.isWindows) {
      final directory = await getDownloadsDirectory();
      _downloadPath = directory?.path ?? '';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download App'),
        actions: [
          IconButton(
            icon: Icon(Icons.folder),
            onPressed: _openDownloadFolder,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Enter URL or YouTube Video ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                Text('Download Path: $_downloadPath'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _showQualityPopup,
                  child: Text('Download'),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'Queue'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildQueueList(),
                        _buildCompletedList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    return ListView.builder(
      itemCount: _downloadQueue.length,
      itemBuilder: (context, index) {
        final task = _downloadQueue[index];
        return ListTile(
          title: Text(task.fileName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: task.progress),
              Text(task.status),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () => _cancelDownload(task),
          ),
        );
      },
    );
  }

  Widget _buildCompletedList() {
    return ListView.builder(
      itemCount: _completedDownloads.length,
      itemBuilder: (context, index) {
        final task = _completedDownloads[index];
        return ListTile(
          title: Text(task.fileName),
          subtitle: Text('Completed'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.open_in_new),
                onPressed: () => _openFile(task),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteFile(task),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQualityPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Download Quality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addToQueue('high');
                },
                child: Text('High Quality'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addToQueue('medium');
                },
                child: Text('Medium Quality'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addToQueue('low');
                },
                child: Text('Low Quality'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addToQueue('audio');
                },
                child: Text('Audio Only'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToQueue(String quality) async {
    String url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('Please enter a URL or YouTube Video ID');
      return;
    }
    if (Platform.isAndroid) {
      if (await _requestStoragePermission()) {
        _enqueueDownload(url, quality);
      } else {
        _showStoragePermissionDialog();
      }
    } else {
      _enqueueDownload(url, quality);
    }
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.storage.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return false;
  }

  void _showStoragePermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text('This app needs access to your storage to download files. Please grant storage permission in the app settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _enqueueDownload(String url, String quality) {
    DownloadTask task = DownloadTask(url: url, quality: quality);
    setState(() {
      _downloadQueue.add(task);
    });
    _startDownload(task);
    _urlController.clear();
  }

  Future<void> _startDownload(DownloadTask task) async {
    try {
      if (task.url.contains('youtube.com') || task.url.contains('youtu.be')) {
        await _downloadYouTubeVideo(task);
      } else {
        await _downloadFile(task);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
      setState(() {
        task.status = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _downloadFile(DownloadTask task) async {
    Dio dio = Dio();
    String fileName = task.url.split('/').last;
    String savePath = path.join(_downloadPath, fileName);
    task.fileName = fileName;
    task.cancelToken = CancelToken();
    try {
      await dio.download(
        task.url,
        savePath,
        cancelToken: task.cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              task.progress = received / total;
              task.status = '${(task.progress * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );
      setState(() {
        task.progress = 1.0;
        task.status = 'Completed';
        _downloadQueue.remove(task);
        _completedDownloads.add(task);
      });
      showNotification('Download Complete', fileName);
    } catch (e) {
      if (task.cancelToken!.isCancelled) {
        setState(() {
          task.status = 'Cancelled';
          _downloadQueue.remove(task);
        });
      } else {
        throw e;
      }
    }
  }

  Future<void> _downloadYouTubeVideo(DownloadTask task) async {
    final yt = YoutubeExplode();
    try {
      Video video = await yt.videos.get(task.url);
      StreamManifest manifest = await yt.videos.streamsClient.getManifest(video.id);
      StreamInfo streamInfo;
      bool isAudioOnly = false;
      switch (task.quality) {
        case 'high':
          streamInfo = manifest.muxed.bestQuality;
          break;
        case 'medium':
          streamInfo = manifest.muxed.firstWhere(
            (s) => s.videoQuality.name == 'medium',
            orElse: () => manifest.muxed.bestQuality
          );
          break;
        case 'low':
          streamInfo = manifest.muxed.sortByVideoQuality().first;
          break;
        case 'audio':
          streamInfo = manifest.audioOnly.withHighestBitrate();
          isAudioOnly = true;
          break;
        default:
          streamInfo = manifest.muxed.bestQuality;
      }
      String sanitizedTitle = video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      String fileExtension = isAudioOnly ? 'mp3' : streamInfo.container.name;
      String fileName = '${sanitizedTitle}.$fileExtension';
      String tempFilePath = path.join(_downloadPath, '${sanitizedTitle}_temp.$fileExtension');
      String finalFilePath = path.join(_downloadPath, fileName);
      task.fileName = fileName;
      task.cancelToken = CancelToken();

      Stream<List<int>> stream = yt.videos.streamsClient.get(streamInfo);
      File tempFile = File(tempFilePath);
      IOSink sink = tempFile.openWrite();
      int totalBytes = streamInfo.size.totalBytes;
      int receivedBytes = 0;
      await for (final chunk in stream) {
        if (task.cancelToken!.isCancelled) {
          await sink.close();
          await tempFile.delete();
          setState(() {
            task.status = 'Cancelled';
            _downloadQueue.remove(task);
          });
          return;
        }
        sink.add(chunk);
        receivedBytes += chunk.length;
        setState(() {
          task.progress = receivedBytes / totalBytes;
          task.status = '${(task.progress * 100).toStringAsFixed(0)}%';
        });
      }
      await sink.close();
      if (isAudioOnly) {
        setState(() {
          task.status = 'Converting to MP3...';
        });
        final session = await FFmpegKit.execute('-i "$tempFilePath" -acodec libmp3lame -b:a 128k "$finalFilePath"');
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          await tempFile.delete(); // Delete the temporary file
        } else {
          final logs = await session.getAllLogsAsString();
          throw Exception('Failed to convert audio to MP3: $logs');
        }
      } else {
        await tempFile.rename(finalFilePath);
      }
      yt.close();
      setState(() {
        task.progress = 1.0;
        task.status = 'Completed';
        _downloadQueue.remove(task);
        _completedDownloads.add(task);
      });
      showNotification('Download Complete', fileName);
    } catch (e) {
      throw Exception('Error downloading YouTube video: ${e.toString()}');
    }
  }

  void _cancelDownload(DownloadTask task) {
    task.cancelToken?.cancel();
    setState(() {
      _downloadQueue.remove(task);
    });
  }

  void _deleteFile(DownloadTask task) async {
    File file = File(path.join(_downloadPath, task.fileName));
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {
      _completedDownloads.remove(task);
    });
  }

  void _openFile(DownloadTask task) async {
    String filePath = path.join(_downloadPath, task.fileName);
    OpenFile.open(filePath);
  }

  void _openDownloadFolder() async {
    OpenFile.open(_downloadPath);
  }

  void _openSettings() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _downloadPath = selectedDirectory;
      });
      _showSnackBar('Download path updated');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}