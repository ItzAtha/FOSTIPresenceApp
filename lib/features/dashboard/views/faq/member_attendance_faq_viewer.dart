import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_constants.dart';

class MemberAttendanceFAQViewer extends StatefulWidget {
  const MemberAttendanceFAQViewer({super.key});

  @override
  State<MemberAttendanceFAQViewer> createState() => _MemberAttendanceFAQViewerState();
}

class _MemberAttendanceFAQViewerState extends State<MemberAttendanceFAQViewer> {
  late final Future<String> memberAttendanceDataFuture;

  @override
  void initState() {
    super.initState();
    memberAttendanceDataFuture = rootBundle.loadString('assets/faq/member_attendance_faq.md');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: memberAttendanceDataFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: ValueListenableBuilder(
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
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading member attendance FAQ:\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        } else {
          return SizedBox(
            height: 300.0,
            child: Scrollbar(
              child: Markdown(
                data: snapshot.data ?? 'No member attendance FAQ available.',
                padding: const EdgeInsets.all(AppSizes.p8),
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.5),
                  h1: Theme.of(context).textTheme.titleLarge,
                  h2: Theme.of(context).textTheme.titleMedium,
                  listBullet: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
