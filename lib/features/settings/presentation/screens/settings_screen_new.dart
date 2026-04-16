import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knowvas/features/settings/presentation/widgets/account_settings_tab.dart';
import 'package:knowvas/features/settings/presentation/widgets/security_settings_tab.dart';
import 'package:knowvas/features/settings/presentation/widgets/billing_settings_tab.dart';
import 'package:knowvas/features/settings/presentation/widgets/preferences_settings_tab.dart';
import 'package:knowvas/features/settings/presentation/widgets/devices_tab.dart';
import 'package:knowvas/features/settings/presentation/widgets/notifications_tab.dart';
import 'package:knowvas/features/settings/presentation/widgets/help_about_tab.dart';

class SettingsScreenNew extends StatefulWidget {
  const SettingsScreenNew({super.key});

  @override
  State<SettingsScreenNew> createState() => _SettingsScreenNewState();
}

class _SettingsScreenNewState extends State<SettingsScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FAFB), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                color: Colors.grey[100]?.withOpacity(0.5),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF8B5CF6),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF8B5CF6),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.person, size: 20),
                      text: 'Account',
                    ),
                    Tab(
                      icon: Icon(Icons.shield, size: 20),
                      text: 'Security',
                    ),
                    Tab(
                      icon: Icon(Icons.credit_card, size: 20),
                      text: 'Billing',
                    ),
                    Tab(
                      icon: Icon(Icons.palette, size: 20),
                      text: 'Preferences',
                    ),
                    Tab(
                      icon: Icon(Icons.devices, size: 20),
                      text: 'Devices',
                    ),
                    Tab(
                      icon: Icon(Icons.notifications, size: 20),
                      text: 'Notifications',
                    ),
                    Tab(
                      icon: Icon(Icons.help_outline, size: 20),
                      text: 'Help',
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Account Tab
                    const AccountSettingsTab(),

                    // Security Tab
                    const SecuritySettingsTab(),

                    // Billing Tab
                    const BillingSettingsTab(),

                    // Preferences Tab
                    const PreferencesSettingsTab(),

                    // Devices Tab
                    const DevicesTab(),

                    // Notifications Tab
                    const NotificationsTab(),

                    // Help & About Tab
                    const HelpAboutTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '$title settings',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

