import 'dart:convert';
import 'dart:io';

import 'package:aimedicalreportanalyzer/constants/app_config.dart';
import 'package:aimedicalreportanalyzer/models/db_model.dart';
import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ReportDatabase {
  ReportDatabase._();
  static final ReportDatabase instance = ReportDatabase._();

  Future<Database>? _db;
  Future<Database> get database => _db ??= _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'reports.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at INTEGER NOT NULL,
            report_type TEXT NOT NULL,
            summary TEXT NOT NULL,
            finding_count INTEGER NOT NULL,
            abnormal_count INTEGER NOT NULL,
            has_urgent INTEGER NOT NULL DEFAULT 0,
            ocr_text TEXT NOT NULL,
            result_json TEXT NOT NULL,
            image_path TEXT,
            schema_version INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_reports_created ON reports(created_at DESC)',
        );
      },
      // Future schema changes: bump `version` and add an onUpgrade migration.
    );
  }
}

class ReportRepository {
  Future<int> save(
    ReportAnalysis analysis, {
    required String ocrText,
    File? image,
  }) async {
    String? savedImage;
    if (AppConfig.saveImages && image != null) {
      savedImage = await _copyImage(image);
    }
    final db = await ReportDatabase.instance.database;
    return db.insert('reports', {
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'report_type': analysis.reportType.isEmpty
          ? 'Medical report'
          : analysis.reportType,
      'summary': analysis.summary,
      'finding_count': analysis.findings.length,
      'abnormal_count': analysis.abnormalCount,
      'has_urgent': analysis.urgentFlags.isEmpty ? 0 : 1,
      'ocr_text': ocrText,
      'result_json': jsonEncode(analysis.toJson()),
      'image_path': savedImage,
      'schema_version': 1,
    });
  }

  Future<List<StoredReportModel>> list() async {
    final db = await ReportDatabase.instance.database;
    final rows = await db.query('reports', orderBy: 'created_at DESC');
    return rows.map(StoredReportModel.fromRow).toList();
  }

  Future<void> delete(int id) async {
    final db = await ReportDatabase.instance.database;
    final rows = await db.query(
      'reports',
      columns: ['image_path'],
      where: 'id = ?',
      whereArgs: [id],
    );
    for (final r in rows) {
      await _deleteFile(r['image_path'] as String?);
    }
    await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await ReportDatabase.instance.database;
    final rows = await db.query('reports', columns: ['image_path']);
    for (final r in rows) {
      await _deleteFile(r['image_path'] as String?);
    }
    await db.delete('reports');
  }

  Future<String> _copyImage(File image) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'report_images'));
    await dir.create(recursive: true);
    final target = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await image.copy(target);
    return target;
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
