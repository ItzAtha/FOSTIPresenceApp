import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';

class MembersExcelViewerPage extends StatefulWidget {
  final String title;
  final Map<String, List<List<String>>> excelData;

  const MembersExcelViewerPage({super.key, required this.title, required this.excelData});

  @override
  State<MembersExcelViewerPage> createState() => _MembersExcelViewerPageState();
}

class _MembersExcelViewerPageState extends State<MembersExcelViewerPage> {
  List<Widget> createExcelTable() {
    List<Widget> tables = [];

    widget.excelData.forEach((division, data) {
      if (data.isEmpty) return;

      final int maxColumns = data.fold(0, (max, row) => row.length > max ? row.length : max);

      tables.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(division, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade400, width: 1.5),
                defaultColumnWidth: const IntrinsicColumnWidth(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: data.asMap().entries.map((entry) {
                  final int rowIndex = entry.key;
                  final List<String> row = entry.value;

                  final paddedRow = List<String>.from(row);
                  while (paddedRow.length < maxColumns) {
                    paddedRow.add('');
                  }

                  final isHeader = rowIndex % 2 == 0;

                  return TableRow(
                    decoration: isHeader ? BoxDecoration(color: Colors.grey.shade800) : null,
                    children: paddedRow.map((cell) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(cell, style: Theme.of(context).textTheme.labelMedium),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });

    return tables;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members Excel Viewer'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: BackButton(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: createExcelTable(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
