import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_auth.dart';

class ScheduledTrip {
  const ScheduledTrip({
    this.id = '',
    required this.destination,
    required this.location,
    required this.dateTime,
    this.createdAt,
  });

  final String id;
  final String destination;
  final String location;
  final DateTime dateTime;
  final DateTime? createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'destination': destination,
    'location': location,
    'dateTime': dateTime.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory ScheduledTrip.fromJson(Map<String, dynamic> json) {
    return ScheduledTrip(
      id: json['id'] as String? ?? '',
      destination: json['destination'] as String,
      location: json['location'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      createdAt:
          json['createdAt'] == null
              ? null
              : DateTime.parse(json['createdAt'] as String),
    );
  }
}

class VisitedPlace {
  const VisitedPlace({
    required this.destination,
    required this.location,
    required this.visitedAt,
  });

  final String destination;
  final String location;
  final DateTime visitedAt;

  Map<String, Object> toJson() => {
    'destination': destination,
    'location': location,
    'visitedAt': visitedAt.toIso8601String(),
  };

  factory VisitedPlace.fromJson(Map<String, dynamic> json) {
    return VisitedPlace(
      destination: json['destination'] as String,
      location: json['location'] as String,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
    );
  }
}

class SearchNavigationResult {
  const SearchNavigationResult({required this.selectedTab, this.focusDate});

  final int selectedTab;
  final DateTime? focusDate;
}

class ScheduledTripStore {
  // Trips used to be one shared list. They are now saved per account, so
  // the old list is moved to the first account that opens it.
  static const _legacyStorageKey = 'iloilo.scheduledTrips.v1';
  static final _storage = SharedPreferencesAsync();
  static var _lastIdTimestamp = 0;

  // Every key ends with the signed-in email so accounts never share data.
  static Future<String> _scope() async =>
      await LocalAuth.currentEmail() ?? 'guest';

  static Future<String> _storageKey() async =>
      'iloilo.scheduledTrips.v2.${await _scope()}';

  static Future<String> _readNotificationsKey() async =>
      'iloilo.readNotifications.v2.${await _scope()}';

  static Future<String> _visitedKey() async =>
      'iloilo.visitedPlaces.v1.${await _scope()}';

  static String createId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastIdTimestamp = now > _lastIdTimestamp ? now : _lastIdTimestamp + 1;
    return 'trip-$_lastIdTimestamp';
  }

  static Future<List<ScheduledTrip>> load() async {
    final key = await _storageKey();
    var saved = await _storage.getString(key);
    if (saved == null) {
      final legacy = await _storage.getString(_legacyStorageKey);
      if (legacy != null && legacy.isNotEmpty) {
        await _storage.setString(key, legacy);
        await _storage.remove(_legacyStorageKey);
        saved = legacy;
      }
    }
    if (saved == null || saved.isEmpty) return [];

    final decoded = jsonDecode(saved) as List<dynamic>;
    final trips =
        decoded
            .map((item) => ScheduledTrip.fromJson(item as Map<String, dynamic>))
            .toList();
    var changed = false;
    final normalized =
        trips.map((trip) {
          if (trip.id.isNotEmpty && trip.createdAt != null) return trip;
          changed = true;
          return ScheduledTrip(
            id: trip.id.isEmpty ? createId() : trip.id,
            destination: trip.destination,
            location: trip.location,
            dateTime: trip.dateTime,
            createdAt: trip.createdAt ?? DateTime.now(),
          );
        }).toList();
    if (changed) await _save(normalized);
    return normalized;
  }

  static Future<Set<String>> loadReadNotificationIds() async {
    final ids = await _storage.getStringList(await _readNotificationsKey());
    return ids?.toSet() ?? <String>{};
  }

  static Future<void> markNotificationsRead(
    Iterable<ScheduledTrip> trips,
  ) async {
    final readIds = await loadReadNotificationIds();
    readIds.addAll(trips.map((trip) => trip.id));
    await _storage.setStringList(
      await _readNotificationsKey(),
      readIds.toList(),
    );
  }

  static Future<void> add(ScheduledTrip trip) async {
    final trips = await load();
    trips.add(
      ScheduledTrip(
        id: trip.id.isEmpty ? createId() : trip.id,
        destination: trip.destination,
        location: trip.location,
        dateTime: trip.dateTime,
        createdAt: trip.createdAt ?? DateTime.now(),
      ),
    );
    await _save(trips);
  }

  static Future<void> update(ScheduledTrip updatedTrip) async {
    final trips = await load();
    final index = trips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (index == -1) {
      throw StateError('The scheduled trip no longer exists.');
    }
    trips[index] = ScheduledTrip(
      id: updatedTrip.id,
      destination: updatedTrip.destination,
      location: updatedTrip.location,
      dateTime: updatedTrip.dateTime,
      createdAt: updatedTrip.createdAt ?? trips[index].createdAt,
    );
    await _save(trips);
    await _clearReadNotificationId(updatedTrip.id);
  }

  static Future<void> remove(String tripId) async {
    final trips = await load();
    final remaining = trips.where((trip) => trip.id != tripId).toList();
    if (remaining.length == trips.length) {
      throw StateError('The scheduled trip no longer exists.');
    }
    await _save(remaining);
    await _clearReadNotificationId(tripId);
  }

  static Future<void> _clearReadNotificationId(String tripId) async {
    final readIds = await loadReadNotificationIds();
    if (!readIds.remove(tripId)) return;
    await _storage.setStringList(
      await _readNotificationsKey(),
      readIds.toList(),
    );
  }

  static Future<void> _save(List<ScheduledTrip> trips) async {
    trips.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _storage.setString(
      await _storageKey(),
      jsonEncode(trips.map((item) => item.toJson()).toList()),
    );
  }

  static Future<List<VisitedPlace>> loadVisited() async {
    final saved = await _storage.getString(await _visitedKey());
    if (saved == null || saved.isEmpty) return [];

    final decoded = jsonDecode(saved) as List<dynamic>;
    final places =
        decoded
            .map((item) => VisitedPlace.fromJson(item as Map<String, dynamic>))
            .toList();
    places.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    return places;
  }

  // Removes the trip from the planner and records the place as visited.
  // A place that was visited before is kept once, with the newest date.
  static Future<void> markVisited(ScheduledTrip trip) async {
    await remove(trip.id);

    final visited = await loadVisited();
    visited.removeWhere((place) => place.destination == trip.destination);
    visited.add(
      VisitedPlace(
        destination: trip.destination,
        location: trip.location,
        visitedAt: DateTime.now(),
      ),
    );
    await _storage.setString(
      await _visitedKey(),
      jsonEncode(visited.map((item) => item.toJson()).toList()),
    );
  }
}
