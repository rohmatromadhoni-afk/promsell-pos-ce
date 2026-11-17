import 'package:flutter/widgets.dart';

/// Minimal bilingual text helper for the accounts screens.
///
/// The rest of the app uses ARB files; these screens deliberately keep their
/// strings here so the account feature can ship without touching all three
/// translation files at once.
class AccountText {
  const AccountText(this.isIndonesian);

  factory AccountText.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AccountText(code == 'id');
  }

  final bool isIndonesian;

  String t(String english, String indonesian) =>
      isIndonesian ? indonesian : english;
}
