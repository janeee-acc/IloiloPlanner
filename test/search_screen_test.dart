import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iloilo_planner/search_screen.dart';

void main() {
  testWidgets('tapping the active search tab keeps the screen open', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    await tester.tap(find.byIcon(Icons.travel_explore));
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('requires a location even when no filter is selected', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    expect(find.text('Search a city or area.'), findsOneWidget);
  });

  testWidgets('search without filters shows every place in Mandurriao', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'Mandurriao');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('4 matching places found'), findsOneWidget);
    for (final destination in [
      'ILOMOCA',
      'The Granary',
      'Iloilo River Esplanade',
      'Festive Walk Mall',
    ]) {
      await tester.scrollUntilVisible(
        find.text(destination),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(destination), findsOneWidget);
    }
  });

  testWidgets('other districts show the current supported-area message', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'Jaro');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No places found for Jaro. Only Mandurriao is currently available.',
      ),
      findsOneWidget,
    );
    expect(find.text('ILOMOCA'), findsNothing);
  });

  testWidgets('scheduling a place opens a popup over search results', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'Mandurriao');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    final scheduleButton =
        find.widgetWithText(ElevatedButton, 'Schedule Trip').first;
    await tester.ensureVisible(scheduleButton);
    await tester.tap(scheduleButton);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Schedule Trip'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back to Search'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Results'), findsOneWidget);
  });

  testWidgets('results summary aligns with the search field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'Mandurriao');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    final searchFieldLeft = tester.getTopLeft(find.byType(TextField)).dx;
    expect(tester.getTopLeft(find.text('Results')).dx, searchFieldLeft);
    expect(
      tester.getTopLeft(find.text('4 matching places found')).dx,
      searchFieldLeft,
    );
  });

  testWidgets('search header logo matches the home wordmark size', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    expect(tester.getSize(find.byType(Image).first), const Size(145, 44));
  });

  testWidgets('empty state uses the search image within its icon area', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    final searchIcon = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/images/search-icon.png',
    );
    expect(searchIcon, findsOneWidget);
    expect(tester.getSize(searchIcon), const Size(58, 58));
  });

  testWidgets('empty-state content is centered inside the card', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    final searchIcon = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/images/search-icon.png',
    );
    final description = find.text(
      'Search for tourist spot in Iloilo\nor use filters to discover places.',
    );
    final contentCenter =
        (tester.getRect(searchIcon).left + tester.getRect(description).right) /
        2;
    final screenCenter =
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;
    expect(contentCenter, closeTo(screenCenter, 2));

    final card =
        find
            .ancestor(
              of: description,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.decoration is BoxDecoration &&
                    (widget.decoration as BoxDecoration).color ==
                        const Color(0xFFF0F0F0),
              ),
            )
            .first;
    expect(tester.getSize(card).height, lessThanOrEqualTo(120));
  });

  testWidgets('header, search field, and results share one scrollable area', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'Mandurriao');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    final header = find.byType(Image).first;
    final headerTop = tester.getTopLeft(header).dy;
    final searchFieldTop = tester.getTopLeft(find.byType(TextField)).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(headerTop));
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      lessThan(searchFieldTop),
    );
  });

  testWidgets('requires a location and finds Mandurriao places', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));

    await tester.tap(find.byTooltip('Choose filters'));
    await tester.pumpAndSettle();
    expect(find.text('Historical Sites'), findsOneWidget);
    expect(find.text('Food & Drinks'), findsOneWidget);
    expect(find.text('Nature Parks'), findsOneWidget);
    expect(find.text('Leisure'), findsOneWidget);
    await tester.tap(find.text('Historical Sites').first);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Search a city or area.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mandu');
    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    expect(
      find.text('Enter the correct area name: Mandurriao.'),
      findsOneWidget,
    );
    expect(find.text('ILOMOCA'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Mandurrio');
    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    expect(
      find.text('Enter the correct area name: Mandurriao.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Mandurriao');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('ILOMOCA'), findsOneWidget);
    expect(
      find.text('Casa de Emperador, Festive Walk Parade, Mandurriao'),
      findsOneWidget,
    );
  });

  testWidgets('each category finds its Mandurriao destination', (tester) async {
    const destinations = {
      'Historical Sites': 'ILOMOCA',
      'Food & Drinks': 'The Granary',
      'Nature Parks': 'Iloilo River Esplanade',
      'Leisure': 'Festive Walk Mall',
    };

    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    String? previouslySelected;

    for (final entry in destinations.entries) {
      await tester.tap(find.byTooltip('Choose filters'));
      await tester.pumpAndSettle();
      if (previouslySelected != null) {
        await tester.tap(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text(previouslySelected),
          ),
        );
      }
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text(entry.key),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Mandurriao');
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('No places found in Mandurriao.'), findsNothing);
      previouslySelected = entry.key;
    }
  });

  testWidgets('saving a filter immediately updates existing results', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.enterText(find.byType(TextField), 'Mandurriao');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.text('4 matching places found'), findsOneWidget);

    await tester.tap(find.byTooltip('Choose filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Leisure')),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('1 matching place found'), findsOneWidget);
    expect(find.text('Festive Walk Mall'), findsOneWidget);
    expect(find.text('ILOMOCA'), findsNothing);
  });
}
