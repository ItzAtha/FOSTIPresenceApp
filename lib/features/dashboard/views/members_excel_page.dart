import 'dart:collection';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:attendance_management/features/dashboard/enum/dialog_acceptance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel_plus/excel_plus.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_constants.dart';
import '../../../core/utils/string_similar.dart';
import '../../../routes/app_router.dart';
import '../../../translations/locale_keys.g.dart';
import '../widgets/member_excel_card_widget.dart';

class MembersExcelPage extends StatefulWidget {
  const MembersExcelPage({super.key});

  @override
  State<MembersExcelPage> createState() => _MembersExcelPageState();
}

class _MembersExcelPageState extends State<MembersExcelPage> {
  int currentPage = 1;
  String searchQuery = "";
  bool isLoadingExcelData = false;
  static const int maxEventPerPage = 12;

  Map<File, Excel> workbooks = {};
  Map<String, Map<String, int>> membersTotalList = {};

  PlatformFile? selectedFile;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController excelNameController = TextEditingController();
  final TextEditingController searchBarController = TextEditingController();

  final List<String> divisionList = [
    "Keilmuan dan Riset Teknologi",
    "Hubungan Publik",
    "Keorganisasian",
    "RisTek",
    "HubPub",
    "Keor",
  ];

  Future<bool> loadExcelData() async {
    List<FileSystemEntity> entities = [];
    List<File> files = [];

    Directory? appDocDir = await getExternalStorageDirectory();
    entities = appDocDir != null ? appDocDir.listSync(recursive: true) : [];

    files = entities.whereType<File>().where((e) => e.path.endsWith(".xlsx")).toList();

    if (kDebugMode) {
      debugPrint("File path list: ${files.map((file) => file.path).toList()}");
    }

    for (var file in files) {
      List<int> bytes = await file.readAsBytes();
      try {
        Excel workbook = Excel.decodeBytes(bytes);
        String fileName = path.basename(file.path);
        setState(() {
          workbooks[file] = workbook;
        });

        if (kDebugMode) {
          debugPrint("Data loaded from ${file.path} | Excel file name: $fileName");
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint("Error decoding Excel file ${file.path}: $e. Skipping....");
        }
      }
    }

    if (workbooks.isEmpty) {
      return false;
    }

    if (kDebugMode) {
      debugPrint("Total Excel files loaded: ${workbooks.length}");
    }
    return true;
  }

