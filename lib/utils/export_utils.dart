// export_utils.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Export Excel
Future<void> exportExcel(List<Map<String, dynamic>> rows, String fileName) async {
  if (rows.isEmpty) return;
  final excel = Excel.createExcel();
  final sheet = excel['Report'];

  // Headers
  sheet.appendRow(rows.first.keys.map((h) => TextCellValue(h)).toList());

  // Values
  for (final r in rows) {
    sheet.appendRow(
      r.values.map((v) => TextCellValue(v?.toString() ?? '')).toList(),
    );
  }

  final bytes = excel.encode();
  if (bytes == null) return;
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$fileName.xlsx';
  final file = File(path)..writeAsBytesSync(bytes);

  // Partage
  await Share.shareXFiles([XFile(file.path)], text: 'Rapport Excel');
}

/// Export CSV
Future<void> exportCsv(List<Map<String, dynamic>> rows, String fileName) async {
  if (rows.isEmpty) return;
  final sb = StringBuffer();
  final headers = rows.first.keys.toList();
  sb.writeln(headers.join(','));

  for (final r in rows) {
    sb.writeln(headers
        .map((h) => '"${(r[h] ?? '').toString().replaceAll('"', '""')}"')
        .join(','));
  }

  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$fileName.csv';
  final file = File(path)..writeAsStringSync(sb.toString());
  await Share.shareXFiles([XFile(file.path)], text: 'Rapport CSV');
}

/// Capture widget as PNG (wrapped in RepaintBoundary)
Future<Uint8List?> captureWidgetAsPng(GlobalKey key, {double pixelRatio = 3.0}) async {
  try {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (e) {
    return null;
  }
}

/// Export PDF with chart image + table
Future<void> exportPdfWithChart(
  Uint8List? chartPng,
  Map<String, dynamic> summary,
  List<Map<String, dynamic>> rows,
  String fileName,
) async {
  final pdf = pw.Document();
  final pwImage = chartPng != null ? pw.MemoryImage(chartPng) : null;

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Rapport GarageLink', style: pw.TextStyle(fontSize: 20))),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Expanded(child: pw.Text('CA: ${summary['ca'] ?? '-'}')),
          pw.Expanded(child: pw.Text('Interventions: ${summary['interventions'] ?? '-'}')),
          pw.Expanded(child: pw.Text('Marge: ${summary['marge'] ?? '-'}')),
        ]),
        pw.SizedBox(height: 12),
        if (pwImage != null) pw.Center(child: pw.Image(pwImage, height: 200)),
        pw.SizedBox(height: 12),
        if (rows.isNotEmpty) pw.Text('Détails', style: pw.TextStyle(fontSize: 14)),
        if (rows.isNotEmpty)
          pw.Table.fromTextArray(
            headers: rows.first.keys.toList(),
            data: rows.map((r) => r.values.map((v) => v?.toString() ?? '').toList()).toList(),
          ),
      ],
    ),
  );

  final bytes = await pdf.save();
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/$fileName.pdf';
  final file = File(path)..writeAsBytesSync(bytes);
  // partage via printing
  await Printing.sharePdf(bytes: bytes, filename: fileName);
}




