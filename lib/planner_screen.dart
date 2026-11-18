import 'package:flutter/material.dart';

import 'schedule_trip_screen.dart';
import 'scheduled_trip.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  static const _green = Color(0xFF406735);
  static const _buttonGreen = Color(0xFF55995C);
  static const _muted = Color(0xFF777777);

  List<ScheduledTrip> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await ScheduledTripStore.load();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load scheduled trips: $error');
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editTrip(ScheduledTrip trip) async {
    final result = await Navigator.of(context).push<Object>(
      MaterialPageRoute<Object>(
        builder:
            (context) => ScheduleTripScreen(
              destination: trip.destination,
              location: trip.location,
              existingTrip: trip,
            ),
      ),
    );
    if (!mounted || result == null) return;
    if (result is ScheduledTrip) {
      await _loadTrips();
    } else if (result is int) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _deleteTrip(ScheduledTrip trip) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFC6D5C4)),
            ),
            title: const Text(
              'Delete scheduled trip?',
              style: TextStyle(color: _green, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Remove ${trip.destination} from your planner?',
              style: const TextStyle(color: Color(0xFF404040)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB64040),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;
    try {
      await ScheduledTripStore.remove(trip.id);
      await _loadTrips();
      if (mounted) _showMessage('${trip.destination} was removed.');
    } catch (error) {
      if (mounted) _showMessage('Could not delete the trip: $error');
    }
  }

  Future<void> _markVisited(ScheduledTrip trip) async {
    try {
      await ScheduledTripStore.remove(trip.id);
      await _loadTrips();
      if (mounted) _showMessage('${trip.destination} marked as visited.');
    } catch (error) {
      if (mounted) _showMessage('Could not update the trip: $error');
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 84,
      width: double.infinity,
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
      child: Center(
        child: Image.asset(
          'assets/images/planner.png',
          width: 135,
          height: 35,
          fit: BoxFit.contain,
          semanticLabel: 'Planner',
        ),
      ),
    );
  }

  Widget _buildTripHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: _green, size: 24),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Upcoming Trips',
                  style: TextStyle(
                    color: _green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage your scheduled visits.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
          Text(
            _trips.length.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: _green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(ScheduledTrip trip, int index) {
    final labels = MaterialLocalizations.of(context);
    final date = labels.formatShortDate(trip.dateTime);
    final time = TimeOfDay.fromDateTime(trip.dateTime).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E2D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 168),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _green,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.destination,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _detail(Icons.calendar_today_outlined, date),
                    const SizedBox(height: 7),
                    _detail(Icons.access_time, time),
                    const SizedBox(height: 7),
                    _detail(Icons.location_on_outlined, trip.location),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 120, color: const Color(0xFFEAEFE8)),
              const SizedBox(width: 8),
              SizedBox(
                width: 68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _action(
                      icon: Icons.check_circle_outline,
                      label: 'Visited',
                      color: _green,
                      backgroundColor: const Color(0xFFEAF3E6),
                      onPressed: () => _markVisited(trip),
                    ),
                    _action(
                      icon: Icons.close,
                      label: 'Delete',
                      color: const Color(0xFFD94A4A),
                      backgroundColor: const Color(0xFFFCEEEE),
                      onPressed: () => _deleteTrip(trip),
                    ),
                    _action(
                      icon: Icons.edit_note,
                      label: 'Edit',
                      color: const Color(0xFF1687D9),
                      backgroundColor: const Color(0xFFEAF4FB),
                      onPressed: () => _editTrip(trip),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _green),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanTripButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pop(1),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Plan Trip',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(150, 42),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = [..._trips]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: _green),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: _buildTripHeading(),
                        ),
                      ),
                    ),
                    if (trips.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No upcoming trips.',
                                style: TextStyle(color: _muted),
                              ),
                              const SizedBox(height: 16),
                              _buildPlanTripButton(),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 20, bottom: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 430,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: _buildTripCard(trips[index], index),
                                ),
                              ),
                            ),
                            childCount: trips.length,
                          ),
                        ),
                      ),
                    if (trips.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'No more scheduled trips.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                                  _buildPlanTripButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) Navigator.of(context).pop(index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: _green,
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
    );
  }
}
