import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'translations.dart';
import 'food_feature_strings.dart';

class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;
  static const supportedLocales = [Locale('ru'), Locale('en')];
  static const delegate = _StringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('ru'));
  String text(String source) {
    if (locale.languageCode != 'en') return source;
    final direct = foodFeatureEnglish[source] ?? english[source];
    if (direct != null) return direct;
    for (final entry in templates.entries) {
      final parts = entry.key.split(RegExp(r'\{\d+\}'));
      final pattern = '^${parts.map(RegExp.escape).join('(.*?)')}\$';
      final match = RegExp(pattern, dotAll: true).firstMatch(source);
      if (match != null) {
        var result = entry.value;
        for (var i = 1; i <= match.groupCount; i++) {
          result = result.replaceAll('{${i - 1}}', text(match.group(i)!));
        }
        return result;
      }
    }
    // Compound labels (units, source attribution, macro abbreviations).
    var result = source;
    for (final entry in fragments.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}

extension AppTranslation on BuildContext {
  String tr(String source) => AppStrings.of(this).text(source);
  String get languageCode =>
      Localizations.maybeLocaleOf(this)?.languageCode ?? 'ru';
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) => ['ru', 'en'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}

/// Translates complete UI strings and leaves user-entered content untouched.
class QText extends StatelessWidget {
  const QText(this.data,
      {super.key,
      this.style,
      this.textAlign,
      this.maxLines,
      this.overflow,
      this.softWrap,
      this.semanticsLabel});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) => Text(context.tr(data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel:
          semanticsLabel == null ? null : context.tr(semanticsLabel!));
}
