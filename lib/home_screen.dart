import 'package:flutter/material.dart';

import 'notification_screen.dart';
import 'planner_screen.dart';
import 'search_screen.dart';
import 'scheduled_trip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const green = Color(0xFF406735);
  static const buttonGreen = Color(0xFF55965C);
  static const muted = Color(0xFF686868);

  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  List<ScheduledTrip> _scheduledTrips = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _loadScheduledTrips();
  }

  Future<void> _loadScheduledTrips({DateTime? focusDate}) async {
    try {
      final trips = await ScheduledTripStore.load();
      if (!mounted) return;
      setState(() {
        _scheduledTrips = trips;
        if (focusDate != null) {
          _selectedDate = DateUtils.dateOnly(focusDate);
          _visibleMonth = DateTime(focusDate.year, focusDate.month);
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not load scheduled trips: $error');
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openNotifications() async {
    late final List<TripReminder> reminders;
    try {
      final trips = await ScheduledTripStore.load();
      final now = DateTime.now();
      reminders =
          trips
              .where((trip) => !trip.dateTime.isBefore(now))
              .map(
                (trip) => TripReminder(
                  destination: trip.destination,
                  location: trip.location,
                  tripDate: trip.dateTime,
                  createdAt: trip.createdAt ?? trip.dateTime,
                ),
              )
              .toList();
    } catch (error) {
      if (mounted) _showMessage('Could not load trip reminders: $error');
      return;
    }

    if (!mounted) return;
    final selectedTab = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (context) => NotificationScreen(reminders: reminders),
      ),
    );

    // The back arrow returns null. A bottom navigation tap returns its index.
    if (!mounted || selectedTab == null) return;
    _onNavigationTap(selectedTab);
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute<Object>(builder: (context) => const SearchScreen()),
    );

    if (!mounted) return;
    if (result is ScheduledTrip) {
      await _loadScheduledTrips(focusDate: result.dateTime);
    } else if (result is SearchNavigationResult) {
      await _loadScheduledTrips(focusDate: result.focusDate);
      if (result.selectedTab != 0 || result.focusDate == null) {
        _onNavigationTap(result.selectedTab);
      }
    } else {
      await _loadScheduledTrips();
      if (result is int) _onNavigationTap(result);
    }
  }

  Future<void> _openPlanner() async {
    final selectedTab = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(builder: (context) => const PlannerScreen()),
    );
    if (!mounted) return;
    await _loadScheduledTrips();
    if (selectedTab != null && selectedTab != 2) {
      _onNavigationTap(selectedTab);
    }
  }

  void _onNavigationTap(int index) {
    switch (index) {
      case 0:
        final today = DateUtils.dateOnly(DateTime.now());
        setState(() {
          _selectedDate = today;
          _visibleMonth = DateTime(today.year, today.month);
        });
        break;
      case 1:
        _openSearch();
        break;
      case 2:
        _openPlanner();
        break;
      case 3:
        _showMessage('Profile will open here.');
        break;
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 42,
            height: 42,
            semanticLabel: 'IloiloPlanner logo',
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/iloilo_planner_text.png',
                width: 145,
                height: 44,
                fit: BoxFit.contain,
                semanticLabel: 'IloiloPlanner',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: green, width: 1.4),
              ),
              child: const Icon(Icons.notifications, color: green, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final labels = MaterialLocalizations.of(context);
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    // Sunday is the first column in this calendar.
    final firstColumn = _visibleMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final weeks = ((firstColumn + daysInMonth) / 7).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC6D5C4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labels.formatMonthYear(_visibleMonth),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: green),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: green),
              ),
            ],
          ),
          Row(
            children: [
              for (final day in weekdays)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var week = 0; week < weeks; week++)
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: _buildDay(
                      week * 7 + column - firstColumn + 1,
                      daysInMonth,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDay(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 42);
    }

    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final isPast = date.isBefore(DateUtils.dateOnly(DateTime.now()));
    final selected = DateUtils.isSameDay(date, _selectedDate);
    final hasScheduledTrip = _scheduledTrips.any(
      (trip) => DateUtils.isSameDay(trip.dateTime, date),
    );

    return Semantics(
      button: !isPast,
      selected: selected,
      label: MaterialLocalizations.of(context).formatFullDate(date),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isPast ? null : () => setState(() => _selectedDate = date),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        selected ? const Color(0xFFEAF3E6) : Colors.transparent,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isPast ? const Color(0xFFAAAAAA) : Colors.black,
                      fontSize: 16,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasScheduledTrip)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripSection() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final trips =
        _scheduledTrips
            .where((trip) => DateUtils.isSameDay(trip.dateTime, _selectedDate))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            trips.isEmpty
                ? (isToday ? 'Today’s Trip' : 'Trips for Selected Date')
                : 'Scheduled Trips',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child:
              trips.isEmpty
                  ? Column(
                    children: [
                      Text(
                        isToday
                            ? 'No trip scheduled today'
                            : 'No trip scheduled for this date',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Choose a place & plan your next trip.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 216,
                        child: ElevatedButton.icon(
                          onPressed: _openSearch,
                          icon: const Icon(Icons.add, size: 19),
                          label: const Text(
                            'Plan Trip',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      for (final trip in trips)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC6D5C4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                color: green,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip.destination,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.location,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: muted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${MaterialLocalizations.of(context).formatMediumDate(trip.dateTime)} · '
                                      '${TimeOfDay.fromDateTime(trip.dateTime).format(context)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: 216,
                        child: ElevatedButton.icon(
                          onPressed: _openSearch,
                          icon: const Icon(Icons.add, size: 19),
                          label: const Text(
                            'Plan Another Trip',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Trip Calendar',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'View your scheduled trips.',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCalendar(),
                            const SizedBox(height: 30),
                            _buildTripSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFB8BAC7))),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: _onNavigationTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: green,
          unselectedItemColor: const Color(0xFF81869D),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.travel_explore),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'My Planner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
