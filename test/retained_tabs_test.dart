import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fitness_dashboard/app/dashboard_shell.dart';

class _Page extends StatefulWidget {
  const _Page(this.index, {super.key});
  final int index;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int count = 0;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(controller: scroll, children: [
        TextButton(
            onPressed: () => setState(() => count++),
            child: Text('page-${widget.index}:$count')),
        for (var i = 0; i < 30; i++)
          SizedBox(height: 80, child: Text('row-${widget.index}-$i')),
      ]);
}

void main() {
  testWidgets(
      'rapid changes paint one opaque tab, keep state and scrolling, disable hidden tickers',
      (tester) async {
    final selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    final pages = List.generate(4, (i) => GlobalKey<_PageState>());
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ValueListenableBuilder<int>(
      valueListenable: selected,
      builder: (_, index, __) => RetainedTabView(
          index: index,
          children: [for (var i = 0; i < 4; i++) _Page(i, key: pages[i])]),
    ))));
    await tester.tap(find.text('page-0:0'));
    await tester.drag(
        find.byType(ListView).hitTestable(), const Offset(0, -220));
    await tester.pumpAndSettle();
    final offset = pages[0].currentState!.scroll.offset;
    final retainedState = pages[0].currentState;
    for (var n = 1; n < 25; n++) {
      selected.value = n % 4;
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(ListView), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        expect(TickerMode.of(pages[i].currentContext!), i == selected.value);
      }
      expect(tester.takeException(), isNull);
    }
    selected.value = 0;
    await tester.pumpAndSettle();
    expect(pages[0].currentState, same(retainedState));
    expect(pages[0].currentState!.count, 1);
    expect(pages[0].currentState!.scroll.offset, offset);
    final view = find.byType(RetainedTabView);
    expect(find.descendant(of: view, matching: find.byType(FadeTransition)),
        findsNothing);
    expect(find.descendant(of: view, matching: find.byType(ScaleTransition)),
        findsNothing);
    final backgrounds = tester.widgetList<ColoredBox>(
        find.descendant(of: view, matching: find.byType(ColoredBox)));
    expect(backgrounds, isNotEmpty);
    expect(backgrounds.every((b) => b.color.a == 1), isTrue);
  });
}
