import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

class SearchNavigationResult {
  const SearchNavigationResult({required this.selectedTab, this.focusDate});

  final int selectedTab;
  final DateTime? focusDate;
}

class ScheduledTripStore {
  static const _storageKey = 'iloilo.scheduledTrips.v1';
  static const _readNotificationsKey = 'iloilo.readNotifications.v1';
  static final _storage = SharedPreferencesAsync();
  static var _lastIdTimestamp = 0;

  static String createId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastIdTimestamp = now > _lastIdTimestamp ? now : _lastIdTimestamp + 1;
    return 'trip-$_lastIdTimestamp';
  }

  static Future<List<ScheduledTrip>> load() async {
    final saved = await _storage.getString(_storageKey);
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
    final ids = await _storage.getStringList(_readNotificationsKey);
    return ids?.toSet() ?? <String>{};
  }

  static Future<void> markNotificationsRead(
    Iterable<ScheduledTrip> trips,
  ) async {
    final readIds = await loadReadNotificationIds();
    readIds.addAll(trips.map((trip) => trip.id));
    await _storage.setStringList(_readNotificationsKey, readIds.toList());
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
    await _storage.setStringList(_readNotificationsKey, readIds.toList());
  }

  static Future<void> _save(List<ScheduledTrip> trips) async {
    trips.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _storage.setString(
      _storageKey,
      jsonEncode(trips.map((item) => item.toJson()).toList()),
    );
  }
}
