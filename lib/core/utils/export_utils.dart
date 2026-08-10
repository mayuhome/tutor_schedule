import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportUtils {
  static Future<File> exportToCsv({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final csvData = const ListToCsvConverter().convert([headers, ...rows]);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.csv');
    await file.writeAsString(csvData, encoding: utf8);
    return file;
  }

  static Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '数据导出',
    );
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}小时${m}分钟';
    if (h > 0) return '$h小时';
    return '$m分钟';
  }

  static String formatCurrency(double amount) {
    return '¥${amount.toStringAsFixed(2)}';
  }
}
