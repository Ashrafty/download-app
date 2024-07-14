import 'package:dio/dio.dart';

class DownloadTask {
  final String url;
  final String quality;
  String fileName = '';
  double progress = 0.0;
  String status = 'Pending';
  CancelToken? cancelToken;

  DownloadTask({required this.url, required this.quality});
}