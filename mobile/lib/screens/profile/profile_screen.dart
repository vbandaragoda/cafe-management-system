import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/contacts_service.dart';
import '../../services/location_service.dart';
import '../../widgets/caffora_bottom_nav.dart';

/// Profile / Settings screen. Hosts the light/dark theme switch, the
/// geolocation "distance to store" sensor feature, and the explicit
/// stored-contacts "Invite a Friend" feature — plus sign-out and the
/// entry point into the Admin console for admin accounts.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _locationService = LocationService();
  final _contactsService = ContactsService();
  String? _locationStatus;
  bool _locationLoading = false;

  Future<void> _checkDistance() async {
    setState(() {
      _locationLoading = true;
      _locationStatus = null;
    });
    final result = await _locationService.getDistanceToStore();
    if (!mounted) return;
    setState(() {
      _locationLoading = false;
      _locationStatus = result.ok
          ? 'You are ${result.distanceKm!.toStringAsFixed(1)} km from the Caffora counter.'
          : result.error;
    });
  }

  Future<void> _inviteFriend() async {
    final contacts = await _contactsService.pickableContacts();
    if (!mounted) return;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No contacts available (permission denied or address book is empty).')));
      return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: contacts.length,
          itemBuilder: (context, i) {
            final c = contacts[i];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
              title: Text(c.displayName.isEmpty ? 'Unnamed contact' : c.displayName),
              onTap: () => Navigator.of(context).pop(c.displayName),
            );
          },
        ),
      ),
    );
    if (chosen != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite ready to send to $chosen ☕')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text('Profile', style: theme.textTheme.headlineMedium)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: theme.colorScheme.primary, child: const Icon(Icons.person_rounded, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.isAuthenticated ? (auth.user?.name ?? '') : 'Guest', style: theme.textTheme.titleLarge),
                    Text(
                      auth.isAuthenticated ? (auth.isAdmin ? 'System Admin' : auth.user?.email ?? '') : 'Not signed in',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel(theme, 'Appearance'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System default'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.mode,
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.mode,
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.mode,
                  onChanged: (m) => themeProvider.setMode(m!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(theme, 'Nearby'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Distance to the Caffora counter')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_locationStatus != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_locationStatus!)),
                  OutlinedButton(
                    onPressed: _locationLoading ? null : _checkDistance,
                    child: _locationLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Use my location'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel(theme, 'Share Caffora'),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.contacts_rounded, color: theme.colorScheme.primary),
              title: const Text('Invite a friend'),
              subtitle: const Text('Pick someone from your contacts'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _inviteFriend,
            ),
          ),
          if (auth.isAdmin) ...[
            const SizedBox(height: 20),
            _sectionLabel(theme, 'Admin'),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings_rounded, color: theme.colorScheme.primary),
                title: const Text('Cafe Manager console'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.admin),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (auth.isAuthenticated)
            OutlinedButton(
              onPressed: () async {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
              },
              child: const Text('Sign out'),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.auth),
              child: const Text('Sign in'),
            ),
        ],
      ),
      bottomNavigationBar: const CafforaBottomNav(currentIndex: 4),
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6)),
    );
  }
}
