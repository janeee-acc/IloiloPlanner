import 'package:flutter/material.dart';

class TripReminder {
  final String destination;
  final String location;
  final DateTime tripDate;
  final DateTime createdAt;
  final bool isUnread;

  const TripReminder({
    required this.destination,
    required this.location,
    required this.tripDate,
    required this.createdAt,
    this.isUnread = true,
  });
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, this.reminders = const []});

  final List<TripReminder> reminders;

  static const _green = Color(0xFF406735);
  static const _muted = Color(0xFF686868);
  static const _navColor = Color(0xFF81869D);

  String _sectionTitle(BuildContext context, DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    if (DateUtils.isSameDay(date, today)) return 'Today';
    if (DateUtils.isSameDay(date, yesterday)) return 'Yesterday';

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _timeAgo(BuildContext context, DateTime date) {
    final elapsed = DateTime.now().difference(date);

    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  Widget _buildReminderCard(BuildContext context, TripReminder reminder) {
    final labels = MaterialLocalizations.of(context);
    final isToday = DateUtils.isSameDay(reminder.tripDate, DateTime.now());
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = DateUtils.isSameDay(reminder.tripDate, tomorrow);
    final day =
        isToday
            ? 'today'
            : isTomorrow
            ? 'tomorrow'
            : 'on ${labels.formatMediumDate(reminder.tripDate)}';
    final time = TimeOfDay.fromDateTime(reminder.tripDate).format(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDDEED1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: _green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Trip reminder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (reminder.isUnread)
                      Semantics(
                        label: 'Unread',
                        child: const Icon(Icons.circle, size: 8, color: _green),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Your visit to ${reminder.destination} is $day at $time.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reminder.location,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _timeAgo(context, reminder.createdAt),
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(2),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text('View in Planner'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...reminders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              foregroundColor: _green,
              elevation: 0,
              toolbarHeight: 64,
              centerTitle: true,
              leading: IconButton(
                tooltip: 'Back to Home',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Notifications',
                style: TextStyle(
                  color: _green,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.notifications, color: _green),
                ),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFDDDDDD),
                ),
              ),
            ),
            if (sorted.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No trip reminders yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Trip reminders appear here on the day '
                            'before each scheduled trip.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sorted.length; i++) ...[
                            if (i == 0 ||
                                !DateUtils.isSameDay(
                                  sorted[i].createdAt,
                                  sorted[i - 1].createdAt,
                                ))
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 14,
                                ),
                                child: Text(
                                  _sectionTitle(context, sorted[i].createdAt),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: _green,
                                  ),
                                ),
                              ),
                            _buildReminderCard(context, sorted[i]),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 32),
                          const Text(
                            'You’re all caught up',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No more reminders to show.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFB8BAC7))),
        ),
        child: BottomNavigationBar(
          currentIndex: 2,
          onTap: (index) {
            const routes = ['/home', '/search', '/planner', '/profile'];
            Navigator.of(context).pushReplacementNamed(routes[index]);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: _green,
          unselectedItemColor: _navColor,
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
