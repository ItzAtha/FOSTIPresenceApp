import 'package:attendance_management/core/app_constants.dart';
import 'package:material_ui/material_ui.dart';

class AppAboutDialog extends StatelessWidget {
  final Widget? applicationIcon;
  final String? applicationName;
  final String? applicationVersion;
  final String? applicationLegalese;
  final List<Widget>? children;

  const AppAboutDialog({
    super.key,
    this.applicationIcon,
    this.applicationName,
    this.applicationVersion,
    this.applicationLegalese,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? bodyMedium = theme.textTheme.bodyMedium;
    final TextStyle? bodySmall = theme.textTheme.bodySmall;

    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (applicationIcon != null)
                  Padding(padding: const EdgeInsets.only(right: 16.0), child: applicationIcon),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (applicationName != null)
                        Text(applicationName!, style: theme.textTheme.headlineSmall),
                      if (applicationVersion != null) Text(applicationVersion!, style: bodyMedium),
                      const SizedBox(height: 8.0),
                      if (applicationLegalese != null) Text(applicationLegalese!, style: bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (children != null) ...[const SizedBox(height: 16.0), ...children!],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: Theme.of(context).textButtonTheme.style
              ?.copyWith(foregroundColor: WidgetStatePropertyAll(AppColors.dangerZone)),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
