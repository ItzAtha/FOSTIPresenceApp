import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_constants.dart';
import '../../../core/translations/locale_keys.g.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  Future<String> _loadPrivacyPolicy() async {
    return await rootBundle.loadString('assets/legality/privacy_policy.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.setting_page_support_about_privacy_policy_title.tr(context: context),
        ),
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
        child: FutureBuilder<String>(
          future: _loadPrivacyPolicy(),
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
                      LocaleKeys.setting_page_support_about_privacy_policy_data_state_loading.tr(
                        context: context,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  LocaleKeys.setting_page_support_about_privacy_policy_data_state_error.tr(
                    context: context,
                    namedArgs: {'error': snapshot.error.toString()},
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return Scrollbar(
                child: Markdown(
                  data:
                      snapshot.data ??
                      LocaleKeys.setting_page_support_about_privacy_policy_data_state_no_data.tr(
                        context: context,
                      ),
                  padding: const EdgeInsets.all(AppSizes.p16),
                  physics: const BouncingScrollPhysics(),
                  onTapLink: (text, url, title) {
                    if (url != null) {
                      launchUrl(Uri.parse(url));
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.5),
                    h1: Theme.of(context).textTheme.titleLarge,
                    h2: Theme.of(context).textTheme.titleMedium,
                    listBullet: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.5),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
