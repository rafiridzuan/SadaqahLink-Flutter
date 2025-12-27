import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sadaqahlink/widgets/background_wrapper.dart';
import 'package:sadaqahlink/widgets/blurred_app_bar.dart';
import 'package:sadaqahlink/screens/dashboard_screen.dart';
import 'package:sadaqahlink/screens/donation_box_screen.dart';
import 'package:sadaqahlink/screens/profile_screen.dart';
import 'package:sadaqahlink/screens/report_screen.dart';
import 'package:sadaqahlink/screens/statistics_screen.dart';
import 'package:sadaqahlink/screens/transactions_screen.dart';
import 'package:sadaqahlink/screens/users_screen.dart';
import 'package:provider/provider.dart';
import 'package:sadaqahlink/services/auth_service.dart';
import 'package:sadaqahlink/services/database_service.dart';
import 'package:sadaqahlink/utils/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _databaseService.listenForNotifications();
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    StatisticsScreen(),
    ReportScreen(),
  ];

  void _onMenuSelected(String value) {
    switch (value) {
      case 'transactions':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionsScreen()),
        );
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case 'donation_box':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonationBoxScreen()),
        );
        break;
      case 'users':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UsersScreen()),
        );
        break;
      case 'logout':
        showDialog(
          context: context,
          builder: (context) {
            final localizations = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(localizations.get('logout')),
              content: Text(localizations.get('logout_confirmation')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.get('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Provider.of<AuthService>(context, listen: false).signOut();
                  },
                  child: Text(
                    localizations.get('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // Allow body to extend behind navbar
        appBar: BlurredAppBar(
          title: Consumer<AuthService>(
            builder: (context, auth, _) {
              final user = auth.userModel;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SadaqahLink',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (user != null)
                    Text(
                      '${user.role.toLowerCase() == 'ajk' ? 'AJK' : user.role} | ${user.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                ],
              );
            },
          ),
          centerTitle: false,
          actions: [
            PopupMenuButton<String>(
              onSelected: _onMenuSelected,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (BuildContext context) {
                final localizations = AppLocalizations.of(context);
                final user = Provider.of<AuthService>(
                  context,
                  listen: false,
                ).userModel;
                final isAdmin = user?.role.toLowerCase() == 'admin';

                return [
                  PopupMenuItem(
                    value: 'transactions',
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 8),
                        Text(localizations.get('transactions')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 8),
                        Text(localizations.get('settings')),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    PopupMenuItem(
                      value: 'donation_box',
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          Text(localizations.get('donation_box_wifi')),
                        ],
                      ),
                    ),
                  if (isAdmin)
                    PopupMenuItem(
                      value: 'users',
                      child: Row(
                        children: [
                          Icon(
                            Icons.group_add,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          Text(localizations.get('users')),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          localizations.get('logout'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: 24,
            ), // Lower and floating
            height: 70, // Increased height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                35,
              ), // Adjusted for new height
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.4), // Frosty border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Foggy blur
                child: Container(
                  decoration: BoxDecoration(
                    // Foggy Glass Effect - Lower opacity (25%)
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E).withOpacity(0.25)
                        : Colors.white.withOpacity(0.25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Use Expanded to prevent shifting
                      Expanded(
                        child: _buildGlassMenuItem(
                          context,
                          index: 0,
                          icon: Icons.dashboard_rounded,
                          label: AppLocalizations.of(context).get('dashboard'),
                          isSelected: _currentIndex == 0,
                        ),
                      ),
                      Expanded(
                        child: _buildGlassMenuItem(
                          context,
                          index: 1,
                          icon: Icons.bar_chart_rounded,
                          label: AppLocalizations.of(context).get('statistics'),
                          isSelected: _currentIndex == 1,
                        ),
                      ),
                      Expanded(
                        child: _buildGlassMenuItem(
                          context,
                          index: 2,
                          icon: Icons.analytics_outlined,
                          label: AppLocalizations.of(context).get('report'),
                          isSelected: _currentIndex == 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassMenuItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    // Active Color Logic: Light Blue for Dark Mode
    final Color selectedColor = Theme.of(context).brightness == Brightness.dark
        ? Colors
              .lightBlueAccent // Alert/Pop color for Dark Mode
        : Theme.of(context).primaryColor;

    final Color unselectedColor =
        Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent, // Hit test
        height: double.infinity, // Fill Expanded height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Animated "Liquid Bubble" Background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  height: isSelected ? 40 : 0,
                  width: isSelected ? 40 : 0,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withOpacity(0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                // Icon (Always visible, centered)
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0, // Slight scale only, no jump
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    color: isSelected ? selectedColor : unselectedColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            // Text Label
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selectedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
