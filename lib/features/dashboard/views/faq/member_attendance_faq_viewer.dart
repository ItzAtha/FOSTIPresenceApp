import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/translations/locale_keys.g.dart';

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
                  LocaleKeys.setting_page_support_about_faq_attendance_member_data_state_loading.tr(
                    context: context,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              LocaleKeys.setting_page_support_about_faq_attendance_member_data_state_error.tr(
                context: context,
                namedArgs: {'error': snapshot.error.toString()},
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else {
          return SizedBox(
            height: 300.0,
            child: Scrollbar(
              child: Markdown(
                data:
                    snapshot.data ??
                    LocaleKeys.setting_page_support_about_faq_attendance_member_data_state_no_data
                        .tr(context: context),
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
