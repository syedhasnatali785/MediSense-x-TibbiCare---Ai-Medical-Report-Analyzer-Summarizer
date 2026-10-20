// import 'dart:convert';
// import 'dart:io';

// import 'package:aimedicalreportanalyzer/models/report_analysis_m.dart';
// import 'package:path/path.dart' as p;
// import 'package:sqflite/sqflite.dart';

// class ReportDatabase {
//   ReportDatabase._();
//   static final ReportDatabase instance = ReportDatabase._();

//   Future<Database>? _db;
//   Future<Database> get database => _db ??= _open();

//   Future<Database> _open() async {
//     final path = p.join(await getDatabasesPath(), 'reports.db');
//     return openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE reports (
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             created_at INTEGER NOT NULL,
//             report_type TEXT NOT NULL,
//             summary TEXT NOT NULL,
//             finding_count INTEGER NOT NULL,
//             abnormal_count INTEGER NOT NULL,
//             has_urgent INTEGER NOT NULL DEFAULT 0,
//             ocr_text TEXT NOT NULL,
//             result_json TEXT NOT NULL,
//             image_path TEXT,
//             schema_version INTEGER NOT NULL DEFAULT 1
//           )
//         ''');
//         await db.execute(
//           'CREATE INDEX idx_reports_created ON reports(created_at DESC)',
//         );
//       },
//       // Future schema changes: bump `version` and add an onUpgrade migration.
//     );
//   }
// }
