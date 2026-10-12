import 'package:attendance_management/features/dashboard/widgets/faq_expansion_tile.dart';
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
    const FaqExpansionTile(
      title: "What is an attendance management app?",
      description: Text(
        "An application designed to help manage members data, events data, and member attendance data "
        "for events organized by the Forum Open Source Teknik Informatika (FOSTI) student organization.",
      ),
    ),
    const FaqExpansionTile(
      title: "How do I register new member with Card ID?",
      description: MemberRegisterFAQViewer(),
    ),
    const FaqExpansionTile(
      title: "How do I upload all members data Excel to used in member registration?",
      description: Text("This FAQ is under construction. Please check back later for updates."),
    ),
    const FaqExpansionTile(
      title: "How do I attendance a member in active event with Card ID?",
      description: MemberAttendanceFAQViewer(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
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
