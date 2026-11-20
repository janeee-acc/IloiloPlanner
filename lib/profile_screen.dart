import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';
import 'local_auth.dart';
import 'login_screen.dart';
import 'scheduled_trip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _green = Color(0xFF406735);
  static const _muted = Color(0xFF777777);

  UserProfile? _profile;
  List<VisitedPlace> _visited = [];
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await LocalAuth.currentProfile();
      final visited = await ScheduledTripStore.loadVisited();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _visited = visited;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load your profile: $error');
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => EditProfileScreen(profile: profile),
      ),
    );
    if (!mounted || saved != true) return;

    await _load();
    if (mounted) _showMessage('Profile updated.');
  }

  Future<void> _logOut() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await LocalAuth.logout();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      _showMessage('Could not log out: $error');
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/profile.png',
            width: 135,
            height: 35,
            fit: BoxFit.contain,
            semanticLabel: 'Profile',
          ),
          Positioned(
            right: 0,
            child: PopupMenuButton<String>(
              enabled: !_isLoggingOut,
              tooltip: 'Profile options',
              color: const Color(0xFFEAF3E6),
              onSelected: (value) {
                if (value == 'logout') _logOut();
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: _green),
                          SizedBox(width: 8),
                          Text('Log out', style: TextStyle(color: _green)),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // Default avatar: no photo upload yet.
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEAF3E6),
        border: Border.all(color: _green, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 56, color: _green),
    );
  }

  Widget _buildUserInfo(UserProfile profile) {
    final hasBio = profile.bio.isNotEmpty;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Edit profile',
                        child: InkWell(
                          onTap: _editProfile,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Color(0xFF1687D9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            hasBio ? profile.bio : 'No bio yet. Tap the edit icon to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: hasBio ? const Color(0xFF404040) : _muted,
              fontStyle: hasBio ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitedHeading() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: const Color(0xFFF7F7F7),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "All the places you've visited",
              style: TextStyle(fontSize: 12, color: Color(0xFF404040)),
            ),
          ),
          Text(
            _visited.length.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitedGrid() {
    if (_visited.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Text(
          'No visited places yet.\nMark a trip as Visited in My Planner.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.4),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth < 360 ? 1 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 160,
          ),
          itemCount: _visited.length,
          itemBuilder: (context, index) => _buildVisitedCard(_visited[index]),
        );
      },
    );
  }

  Widget _buildVisitedCard(VisitedPlace place) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.destination,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, color: _green, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place.location,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined, color: _green, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Visited ${MaterialLocalizations.of(context).formatMediumDate(place.visitedAt)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }

    final profile = _profile;
    if (profile == null) {
      // The session ended or the account was removed.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are not signed in.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _logOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF55995C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _green,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildUserInfo(profile),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 6,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [_buildVisitedHeading(), _buildVisitedGrid()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [_buildHeader(), Expanded(child: _buildBody())],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          const routes = ['/home', '/search', '/planner', '/profile'];
          Navigator.of(context).pushReplacementNamed(routes[index]);
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
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
