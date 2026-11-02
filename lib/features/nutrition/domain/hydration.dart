/// Estimated water content. Each diary entry stores its own immutable snapshot.
abstract final class Hydration {
  static double validate(double value) {
    if (!value.isFinite || value < 0 || value > 100) {
      throw ArgumentError.value(value, 'waterPercentage', 'Expected 0..100');
    }
    return value;
  }

  static double volume(double grams, double percentage) =>
      grams * validate(percentage) / 100;
  static double detect(String name,
      {Iterable<String> categories = const [], String serving = ''}) {
    final text = name.toLowerCase().replaceAll('ё', 'е');
    final tags = categories.join(' ').toLowerCase();
    bool has(String pattern) => RegExp(pattern, unicode: true).hasMatch(text);
    bool word(String pattern) =>
        has(r'(^|[^а-яa-z])(' + pattern + r')([^а-яa-z]|$)');
    // Dry powders and ready-to-drink shakes are different products.
    if (has(r'сух[а-я]*|порош[а-я]*|powder|dried|dry |сгущен|condensed')) {
      return 0;
    }
    if (has(r'суп|борщ|бульон|окрошк|soup|broth|bouillon') ||
        word('щи') ||
        tags.contains('soups')) {
      return 80;
    }
    final explicitDrink =
        has(r'напиток|коктейль|shake|drink|beverage|chocolate milk|шоколадн[а-я]* молоко|молоко шоколадн[а-я]*') ||
            RegExp(r'beverages|drinks|milks').hasMatch(tags);
    // A dairy ingredient or flavour in a solid food must not count as a drink.
    if (has(r'творог|cottage|пюре|puree|каша|porridge|колбас|sausage|греческ|greek|морожен|ice cream|конфет|печенье|biscuit') ||
        word(r'сыр|cheese') ||
        tags.contains('cheeses') ||
        (has('шоколад|chocolate') && !explicitDrink)) {
      return 0;
    }
    if (has(r'молоко|молочный напиток|кефир|питьевой йогурт|йогурт питьевой|ряженк|экспонент|exponenta|milk|kefir|drinking yogurt|drinking yoghurt|протеинов[а-я]* (коктейль|напиток)|protein (shake|drink)') ||
        tags.contains('milks') ||
        tags.contains('dairy-drinks')) {
      return 88;
    }
    if (word(
        r'сок[а-я]*|морс[а-я]*|компот[а-я]*|нектар[а-я]*|juices?|nectars?')) {
      return 90;
    }
    final zero = has(r'zero|без сахара|sugar.?free|no sugar|diet|light');
    if (word(
            r'кола|cola|пепси|pepsi|газиров[а-я]*|лимонад[а-я]*|lemonade|содовая|энергетик[а-я]*|energy drink|квас|kvass') ||
        tags.contains('carbonated-drinks') ||
        tags.contains('sodas')) {
      return zero ? 98 : 90;
    }
    if (word('вода|воды|water|минералка|минеральная') ||
        tags.contains('waters')) {
      return 100;
    }
    if (word('чай|кофе|tea|coffee') ||
        tags.contains('teas') ||
        tags.contains('coffees')) {
      return has(r'с сахаром|with sugar|sweetened') && !zero ? 90 : 98;
    }
    if (has(r'напиток|drink|beverage|smoothie|смузи') ||
        RegExp(r'beverages|drinks|juices').hasMatch(tags) ||
        RegExp(r'(^|[^a-zа-я])(ml|мл)([^a-zа-я]|$)')
            .hasMatch(('$serving $text').toLowerCase())) {
      return zero ? 98 : 90;
    }
    return 0;
  }
}
