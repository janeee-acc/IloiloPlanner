import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iloilo_planner/home_screen.dart';
import 'package:iloilo_planner/schedule_trip_screen.dart';
import 'package:iloilo_planner/scheduled_trip.dart';
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

  testWidgets('Home header scrolls with page content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final header = find.byType(Image).first;
    final headerTop = tester.getTopLeft(header).dy;
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, lessThan(headerTop));
  });

  testWidgets('schedule back button returns to the search results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => const ScheduleTripScreen(
                                  destination: 'ILOMOCA',
                                  location: 'Mandurriao',
                                ),
                          ),
                        ),
                    child: const Text('Search results'),
                  ),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Search results'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Search'));
    await tester.pumpAndSettle();
    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Schedule Trip'), findsNothing);
    expect(find.text('Save this trip?'), findsNothing);
  });

  testWidgets('edit back button sits in header and exits without a prompt', (
    tester,
  ) async {
    final tripDate = DateTime.now().add(const Duration(days: 2));
    final scheduledTrip = ScheduledTrip(
      id: ScheduledTripStore.createId(),
      destination: 'ILOMOCA',
      location: 'Casa de Emperador, Mandurriao',
      dateTime: DateTime(tripDate.year, tripDate.month, tripDate.day, 13),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => ScheduleTripScreen(
                                  destination: scheduledTrip.destination,
                                  location: scheduledTrip.location,
                                  existingTrip: scheduledTrip,
                                ),
                          ),
                        ),
                    child: const Text('Open edit'),
                  ),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Open edit'));
    await tester.pumpAndSettle();
    final backButton = find.byTooltip('Back to Planner');
    final headerTitle = find.text('Edit Schedule Trip');
    expect(
      tester.getCenter(backButton).dy,
      closeTo(tester.getCenter(headerTitle).dy, 1),
    );

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Open edit'), findsOneWidget);
    expect(find.text('Save this trip?'), findsNothing);
  });

  testWidgets('same place can be scheduled repeatedly', (tester) async {
    final returnedTrips = <ScheduledTrip>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final trip = await Navigator.of(
                        context,
                      ).push<ScheduledTrip>(
                        MaterialPageRoute<ScheduledTrip>(
                          builder:
                              (_) => const ScheduleTripScreen(
                                destination: 'ILOMOCA',
                                location:
                                    'Casa de Emperador, Festive Walk Parade, Mandurriao',
                              ),
                        ),
                      );
                      if (trip != null) returnedTrips.add(trip);
                    },
                    child: const Text('Open scheduler'),
                  ),
                ),
              ),
        ),
      ),
    );

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Open scheduler'));
      await tester.pumpAndSettle();
      expect(find.text('Schedule Trip'), findsOneWidget);

      final tomorrow = DateUtils.dateOnly(
        DateTime.now(),
      ).add(const Duration(days: 1));
      await tester.tap(find.text('${tomorrow.day}').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Trip scheduled!'), findsOneWidget);
      expect(find.text('Back to Search'), findsOneWidget);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.backgroundColor, Colors.white);
      final dialogWidth = tester.getSize(find.byType(AlertDialog)).width;
      final confirmationButtonWidth =
          tester
              .getSize(find.widgetWithText(ElevatedButton, 'Back to Search'))
              .width;
      expect(confirmationButtonWidth, lessThan(dialogWidth * 0.8));

      await tester.tap(find.text('Back to Search'));
      await tester.pumpAndSettle();
      expect(find.text('Open scheduler'), findsOneWidget);
    }

    final trips = await ScheduledTripStore.load();
    expect(trips, hasLength(2));
    expect(trips.every((trip) => trip.destination == 'ILOMOCA'), isTrue);
    expect(trips.every((trip) => trip.location.contains('Mandurriao')), isTrue);
    expect(returnedTrips, hasLength(2));
    expect(returnedTrips[0].destination, returnedTrips[1].destination);
    expect(returnedTrips[0].dateTime, returnedTrips[1].dateTime);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    final tomorrow = DateUtils.dateOnly(
      DateTime.now(),
    ).add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}').first);
    await tester.pumpAndSettle();
    expect(find.text('ILOMOCA'), findsNWidgets(2));
  });

  testWidgets('Home shows only trips for the selected date', (tester) async {
    final firstDate = DateUtils.dateOnly(DateTime.now());
    final secondDate = firstDate.add(const Duration(days: 1));
    await ScheduledTripStore.add(
      ScheduledTrip(
        destination: 'ILOMOCA',
        location: 'Casa de Emperador, Mandurriao',
        dateTime: DateTime(firstDate.year, firstDate.month, firstDate.day, 13),
      ),
    );
    await ScheduledTripStore.add(
      ScheduledTrip(
        destination: 'ILOMOCA',
        location: 'Casa de Emperador, Mandurriao',
        dateTime: DateTime(
          secondDate.year,
          secondDate.month,
          secondDate.day,
          14,
        ),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ILOMOCA'), findsOneWidget);
    expect(find.textContaining('1:00 PM'), findsOneWidget);
    expect(find.textContaining('2:00 PM'), findsNothing);

    await tester.tap(find.text('${secondDate.day}'));
    await tester.pumpAndSettle();

    expect(find.text('ILOMOCA'), findsOneWidget);
    expect(find.textContaining('1:00 PM'), findsNothing);
    expect(find.textContaining('2:00 PM'), findsOneWidget);

    final allTrips = await ScheduledTripStore.load();
    expect(allTrips, hasLength(2));
    expect(find.text('Scheduled Trips'), findsOneWidget);
  });

  testWidgets('Home marks past dates gray and prevents selecting them', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    await ScheduledTripStore.add(
      ScheduledTrip(
        destination: 'Past trip',
        location: 'Mandurriao',
        dateTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 13),
      ),
    );
    await ScheduledTripStore.add(
      ScheduledTrip(
        destination: 'Today trip',
        location: 'Mandurriao',
        dateTime: DateTime(today.year, today.month, today.day, 14),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final pastDay = find.text('${yesterday.day}');
    expect(tester.widget<Text>(pastDay).style?.color, const Color(0xFFAAAAAA));

    await tester.tap(pastDay);
    await tester.pumpAndSettle();

    expect(find.text('Today trip'), findsOneWidget);
    expect(find.text('Past trip'), findsNothing);
  });

  testWidgets('Home notifications show upcoming scheduled trips', (
    tester,
  ) async {
    final tripDate = DateTime.now().add(const Duration(days: 2));
    await ScheduledTripStore.add(
      ScheduledTrip(
        destination: 'ILOMOCA',
        location: 'Casa de Emperador, Mandurriao',
        dateTime: DateTime(tripDate.year, tripDate.month, tripDate.day, 13),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Trip reminder'), findsOneWidget);
    expect(find.textContaining('Your visit to ILOMOCA'), findsOneWidget);
    expect(find.text('Casa de Emperador, Mandurriao'), findsOneWidget);
  });

  testWidgets('edit schedule summary shows details without an image', (
    tester,
  ) async {
    final tripDate = DateTime.now().add(const Duration(days: 2));
    final scheduledTrip = ScheduledTrip(
      id: ScheduledTripStore.createId(),
      destination: 'ILOMOCA',
      location: 'Casa de Emperador, Festive Walk Parade, Mandurriao',
      dateTime: DateTime(tripDate.year, tripDate.month, tripDate.day, 13),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: ScheduleTripScreen(
          destination: scheduledTrip.destination,
          location: scheduledTrip.location,
          existingTrip: scheduledTrip,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ILOMOCA'), findsOneWidget);
    expect(find.text(scheduledTrip.location), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Scrollbar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cannot save an edit for a time that has already passed', (
    tester,
  ) async {
    final pastDateTime = DateTime.now().subtract(const Duration(hours: 2));
    final scheduledTrip = ScheduledTrip(
      id: ScheduledTripStore.createId(),
      destination: 'ILOMOCA',
      location: 'Casa de Emperador, Mandurriao',
      dateTime: pastDateTime,
    );
    await ScheduledTripStore.add(scheduledTrip);

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleTripScreen(
          destination: scheduledTrip.destination,
          location: scheduledTrip.location,
          existingTrip: scheduledTrip,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a future date and time.'), findsOneWidget);
    final trips = await ScheduledTripStore.load();
    expect(trips, hasLength(1));
    expect(trips.single.dateTime, scheduledTrip.dateTime);
  });
}
