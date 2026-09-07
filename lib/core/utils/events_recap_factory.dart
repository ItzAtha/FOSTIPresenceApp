import 'dart:io';

import 'package:attendance_management/shared/models/event_log_model.dart';
import 'package:attendance_management/shared/models/event_model.dart';
import 'package:attendance_management/shared/models/member_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum SaveResult { success, failed, cancel }

class RecapFactory {
  final EventModel _eventData;
  final List<MemberModel> _membersData;
  final List<EventLogModel> _logsData;
  final Excel _workbook;

  int _currentIndexColumn = 0;
  int _startIndexInfoColumn = 0;
  List<int> _excelBytes = [];

  RecapFactory({required this._eventData, required this._membersData, required this._logsData})
    : _workbook = Excel.createExcel();

  Future<RecapFactory?> createExcel() async {
    final String defaultSheet = _workbook.getDefaultSheet() ?? 'Sheet1';
    _workbook.rename(defaultSheet, 'PresenceRecap');
    Sheet worksheet = _workbook['PresenceRecap'];

    // ============[ Header Section ] ============
    CellStyle headerStyle = CellStyle(
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString("#0EA253"),
    );

    Data headerCell = worksheet.cell(CellIndex.indexByString('A1'));
    headerCell.value = TextCellValue(_eventData.title);
    headerCell.cellStyle = headerStyle;
    worksheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));

    // ============[ Sub Header Section ] ============
    CellStyle subHeaderStyle = CellStyle(
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"),
    );

    Data colNIMCell = worksheet.cell(CellIndex.indexByString('A2'));
    colNIMCell.value = TextCellValue("NIM");
    colNIMCell.cellStyle = subHeaderStyle;

    Data colNameCell = worksheet.cell(CellIndex.indexByString('B2'));
    colNameCell.value = TextCellValue("Nama");
    colNameCell.cellStyle = subHeaderStyle;

    Data colDivisionCell = worksheet.cell(CellIndex.indexByString('C2'));
    colDivisionCell.value = TextCellValue("Divisi");
    colDivisionCell.cellStyle = subHeaderStyle;

    Data colLoginDateCell = worksheet.cell(CellIndex.indexByString('D2'));
    colLoginDateCell.value = TextCellValue("Tanggal Masuk");
    colLoginDateCell.cellStyle = subHeaderStyle;

    Data colLogoutDateCell = worksheet.cell(CellIndex.indexByString('E2'));
    colLogoutDateCell.value = TextCellValue("Tanggal Keluar");
    colLogoutDateCell.cellStyle = subHeaderStyle;

    Data colRoleCell = worksheet.cell(CellIndex.indexByString('F2'));
    colRoleCell.value = TextCellValue("Role");
    colRoleCell.cellStyle = subHeaderStyle;

    Data colInfoCell = worksheet.cell(CellIndex.indexByString('G2'));
    colInfoCell.value = TextCellValue("Keterangan");
    colInfoCell.cellStyle = subHeaderStyle;

    worksheet.setColumnWidth(0, 15);
    worksheet.setColumnWidth(1, 50);
    worksheet.setColumnWidth(2, 10);
    worksheet.setColumnWidth(3, 30);
    worksheet.setColumnWidth(4, 30);
    worksheet.setColumnWidth(5, 10);
    worksheet.setColumnWidth(6, 15);
    _currentIndexColumn++;

    // ============[ Content Section ] ============
    for (int i = 0; i < _membersData.length; i++) {
      MemberModel member = _membersData[i];
      EventLogModel eventLog = _logsData.firstWhere((log) => log.cardId == member.cardId);
      String formattedLoginDate = "";
      String formattedLogoutDate = "";

      try {
        formattedLoginDate = DateFormat("dd MMMM yyyy, HH:mm:ss")
            .format(eventLog.loginDate.toLocal());
      } on FormatException {
        print("Warning: Invalid login date format for member ${member.nim}: ${eventLog.loginDate}");
      }

      try {
        formattedLogoutDate = DateFormat("dd MMMM yyyy, HH:mm:ss")
            .format(eventLog.logoutDate.toLocal());
      } on FormatException {
        print(
          "Warning: Invalid logout date format for member ${member.nim}: ${eventLog.logoutDate}",
        );
      }

      worksheet.cell(CellIndex.indexByString('A${i + 3}')).value = TextCellValue(member.nim);

      Data nameCell = worksheet.cell(CellIndex.indexByString('B${i + 3}'));
      nameCell.value = TextCellValue(member.name);
      nameCell.cellStyle = CellStyle(textWrapping: TextWrapping.WrapText);

      worksheet.cell(CellIndex.indexByString('C${i + 3}')).value = TextCellValue(
        member.division.aliases,
      );
      worksheet.cell(CellIndex.indexByString('D${i + 3}')).value = TextCellValue(
        formattedLoginDate,
      );
      worksheet.cell(CellIndex.indexByString('E${i + 3}')).value = TextCellValue(
        formattedLogoutDate,
      );
      worksheet.cell(CellIndex.indexByString('F${i + 3}')).value = TextCellValue(
        eventLog.role.name,
      );
      worksheet.cell(CellIndex.indexByString('G${i + 3}')).value = TextCellValue(
        eventLog.information.name,
      );
      _currentIndexColumn++;
    }

    Border cellBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString("#000000"),
    );

    final startCellIndex = CellIndex.indexByString("A1");
    final lastCellIndex = CellIndex.indexByString("G${_currentIndexColumn + 1}");

    for (int row = startCellIndex.rowIndex; row <= lastCellIndex.rowIndex; row++) {
      for (int column = startCellIndex.columnIndex; column <= lastCellIndex.columnIndex; column++) {
        Data baseCell = worksheet.cell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
        );
        baseCell.cellStyle = (baseCell.cellStyle ?? CellStyle()).copyWith(
          fontFamilyVal: getFontFamily(FontFamily.Abadi_MT_Condensed_Extra_Bold),
          leftBorderVal: cellBorder,
          rightBorderVal: cellBorder,
          topBorderVal: cellBorder,
          bottomBorderVal: cellBorder,
        );
      }
    }
    _startIndexInfoColumn = _currentIndexColumn += 5;

    // ============[ Information Sub Header Section ] ============
    CellStyle subHeaderInfoStyle = CellStyle(
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString("#0EA253"),
    );

    Data subHeaderInfoCell = worksheet.cell(CellIndex.indexByString('F$_startIndexInfoColumn'));
    subHeaderInfoCell.value = TextCellValue("Keterangan");
    subHeaderInfoCell.cellStyle = subHeaderInfoStyle;
    worksheet.merge(
      CellIndex.indexByString('F$_startIndexInfoColumn'),
      CellIndex.indexByString('G$_startIndexInfoColumn'),
    );
    _currentIndexColumn++;

    // ============[ Content Sub Header Section ] ============
    CellStyle infoContentStyle = CellStyle(
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (int i = 0; i < Information.values.length; i++) {
      Information information = Information.values[i];
      String capitalizeName =
          "${information.name[0]}${information.name.substring(1).toLowerCase()}";
      int total = _logsData.where((log) => log.information == information).length;

      Data infoNameCell = worksheet.cell(CellIndex.indexByString('F$_currentIndexColumn'));
      infoNameCell.value = TextCellValue(capitalizeName);
      infoNameCell.cellStyle = infoContentStyle;

      Data infoValueCell = worksheet.cell(CellIndex.indexByString('G$_currentIndexColumn'));
      infoValueCell.value = TextCellValue(total.toString());
      infoValueCell.cellStyle = infoContentStyle;
      _currentIndexColumn++;
    }

    CellStyle totalTextStyle = CellStyle(
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString("#E0E0E0"),
    );

    Data totalText = worksheet.cell(CellIndex.indexByString('F$_currentIndexColumn'));
    totalText.value = TextCellValue("Total");
    totalText.cellStyle = totalTextStyle;

    Data totalValueText = worksheet.cell(CellIndex.indexByString('G$_currentIndexColumn'));
    totalValueText.value = TextCellValue(_logsData.length.toString());
    totalValueText.cellStyle = totalTextStyle;

    final startInfoCellIndex = CellIndex.indexByString("F$_startIndexInfoColumn");
    final lastInfoCellIndex = CellIndex.indexByString("G$_currentIndexColumn");

    for (int row = startInfoCellIndex.rowIndex; row <= lastInfoCellIndex.rowIndex; row++) {
      for (
        int column = startInfoCellIndex.columnIndex;
        column <= lastInfoCellIndex.columnIndex;
        column++
      ) {
        Data baseCell = worksheet.cell(
          CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
        );
        baseCell.cellStyle = (baseCell.cellStyle ?? CellStyle()).copyWith(
          fontFamilyVal: getFontFamily(FontFamily.Abadi_MT_Condensed_Extra_Bold),
          leftBorderVal: cellBorder,
          rightBorderVal: cellBorder,
          topBorderVal: cellBorder,
          bottomBorderVal: cellBorder,
        );
      }
    }

    _excelBytes = _workbook.save()!;
    return this;
  }

  Future<({String? data, SaveResult result})> saveAndOpenExcel() async {
    final String safeTitle = _eventData.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    final String fileName = '$safeTitle.xlsx';

    String localFilePath = '';

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      localFilePath = path.join(appDocDir.path, fileName);
      final File file = File(localFilePath);
      await file.writeAsBytes(_excelBytes, flush: true);
    } catch (e) {
      print("Warning: Could not write local cache file: $e");
      return (data: null, result: SaveResult.failed);
    }

    final Uint8List savedExcelBytes = _excelBytes is Uint8List
        ? _excelBytes as Uint8List
        : Uint8List.fromList(_excelBytes);

    final Uri? savedPath = await FilePicker.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: fileName,
      bytes: savedExcelBytes,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (savedPath == null) {
      return (data: null, result: SaveResult.cancel);
    }
    print("Successfully saved recap excel file as $fileName at $savedPath");

    final String pathToOpen = localFilePath.isNotEmpty ? localFilePath : savedPath.path;
    return (data: pathToOpen, result: SaveResult.success);
  }
}
