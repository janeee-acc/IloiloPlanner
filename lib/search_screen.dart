import 'package:flutter/material.dart';

import 'schedule_trip_screen.dart';
import 'scheduled_trip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _green = Color(0xFF406735);
  static const _navColor = Color(0xFF81869D);
  static const _categories = [
    'Historical Sites',
    'Food & Drinks',
    'Nature Parks',
    'Leisure',
  ];

  final _searchController = TextEditingController();
  Set<String> _selectedCategories = {};
  List<_Place> _results = [];
  bool _hasSearched = false;
  String _emptyResultsMessage = 'No places found in Mandurriao.';
  DateTime? _lastScheduledTripDate;

  static const _places = <_Place>[
    _Place(
      name: 'ILOMOCA',
      category: 'Historical Sites',
      location: 'Casa de Emperador, Festive Walk Parade, Mandurriao',
      hours: 'Tue–Sun, 10 AM–6 PM',
      description:
          'A contemporary art museum featuring local and global works.',
      icon: Icons.museum_outlined,
      imageAsset: 'assets/images/search-ilomoca.jpg',
    ),
    _Place(
      name: 'The Granary',
      category: 'Food & Drinks',
      location: 'Iloilo Business Park, Mandurriao',
      hours: 'Hours may vary',
      description: 'Enjoy a meal at this dining destination in Iloilo.',
      icon: Icons.restaurant_outlined,
      imageAsset: 'assets/images/search-granary.jpg',
    ),
    _Place(
      name: 'Iloilo River Esplanade',
      category: 'Nature Parks',
      location: 'Diversion Road, Mandurriao',
      hours: 'Open daily',
      description: 'Take a relaxing walk along Iloilo River.',
      icon: Icons.park_outlined,
      imageAsset: 'assets/images/search-esplanade.jpg',
    ),
    _Place(
      name: 'Festive Walk Mall',
      category: 'Leisure',
      location: 'Iloilo Business Park, Mandurriao',
      hours: 'Hours may vary',
      description: 'Explore shops, dining, and entertainment in one place.',
      icon: Icons.local_activity_outlined,
      imageAsset: 'assets/images/search-festive.jpg',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scheduleTrip(_Place place) async {
    final result = await showDialog<ScheduledTrip>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ScheduleTripScreen(
            destination: place.name,
            location: place.location,
            imageAsset: place.imageAsset,
            asDialog: true,
          ),
    );

    if (!mounted || result == null) return;
    setState(() => _lastScheduledTripDate = result.dateTime);
  }

  Future<void> _openFilters() async {
    final selected = Set<String>.of(_selectedCategories);
    final result = await showDialog<Set<String>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 330),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter',
                            style: TextStyle(
                              color: _green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Find the perfect spot for your trip.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF686868),
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final category in _categories)
                            CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -3,
                              ),
                              activeColor: _green,
                              title: Text(
                                category,
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: selected.contains(category),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selected.add(category);
                                  } else {
                                    selected.remove(category);
                                  }
                                });
                              },
                            ),
                          const SizedBox(height: 8),
                          Center(
                            child: ElevatedButton(
                              onPressed:
                                  () => Navigator.of(context).pop(selected),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF55995C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(88, 34),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedCategories = result;
      if (_searchController.text.trim().isEmpty) {
        _hasSearched = false;
        _results = [];
      }
    });
    if (_searchController.text.trim().isNotEmpty) _search();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      _showMessage('Search a city or area.');
      return;
    }

    if (query != 'mandurriao') {
      if (query.startsWith('mandu')) {
        setState(() {
          _hasSearched = false;
          _results = [];
        });
        _showMessage('Enter the correct area name: Mandurriao.');
      } else {
        setState(() {
          _hasSearched = true;
          _results = [];
          _emptyResultsMessage =
              'No places found for ${_searchController.text.trim()}. '
              'Only Mandurriao is currently available.';
        });
      }
      return;
    }

    setState(() {
      _hasSearched = true;
      _emptyResultsMessage = 'No places found in Mandurriao.';
      _results =
          _places
              .where(
                (place) =>
                    _selectedCategories.isEmpty ||
                    _selectedCategories.contains(place.category),
              )
              .toList();
    });
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
          'assets/images/search.png',
          width: 135,
          height: 35,
          fit: BoxFit.contain,
          semanticLabel: 'IloiloPlanner logo',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/search-icon.png',
          width: 58,
          height: 58,
          fit: BoxFit.contain,
          semanticLabel: 'Search destinations',
        ),
        const SizedBox(width: 14),
        const Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Exploring!',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202020),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Search for tourist spot in Iloilo\n'
                'or use filters to discover places.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F2F2F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(_Place place) {
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFB8BAC7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.imageAsset case final imageAsset?)
            Image.asset(
              imageAsset,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              semanticLabel: place.name,
            )
          else
            Container(
              height: 150,
              width: double.infinity,
              color: const Color(0xFFEAF3E6),
              child: Icon(place.icon, size: 56, color: _green),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1687D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        place.category == 'Historical Sites'
                            ? 'HISTORICAL'
                            : place.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _placeDetail(Icons.location_on_outlined, place.location),
                const SizedBox(height: 4),
                _placeDetail(Icons.schedule, place.hours),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '“${place.description}”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, height: 1.3),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _scheduleTrip(place),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF55995C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Schedule Trip',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeDetail(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _green),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 10, height: 1.25)),
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
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (_) => _search(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4F4F4F),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter Iloilo location',
                                      hintStyle: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF777777),
                                      ),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: IconButton(
                                        tooltip: 'Choose filters',
                                        onPressed: _openFilters,
                                        icon: const Icon(
                                          Icons.tune,
                                          size: 20,
                                          color: Color(0xFF7D8792),
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: 'Search',
                                        onPressed: _search,
                                        icon: const Icon(
                                          Icons.search,
                                          size: 22,
                                          color: Color(0xFF777777),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFB8BAC7),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: const BorderSide(
                                          color: _green,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCategories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children:
                                      _selectedCategories
                                          .map(
                                            (category) => Chip(
                                              label: Text(category),
                                              labelStyle: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.white,
                                              ),
                                              backgroundColor: _green,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding: EdgeInsets.zero,
                                              side: BorderSide.none,
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!_hasSearched)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  minHeight: 104,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12000000),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _buildEmptyState(),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (_results.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _emptyResultsMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF686868)),
                              ),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Results',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _green,
                                      ),
                                    ),
                                    Text(
                                      '${_results.length} matching ${_results.length == 1 ? 'place' : 'places'} found',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF686868),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: _buildPlaceCard(_results[index]),
                              ),
                            ),
                          ),
                          childCount: _results.length,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index != 1) {
            Navigator.of(context).pop(
              SearchNavigationResult(
                selectedTab: index,
                focusDate: _lastScheduledTripDate,
              ),
            );
          }
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
    );
  }
}

class _Place {
  const _Place({
    required this.name,
    required this.category,
    required this.location,
    required this.hours,
    required this.description,
    required this.icon,
    this.imageAsset,
  });

  final String name;
  final String category;
  final String location;
  final String hours;
  final String description;
  final IconData icon;
  final String? imageAsset;
}