  Map<String, Map<String, int>> getMembersTotalList() {
    List<CellIndex> startIdColumns = [];
    Map<String, Map<String, int>> workbookDataMap = {};

    for (var workbookEntries in workbooks.entries) {
      File workbookFile = workbookEntries.key;
      String workbookName = path.basename(workbookFile.path);
      Excel workbook = workbookEntries.value;

      Map<String, int> divisionsDataMap = {};

      if (workbook.sheets.isEmpty) {
        if (kDebugMode) {
          debugPrint("No sheets found in the workbook.");
        }
        continue;
      }

      Iterable<Sheet> worksheets = workbook.sheets.values;
      for (var worksheet in worksheets) {
        startIdColumns.clear();

        if (worksheet.rows.isEmpty) {
          if (kDebugMode) {
            debugPrint("No rows found in the worksheet ${worksheet.sheetName}.");
          }
          continue;
        }

        for (var rows in worksheet.rows) {
          for (var cell in rows) {
            if (cell == null) continue;

            bool hasMatch = divisionList.any(
              (division) => StringSimilar.jaccardSimilarity(cell.value.toString(), division) >= 0.8,
            );

            if (hasMatch) {
              startIdColumns.add(cell.cellIndex);
              break;
            }
          }
        }

        for (var startIdColumn in startIdColumns) {
          String divisionName = worksheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: startIdColumn.columnIndex,
                  rowIndex: startIdColumn.rowIndex,
                ),
              )
              .value
              .toString();
          List<List<String>> studentsData = [];

          int columnIndex = startIdColumn.columnIndex;
          int rowIndex = startIdColumn.rowIndex;

          for (int row = rowIndex; row < worksheet.maxRows; row++) {
            List<String> tempStudentsData = [];

            for (int column = columnIndex + 1; column < worksheet.maxColumns; column++) {
              var cell = worksheet.cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
              );

              if (cell.value == null || row == rowIndex + 1) continue;
              tempStudentsData.add(cell.value.toString());
            }

            if (tempStudentsData.isNotEmpty) {
              studentsData.add(tempStudentsData);
            }

            var cell = worksheet.cell(
              CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: row),
            );
            if (cell.value == null) {
              divisionsDataMap[divisionName] = studentsData.length;
              break;
            }
          }
        }
      }

      workbookDataMap[workbookName] = divisionsDataMap;
    }
    return workbookDataMap;
  }

  Map<String, List<List<String>>> getMembersPerDivisions(Excel? workbook) {
    List<CellIndex> startIdColumns = [];
    Map<String, List<List<String>>> membersDataMap = {};

    Map<String, List<List<String>>> workbookDataMap = {};

    if (workbook == null) return workbookDataMap;

    if (workbook.sheets.isEmpty) {
      if (kDebugMode) {
        debugPrint("No sheets found in the workbook.");
      }
      return membersDataMap;
    }

    Iterable<Sheet> worksheets = workbook.sheets.values;
    for (var worksheet in worksheets) {
      startIdColumns.clear();

      if (worksheet.rows.isEmpty) {
        if (kDebugMode) {
          debugPrint("No rows found in the worksheet ${worksheet.sheetName}.");
        }
        continue;
      }

      for (var rows in worksheet.rows) {
        for (var cell in rows) {
          if (cell == null) continue;

          bool hasMatch = divisionList.any(
            (division) => StringSimilar.jaccardSimilarity(cell.value.toString(), division) >= 0.8,
          );

          if (hasMatch) {
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
        List<List<String>> membersData = [];

        int columnIndex = startIdColumn.columnIndex;
        int rowIndex = startIdColumn.rowIndex;

        for (int row = rowIndex; row < worksheet.maxRows; row++) {
          List<String> tempStudentsData = [];

          for (int column = columnIndex + 1; column < worksheet.maxColumns; column++) {
            var cell = worksheet.cell(
              CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
            );

            if (cell.value == null || row == rowIndex + 1) continue;
            tempStudentsData.add(cell.value.toString());
          }

          if (tempStudentsData.isNotEmpty) {
            membersData.add(tempStudentsData);
          }

          var cell = worksheet.cell(
            CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: row),
          );
          if (cell.value == null) {
            workbookDataMap[divName] = membersData;
            break;
          }
        }
      }
    }

    if (membersDataMap.isEmpty) {
      membersDataMap = workbookDataMap;
    } else {
      workbookDataMap.forEach((key, value) {
        if (membersDataMap.containsKey(key)) {
          membersDataMap[key]!.addAll(value);
        } else {
          membersDataMap[key] = value;
        }
      });
    }

    return membersDataMap;
  }

  Future<void> pickExcelFile(FormFieldState<PlatformFile> field) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx']);

    if (file != null) {
      setState(() => selectedFile = file);
      field.didChange(file);
    }
  }

  void validateFormInput() async {
    FormState? form = formKey.currentState;

    if (form != null) {
      if (form.validate()) {
        final String rawFileName = excelNameController.text.isNotEmpty
            ? excelNameController.text
            : (selectedFile?.name ?? "Unknown.xlsx");
        final String safeTitle = rawFileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
        final String fileName = safeTitle.endsWith('.xlsx') ? safeTitle : '$safeTitle.xlsx';

        File file = File(selectedFile!.path!);
        Directory? appDocDir = await getExternalStorageDirectory();
        String newPath = path.join(appDocDir!.path, fileName);

        try {
          File savedFile = await file.copy(newPath);
          List<int> bytes = await savedFile.readAsBytes();
          Excel workbook = Excel.decodeBytes(bytes);

          setState(() {
            workbooks[savedFile] = workbook;
            membersTotalList = getMembersTotalList();
          });

          if (!mounted) return;

          Toastification().show(
            context: context,
            title: Text(LocaleKeys.alert_notify_file_title.tr(context: context)),
            description: Text(
              LocaleKeys.alert_notify_file_description_success_set.tr(
                context: context,
                namedArgs: {'fileName': fileName},
              ),
            ),
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );

          if (kDebugMode) {
            debugPrint("File saved to: ${savedFile.path}");
          }
        } catch (_, trace) {
          if (!mounted) return;

          Toastification().show(
            title: Text(LocaleKeys.alert_notify_file_title.tr(context: context)),
            description: Text(
              LocaleKeys.alert_notify_file_description_fail_set.tr(
                context: context,
                namedArgs: {'fileName': fileName},
              ),
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 2),
            animationDuration: const Duration(milliseconds: 500),
          );

          if (kDebugMode) {
            debugPrintStack(stackTrace: trace, label: "Error saving Excel file");
          }
        }

        if (mounted) context.pop();
      }
    }
  }

  Future<void> excelAddButton() async {
    final theme = Theme.of(context);

    var excelAddForm = AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p8,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p8,
        AppSizes.p24,
        AppSizes.p8,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p12,
        AppSizes.p24,
        AppSizes.p24,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.mediumRounded)),
      ),
      title: const Text("Add Excel Data", textAlign: TextAlign.center),
      content: Form(
        key: formKey,
        canPop: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.all(Radius.circular(AppSizes.smallRounded)),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.8), width: 2.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const FaIcon(FontAwesomeIcons.circleInfo, size: 24.0),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Text(
                          "You can leave the field below blank to create a file name that matches the file you have uploaded.",
                          textAlign: TextAlign.justify,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              TextFormField(
                controller: excelNameController,
                decoration: const InputDecoration(
                  labelText: "Excel Name",
                  hintText: "Daftar Anggota FOSTI 202X.xlsx",
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    child: FaIcon(FontAwesomeIcons.fileLines, size: 24.0),
                  ),
                  suffixText: ".xlsx",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16.0),
              FormField<PlatformFile>(
                validator: (file) {
                  if (file == null) {
                    return 'Please select an Excel file';
                  }
                  return null;
                },
                builder: (field) {
                  final file = field.value ?? selectedFile;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          pickExcelFile(field);
                        },
                        icon: FaIcon(
                          FontAwesomeIcons.upload,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        label: Text(
                          file == null ? 'Choose Excel File' : 'Change Excel File',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48.0)),
                      ),

                      if (file != null) ...[
                        const SizedBox(height: 12.0),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.p16),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppSizes.smallRounded),
                            ),
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.solidFileLines, size: 28.0),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Excel file',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.textTheme.labelSmall?.color?.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              const FaIcon(
                                FontAwesomeIcons.circleCheck,
                                color: Colors.green,
                                size: 20.0,
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (field.hasError) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          field.errorText!,
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.dangerZone),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () => validateFormInput(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 24.0),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  selectedFile = null;
                  excelNameController.clear();
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dangerZone,
                  side: const BorderSide(color: AppColors.dangerZone),
                ),
                child: Text(LocaleKeys.event_page_dialog_button_cancel.tr(context: context)),
              ),
            ),
          ],
        ),
      ],
    );

    showDialog(
      context: context,
      animationStyle: const AnimationStyle(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      ),
      builder: (dialogContext) {
        return excelAddForm;
      },
    );
  }

  Future<void> excelEditButton(String oldFileName, File fileData) async {
    excelNameController.text = oldFileName;

    var excelEditForm = AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p8,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p8,
        AppSizes.p24,
        AppSizes.p8,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p12,
        AppSizes.p24,
        AppSizes.p24,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.mediumRounded)),
      ),
      title: const Text("Edit Excel Name", textAlign: TextAlign.center),
      content: Form(
        key: formKey,
        canPop: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16.0),
              TextFormField(
                controller: excelNameController,
                decoration: const InputDecoration(
                  labelText: "Excel Name",
                  hintText: "Daftar Anggota FOSTI 202X.xlsx",
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    child: FaIcon(FontAwesomeIcons.fileLines, size: 24.0),
                  ),
                  suffixText: ".xlsx",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  String newFileName = excelNameController.text.endsWith('.xlsx')
                      ? excelNameController.text
                      : '${excelNameController.text}.xlsx';

                  if (newFileName.compareTo(oldFileName) == 0) return;

                  if (await fileData.exists()) {
                    File oldFileData = fileData;

                    try {
                      Directory? appDocDir = await getExternalStorageDirectory();
                      String newFilePath = path.join(appDocDir!.path, newFileName);

                      File newFile = await fileData.rename(newFilePath);

                      final updatedMap = Map.fromEntries(
                        workbooks.entries.map((entry) {
                          if (entry.key == oldFileData) {
                            return MapEntry(newFile, entry.value);
                          }
                          return entry;
                        }),
                      );

                      setState(() {
                        workbooks = updatedMap;
                        membersTotalList = getMembersTotalList();
                      });

                      if (kDebugMode) {
                        debugPrint("File successfully renamed to: ${newFile.path}");
                      }
                    } on FileSystemException catch (_, trace) {
                      if (kDebugMode) {
                        debugPrintStack(stackTrace: trace, label: "Failed to rename file");
                      }
                    }
                  } else {
                    if (kDebugMode) {
                      debugPrint('File does not exist.');
                    }
                  }

                  if (mounted) context.pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text("Edit", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 24.0),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  selectedFile = null;
                  excelNameController.clear();
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dangerZone,
                  side: const BorderSide(color: AppColors.dangerZone),
                ),
                child: Text(LocaleKeys.event_page_dialog_button_cancel.tr(context: context)),
              ),
            ),
          ],
        ),
      ],
    );

    showDialog(
      context: context,
      animationStyle: const AnimationStyle(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      ),
      builder: (dialogContext) {
        return excelEditForm;
      },
    );
  }

  Future<void> excelDeleteButton(File fileData) async {
    final DialogAcceptance answer = await showDialog(
      context: context,
      animationStyle: const AnimationStyle(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      ),
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text("Delete Confirmation", textAlign: TextAlign.center),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              child: Column(
                children: <Widget>[
                  const Text(
                    "Are you sure you want to delete this file?",
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 25.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => dialogContext.pop(DialogAcceptance.YES),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: Text(
                            LocaleKeys.event_page_dialog_button_yes.tr(context: dialogContext),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24.0),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => dialogContext.pop(DialogAcceptance.NO),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.dangerZone,
                            side: const BorderSide(color: AppColors.dangerZone),
                          ),
                          child: Text(
                            LocaleKeys.event_page_dialog_button_no.tr(context: dialogContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (answer == DialogAcceptance.YES) {
      bool isSuccess = false;

      if (!mounted) return;

      File oldFileData = fileData;
      if (await fileData.exists()) {
        try {
          await fileData.delete();
          isSuccess = true;
        } on FileSystemException catch (_, trace) {
          if (kDebugMode) {
            debugPrintStack(stackTrace: trace, label: "Failed to delete Excel file");
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint("File does not exist.");
        }
      }

      if (isSuccess) {
        setState(() => workbooks.remove(oldFileData));

        Toastification().show(
          title: const Text("Excel File"),
          description: const Text("Successfully delete Excel file"),
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
      } else {
        Toastification().show(
          title: const Text("Excel File"),
          description: const Text("Failed to delete Excel file"),
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.bottomCenter,
          autoCloseDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
        );
      }
    }
  }

  Widget loadingExcelData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ValueListenableBuilder(
            valueListenable: AdaptiveTheme.of(context).modeChangeNotifier,
            builder: (_, mode, child) {
              return CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  mode == AdaptiveThemeMode.light
                      ? AppColors.secondary
                      : AppColors.secondary.withValues(alpha: 0.6),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          Text(
            "Load all members data excel from folder...",
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget noExcelData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(AppSizes.p16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const FaIcon(FontAwesomeIcons.userGroup, size: 32.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Text(
                            "Members Excel Data",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8.0),
                    Text(
                      "No members Excel data found! Add a new one member Excel data to see it in here.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8.0),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: () => excelAddButton(),
                      style: ElevatedButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text("Add", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 8.0),
                          FaIcon(FontAwesomeIcons.calendarPlus, size: 20.0, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget noFilteredExcel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const FaIcon(FontAwesomeIcons.fileExcel, size: 32.0),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Text(
                          "No Filtered Excel Found",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 8.0),
                  Text(
                    "Search with another name key",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget hasExcelData() {
    final sortedWorkbooks = SplayTreeMap<File, Excel>.from(workbooks, (a, b) {
      final memberExcelNameA = path.basename(a.path);
      final memberExcelNameB = path.basename(b.path);

      final comparison = memberExcelNameA.compareTo(memberExcelNameB);
      if (comparison != 0) {
        return comparison;
      }

      return a.path.compareTo(b.path);
    });

    List<File> filteredEvents = sortedWorkbooks.keys.where((excel) {
      final memberExcelName = path.basename(excel.path);
      return memberExcelName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    final totalPages = (filteredEvents.length / maxEventPerPage).ceil();
    if (totalPages > 0 && currentPage > totalPages) {
      currentPage = totalPages;
    }

    final startIndex = (currentPage - 1) * maxEventPerPage;
    final endIndex = (startIndex + maxEventPerPage).clamp(0, filteredEvents.length);
    final currentMembersExcel = filteredEvents.sublist(startIndex, endIndex);

    return Column(
      children: <Widget>[
        Container(
          height: 50.0,
          margin: const EdgeInsets.all(AppSizes.p16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SearchBar(
                  controller: searchBarController,
                  leading: const Icon(Icons.search),
                  trailing: <Widget>[
                    if (searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchBarController.clear();
                          setState(() => searchQuery = "");
                        },
                      ),
                  ],
                  hintText: "Search excel file.....",
                  textInputAction: TextInputAction.search,
                  onChanged: (String value) {
                    setState(() {
                      searchQuery = value;
                      currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              SizedBox(
                width: 45.0,
                height: 45.0,
                child: Material(
                  elevation: Theme.of(context).iconButtonTheme.style?.elevation?.resolve({}) ?? 4.0,
                  shape: Theme.of(context).iconButtonTheme.style?.shape?.resolve({}),
                  child: IconButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      excelAddButton();
                    },
                    icon: const FaIcon(FontAwesomeIcons.fileImport, size: 20.0),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraint) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSizes.p16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight - (AppSizes.p16 * 2)),
                  child: IntrinsicHeight(
                    child: Column(
                      children: <Widget>[
                        if (currentMembersExcel.isEmpty) ...[
                          const Spacer(),
                          noFilteredExcel(),
                        ] else
                          AnimationLimiter(
                            child: Column(
                              children: List<Widget>.generate(currentMembersExcel.length, (index) {
                                final memberExcelFile = currentMembersExcel[index];
                                final memberExcelName = path.basename(memberExcelFile.path);
                                final memberExcelData = membersTotalList[memberExcelName] ?? {};

                                final fileWorkbook = workbooks[memberExcelFile];
                                final membersDataPerDivisions = getMembersPerDivisions(
                                  fileWorkbook,
                                );

                                return Column(
                                  children: <Widget>[
                                    AnimationConfiguration.staggeredList(
                                      position: index,
                                      delay: const Duration(milliseconds: 300),
                                      duration: const Duration(milliseconds: 800),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: MemberExcelCardWidget(
                                            name: memberExcelName,
                                            data: memberExcelData,
                                            viewButton: () => MemberExcelViewRoute(
                                              title: memberExcelName,
                                              $extra: membersDataPerDivisions,
                                            ).push(context),
                                            editButton: () =>
                                                excelEditButton(memberExcelName, memberExcelFile),
                                            deleteButton: () => excelDeleteButton(memberExcelFile),
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (index < currentMembersExcel.length - 1)
                                      const SizedBox(height: 16.0),
                                  ],
                                );
                              }),
                            ),
                          ),
                        const SizedBox(height: 16.0),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            previousPageButton(),
                            const SizedBox(width: 20.0),
                            Text(
                              LocaleKeys.paginating_page_info.tr(
                                context: context,
                                namedArgs: {'current': '$currentPage', 'total': '$totalPages'},
                              ),
                            ),
                            const SizedBox(width: 20.0),
                            nextPageButton(totalPages: totalPages),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).padding.bottom),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget previousPageButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      color: Colors.white,
      style: IconButton.styleFrom(
        minimumSize: const Size(50, 40),
        backgroundColor: currentPage > 1 ? AppColors.primary : Colors.grey,
      ),
      onPressed: currentPage > 1
          ? () {
              setState(() {
                currentPage--;
              });

              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          : null,
    );
  }

  Widget nextPageButton({required int totalPages}) {
    return IconButton(
      icon: const Icon(Icons.arrow_forward_ios),
      color: Colors.white,
      style: IconButton.styleFrom(
        minimumSize: const Size(50, 40),
        backgroundColor: currentPage < totalPages ? AppColors.primary : Colors.grey,
      ),
      onPressed: currentPage < totalPages
          ? () {
              setState(() {
                currentPage++;
              });

              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          : null,
    );
  }

  @override
  void initState() {
    super.initState();

    setState(() => isLoadingExcelData = true);
    loadExcelData()
        .then((success) {
          if (success) {
            if (kDebugMode) {
              debugPrint("Excel data loaded successfully.");
            }

            membersTotalList.addAll(getMembersTotalList());
          } else {
            if (kDebugMode) {
              debugPrint("No Excel files found or failed to load data.");
            }
          }
        })
        .whenComplete(() {
          setState(() => isLoadingExcelData = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members Excel'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: BackButton(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: isLoadingExcelData
          ? loadingExcelData()
          : workbooks.isNotEmpty
          ? hasExcelData()
          : noExcelData(),
    );
  }
}
