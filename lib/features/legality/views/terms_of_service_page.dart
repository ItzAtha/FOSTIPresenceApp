import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_constants.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  Future<String> _loadTermsOfService() async {
    return await rootBundle.loadString('assets/legality/tos.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
          future: _loadTermsOfService(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading terms: \n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return Scrollbar(
                child: Markdown(
                  data: snapshot.data ?? 'No terms of service available.',
                  padding: const EdgeInsets.all(AppSizes.p16),
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
