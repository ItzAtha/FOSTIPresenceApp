import 'dart:convert';
import 'dart:io';

import 'package:attendance_management/utilities/string_similar.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MembersData {
  final List<Excel> _workbooks = [];

  final List<String> divisionList = [
    "Keilmuan dan Riset Teknologi",
    "Hubungan Publik",
    "Keorganisasian",
    "RisTek",
    "HubPub",
    "Keor",
  ];

  Future<bool> loadData() async {
    List<FileSystemEntity> entities = [];
    List<File> files = [];

    Directory? appDocDir = await getExternalStorageDirectory();
    entities = appDocDir != null ? appDocDir.listSync(recursive: true) : [];

    files = entities.whereType<File>().where((e) => e.path.endsWith(".xlsx")).toList();
    print(files.map((file) => file.path).toList());

    for (var file in files) {
      List<int> bytes = await file.readAsBytes();
      try {
        Excel workbook = Excel.decodeBytes(bytes);
        _workbooks.add(workbook);
        print("Data loaded from ${file.path} | Excel file name: ${path.basename(file.path)}");
      } catch (e) {
        print("Error decoding Excel file ${file.path}: $e. Skipping....");
      }
    }

    if (_workbooks.isEmpty) {
      print("No Excel files found in the directory.");
      return false;
    }

    print("Total Excel files loaded: ${_workbooks.length}");
    return true;
  }

  Map<String, List<List<String>>> _getStudentsList() {
    List<CellIndex> startIdColumns = [];
    Map<String, List<List<String>>> studentsDataMap = {};

    for (var workbook in _workbooks) {
      Map<String, List<List<String>>> workbookDataMap = {};

      if (workbook.sheets.isEmpty) {
        print("No sheets found in the workbook.");
        continue;
      }

      Iterable<Sheet> worksheets = workbook.sheets.values;
      for (var worksheet in worksheets) {
        startIdColumns.clear();

        if (worksheet.rows.isEmpty) {
          print("No rows found in the worksheet ${worksheet.sheetName}.");
          continue;
        }

        for (var rows in worksheet.rows) {
          for (var cell in rows) {
            if (cell == null) continue;

            bool hasMatch = divisionList.any(
                  (division) => StringSimilar.jaccardSimilarity(cell.value.toString(), division) >= 0.8,
            );

            if (hasMatch) {
              print("Found Division on Index ${cell.cellIndex} | Value: ${cell.value}");
              startIdColumns.add(cell.cellIndex);
              break;
            }
          }
        }

        for (var startIdColumn in startIdColumns) {
          String divName = worksheet
              .cell(
            CellIndex.indexByColumnRow(
              columnIndex: startIdColumn.columnIndex,
              rowIndex: startIdColumn.rowIndex,
            ),
          )
              .value
              .toString();
          List<List<String>> studentsData = [];

          print("$divName Start ID Column: ${startIdColumn.columnIndex}, Row: ${startIdColumn.rowIndex}");
          int columnIndex = startIdColumn.columnIndex;
          int rowIndex = startIdColumn.rowIndex;

          for (int row = rowIndex; row < worksheet.maxRows; row++) {
            List<String> tempStudentsData = [];

            for (int column = columnIndex + 1; column < worksheet.maxColumns; column++) {
              var cell = worksheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row));

              if (cell.value == null || row == rowIndex + 1) continue;
              print("Cell at Row: $row, Col: $column has value: ${cell.value}");
              tempStudentsData.add(cell.value.toString());
            }

            if (tempStudentsData.isNotEmpty) {
              studentsData.add(tempStudentsData);
            }
            print("==================================================================");

            var cell = worksheet.cell(
              CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: row),
            );
            if (cell.value == null) {
              workbookDataMap[divName] = studentsData;
              break;
            }
          }
        }
      }

      print(
        "===================================================================================================",
      );
      workbookDataMap.forEach((key, value) {
        print("Division: $key");
        for (var student in value) {
          print("Student Data: ${student.toString()}");
        }
      });
      print(
        "===================================================================================================",
      );

      if (studentsDataMap.isEmpty) {
        studentsDataMap = workbookDataMap;
      } else {
        workbookDataMap.forEach((key, value) {
          if (studentsDataMap.containsKey(key)) {
            studentsDataMap[key]!.addAll(value);
          } else {
            studentsDataMap[key] = value;
          }
        });
      }
    }
    
    String encodedData = jsonEncode(studentsDataMap);
    print("Encoded Students Data: $encodedData");
    return studentsDataMap;
  }

  List<String> findStudentByNIM(String nim) {
    List<String> foundStudent = [];
    Map<String, List<List<String>>> studentsDataMap = _getStudentsList();

    studentsDataMap.forEach((division, studentsList) {
      for (var student in studentsList) {
        if (student.isNotEmpty && student[1] == nim) {
          if (StringSimilar.jaccardSimilarity(division, "Keilmuan dan Riset Teknologi") >= 0.8) {
            division = "RISTEK";
          } else if (StringSimilar.jaccardSimilarity(division, "Hubungan Publik") >= 0.8) {
            division = "HUBPUB";
          } else if (StringSimilar.jaccardSimilarity(division, "Keorganisasian") >= 0.8) {
            division = "KEOR";
          }

          foundStudent.add(division);
          foundStudent.addAll(student);
          print("Found Student in Division $division: ${student.toString()}");
          break;
        }
      }
    });

    if (foundStudent.isEmpty) {
      print("No Student found with NIM: $nim");
    }

    return foundStudent.sublist(0, 3);
  }
}
