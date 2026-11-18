import 'package:flutter/material.dart';

import 'scheduled_trip.dart';

class ScheduleTripScreen extends StatefulWidget {
  const ScheduleTripScreen({
    super.key,
    required this.destination,
    required this.location,
    this.existingTrip,
    this.asDialog = false,
  });

  final String destination;
  final String location;
  final ScheduledTrip? existingTrip;
  final bool asDialog;

  @override
  State<ScheduleTripScreen> createState() => _ScheduleTripScreenState();
}

class _ScheduleTripScreenState extends State<ScheduleTripScreen> {
  static const _green = Color(0xFF406735);
  static const _navColor = Color(0xFF81869D);
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 13, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(
      widget.existingTrip?.dateTime ?? DateTime.now(),
    );
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    final existingTime = widget.existingTrip?.dateTime;
    if (existingTime != null) {
      _selectedTime = TimeOfDay.fromDateTime(existingTime);
    }
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final currentMonth = DateTime.now();
    if (nextMonth.isBefore(DateTime(currentMonth.year, currentMonth.month))) {
      return;
    }
    setState(() => _visibleMonth = nextMonth);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      if (dateTime.isBefore(DateTime.now())) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Choose a future date and time.')),
          );
        return;
      }

      final trip = ScheduledTrip(
        id: widget.existingTrip?.id ?? ScheduledTripStore.createId(),
        destination: widget.destination,
        location: widget.location,
        dateTime: dateTime,
        createdAt: widget.existingTrip?.createdAt,
      );

      if (widget.existingTrip == null) {
        await ScheduledTripStore.add(trip);
      } else {
        await ScheduledTripStore.update(trip);
      }
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFC6D5C4)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: _green, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.existingTrip == null
                          ? 'Trip scheduled!'
                          : 'Trip updated!',
                      style: const TextStyle(
                        color: _green,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                '${trip.destination} has been ${widget.existingTrip == null ? 'added to' : 'updated in'} your planner for '
                '${MaterialLocalizations.of(context).formatMediumDate(trip.dateTime)} '
                'at ${TimeOfDay.fromDateTime(trip.dateTime).format(context)}.',
                style: const TextStyle(color: Color(0xFF404040), height: 1.4),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF55995C),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(42),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.existingTrip == null
                              ? 'Back to Search'
                              : 'Back to Planner',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );

      if (mounted) Navigator.of(context).pop(trip);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save this trip: $error')),
        );
    }
  }

  Widget _buildHeader() {
    if (widget.existingTrip != null) {
      return Container(
        height: 56,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E2E2))),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back to Planner',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: _green),
            ),
            const Expanded(
              child: Text(
                'Edit Schedule Trip',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _green,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );
    }

    return Container(
      height: 84,
      width: double.infinity,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/iloilo_planner_text.png',
            width: 145,
            height: 44,
            fit: BoxFit.contain,
            semanticLabel: 'IloiloPlanner',
          ),
          Positioned(
            left: 8,
            child: IconButton(
              tooltip: 'Back to Search',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: _green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final labels = MaterialLocalizations.of(context);
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final firstColumn = _visibleMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final weeks = ((firstColumn + daysInMonth) / 7).ceil();
    final currentMonth = DateTime.now();
    final canGoBack =
        _visibleMonth.year > currentMonth.year ||
        _visibleMonth.month > currentMonth.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labels.formatMonthYear(_visibleMonth),
                  style: TextStyle(fontSize: widget.asDialog ? 16 : 14),
                ),
              ),
              IconButton(
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: canGoBack ? () => _changeMonth(-1) : null,
                icon: const Icon(Icons.chevron_left, color: _green),
              ),
              IconButton(
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: _green),
              ),
            ],
          ),
          Row(
            children: [
              for (final weekday in weekdays)
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: widget.asDialog ? 10 : 9,
                      color: const Color(0xFF888888),
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
          const Divider(height: 12),
          InkWell(
            onTap: _selectTime,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Time',
                      style: TextStyle(fontSize: widget.asDialog ? 16 : 14),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.asDialog ? 16 : 12,
                        vertical: widget.asDialog ? 8 : 6,
                      ),
                      child: Text(
                        _selectedTime.format(context),
                        style: TextStyle(fontSize: widget.asDialog ? 14 : 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) {
      return SizedBox(height: widget.asDialog ? 42 : 32);
    }
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final isPast = DateUtils.dateOnly(
      date,
    ).isBefore(DateUtils.dateOnly(DateTime.now()));
    final isSelected = DateUtils.isSameDay(date, _selectedDate);

    return Semantics(
      button: !isPast,
      selected: isSelected,
      label: MaterialLocalizations.of(context).formatFullDate(date),
      excludeSemantics: true,
      child: InkWell(
        onTap: isPast ? null : () => setState(() => _selectedDate = date),
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: widget.asDialog ? 42 : 32,
          child: Center(
            child: Container(
              width: widget.asDialog ? 34 : 26,
              height: widget.asDialog ? 34 : 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFFEAF3E6) : Colors.transparent,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: isPast ? const Color(0xFFAAAAAA) : Colors.black,
                  fontSize: widget.asDialog ? 16 : 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = MaterialLocalizations.of(context);
    final currentTab = widget.existingTrip == null ? 1 : 2;

    final formContent = SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration:
              widget.asDialog
                  ? null
                  : BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFC6D5C4)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.existingTrip == null) ...[
                if (widget.asDialog)
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to Search',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: _green),
                      ),
                      const Expanded(
                        child: Text(
                          'Schedule Trip',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _green,
                            fontSize: 22,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  )
                else
                  const Text(
                    'Schedule Trip',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _green,
                      fontSize: 20,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${widget.destination} · ${labels.formatMediumDate(_selectedDate)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.asDialog ? 14 : 12,
                    color: const Color(0xFF686868),
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(minHeight: 76),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.destination,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: _green,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              widget.location,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildCalendar(),
              const SizedBox(height: 10),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.asDialog ? 320 : 300,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF55995C),
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(widget.asDialog ? 44 : 38),
                        elevation: 0,
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                widget.existingTrip == null
                                    ? 'Save'
                                    : 'Save Changes',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final form = widget.asDialog ? formContent : Center(child: formContent);
    final editForm = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: form,
    );

    if (widget.asDialog) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFC6D5C4)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: form,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: widget.existingTrip != null ? editForm : form),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFB8BAC7))),
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) {
            if (index == currentTab) return;
            const routes = ['/', '/search', '/planner', '/profile'];
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
