import 'package:attendance_management/core/translations/locale_keys.g.dart';
import 'package:attendance_management/features/dashboard/views/faq/member_excel_upload_faq_viewer.dart';
import 'package:attendance_management/features/dashboard/widgets/faq_expansion_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_constants.dart';
import 'faq/member_attendance_faq_viewer.dart';
import 'faq/member_register_faq_viewer.dart';

class FrequentlyAskQuestionPage extends StatefulWidget {
  const FrequentlyAskQuestionPage({super.key});

  @override
  State<FrequentlyAskQuestionPage> createState() => _FrequentlyAskQuestionPageState();
}

class _FrequentlyAskQuestionPageState extends State<FrequentlyAskQuestionPage> {
  bool isFAQOpened = false;

  final List<FaqExpansionTile> faqList = [
    FaqExpansionTile(
      title: LocaleKeys.setting_page_support_about_faq_about_app_title,
      description: Text(LocaleKeys.setting_page_support_about_faq_about_app_description.tr()),
    ),
    const FaqExpansionTile(
      title: LocaleKeys.setting_page_support_about_faq_register_member_title,
      description: MemberRegisterFAQViewer(),
    ),
    const FaqExpansionTile(
      title: LocaleKeys.setting_page_support_about_faq_upload_excel_file_title,
      description: MemberExcelUploadFAQViewer(),
    ),
    const FaqExpansionTile(
      title: LocaleKeys.setting_page_support_about_faq_attendance_member_title,
      description: MemberAttendanceFAQViewer(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.setting_page_support_about_faq_title.tr(context: context)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: BackButton(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: ListView.builder(
            itemCount: faqList.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0)),
                ),
                child: faqList[index],
              );
            },
          ),
        ),
      ),
    );
  }
}
