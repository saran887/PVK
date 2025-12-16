import 'dart:io';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options_local.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  // Read Excel file
  final file = File('D:\\pkv2\\ANIL FOODS ORDER FORMAT-sri vishnu.xlsx');
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  print('Reading Excel file...');
  print('Sheets: ${excel.tables.keys.join(", ")}');

  // Get the first sheet
  final sheet = excel.tables[excel.tables.keys.first];
  
  if (sheet == null) {
    print('No sheet found!');
    return;
  }

  print('Total rows: ${sheet.maxRows}');
  print('Total columns: ${sheet.maxColumns}');
  
  // Print headers to understand structure
  print('\n=== Headers ===');
  final headerRow = sheet.rows.first;
  for (var i = 0; i < headerRow.length; i++) {
    final cell = headerRow[i];
    print('Column $i: ${cell?.value}');
  }
  
  // Print first few data rows to understand structure
  print('\n=== First 5 Data Rows ===');
  for (var i = 1; i < (sheet.maxRows < 6 ? sheet.maxRows : 6); i++) {
    final row = sheet.rows[i];
    print('Row $i:');
    for (var j = 0; j < row.length; j++) {
      final cell = row[j];
      if (cell?.value != null) {
        print('  Column $j: ${cell?.value}');
      }
    }
    print('---');
  }

  print('\nPlease review the structure above.');
  print('Update the script with correct column indices for:');
  print('- Product ID');
  print('- Product Name');
  print('- Category');
  print('- Price');
  print('- Any other fields');
}
