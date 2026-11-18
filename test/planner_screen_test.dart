import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iloilo_planner/home_screen.dart';
import 'package:iloilo_planner/planner_screen.dart';
import 'package:iloilo_planner/schedule_trip_screen.dart';
import 'package:iloilo_planner/scheduled_trip.dart';
import 'package:iloilo_planner/search_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

final _preferences = InMemorySharedPreferencesAsync.empty();

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = _preferences;
    await _preferences.clear(
      const ClearPreferencesParameters(filter: PreferencesFilters()),
      const SharedPreferencesOptions(),
    );
  });

  ScheduledTrip trip({String destination = 'ILOMOCA'}) => ScheduledTrip(
    id: ScheduledTripStore.createId(),
    destination: destination,
    location: 'Casa de Emperador, Mandurriao',
    dateTime: DateTime(2026, 11, 19, 13),
  );

  testWidgets(
    'planner header displays the planner logo at the requested size',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
      await tester.pumpAndSettle();

      final headerLogo = tester.widget<Image>(find.byType(Image).first);
      expect(
        (headerLogo.image as AssetImage).assetName,
        'assets/images/planner.png',
      );
      expect(tester.getSize(find.byType(Image).first), const Size(135, 35));
    },
  );

  testWidgets('scheduled trip cards show details without destination photos', (
    tester,
  ) async {
    await ScheduledTripStore.add(trip());
    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/search-ilomoca.jpg',
      ),
      findsNothing,
    );
    expect(find.text('ILOMOCA'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
  });

  testWidgets('planner header and trips share a scrollable area', (
    tester,
  ) async {
    for (var index = 0; index < 8; index++) {
      await ScheduledTripStore.add(trip(destination: 'Trip $index'));
    }

    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle();

    final header = find.byType(Image).first;
    final initialHeaderTop = tester.getTopLeft(header).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -50));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(initialHeaderTop));
  });

  testWidgets('planner end message and plan button follow the trip list', (
    tester,
  ) async {
    for (var index = 0; index < 8; index++) {
      await ScheduledTripStore.add(trip(destination: 'Trip $index'));
    }

    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle();

    final endMessage = find.text('No more scheduled trips.');
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Trip 7'),
      250,
      scrollable: scrollable,
    );
    await tester.scrollUntilVisible(endMessage, 250, scrollable: scrollable);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(endMessage).dy, lessThan(600));
    expect(find.text('Plan Trip'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation before removing a trip', (
    tester,
  ) async {
    final scheduledTrip = trip();
    await ScheduledTripStore.add(scheduledTrip);
    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Delete scheduled trip?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('ILOMOCA'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('ILOMOCA'), findsNothing);
    expect(await ScheduledTripStore.load(), isEmpty);
  });

  testWidgets('marking visited removes only that trip from the planner', (
    tester,
  ) async {
    final firstTrip = trip();
    final secondTrip = trip(destination: 'ILOMOCA repeat visit');
    await ScheduledTripStore.add(firstTrip);
    await ScheduledTripStore.add(secondTrip);
    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_circle_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('ILOMOCA'), findsNothing);
    expect(find.text('ILOMOCA repeat visit'), findsOneWidget);
    final remainingTrips = await ScheduledTripStore.load();
    expect(remainingTrips, hasLength(1));
    expect(remainingTrips.single.id, secondTrip.id);
  });

  testWidgets('editing a trip saves changes without creating another trip', (
    tester,
  ) async {
    final scheduledTrip = trip();
    await ScheduledTripStore.add(scheduledTrip);
    await tester.pumpWidget(const MaterialApp(home: PlannerScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_note).first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Schedule Trip'), findsOneWidget);

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Trip updated!'), findsOneWidget);

    await tester.tap(find.text('Back to Planner').last);
    await tester.pumpAndSettle();

    final trips = await ScheduledTripStore.load();
    expect(trips, hasLength(1));
    expect(trips.single.id, scheduledTrip.id);
  });

  testWidgets('edit screen navigation opens the selected tab', (tester) async {
    await ScheduledTripStore.add(trip());
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_month_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_note).first);
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleTripScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleTripScreen), findsNothing);
    expect(find.byType(PlannerScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_note).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.travel_explore).last);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
  });
}
