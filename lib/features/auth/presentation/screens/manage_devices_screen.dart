import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/reveal_animation.dart';

/// Manage Devices Screen - shown when user hits device limit during sign-in.
/// Matches the web app's /auth/manage-devices page exactly.
class ManageDevicesScreen extends ConsumerStatefulWidget {
  const ManageDevicesScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<ManageDevicesScreen> createState() => _ManageDevicesScreenState();
}

class _ManageDevicesScreenState extends ConsumerState<ManageDevicesScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
  String? _error;
  int? _removingId;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get<Map<String, dynamic>>(
        '/api/auth/devices-by-token',
        queryParameters: {'token': widget.token},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as List<dynamic>? ?? [];
        setState(() {
          _devices = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Failed to load devices'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _removeDevice(int deviceId) async {
    final confirmed = await _showConfirmDialog(deviceId);
    if (!confirmed) return;

    setState(() => _removingId = deviceId);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post<Map<String, dynamic>>(
        '/api/auth/devices/$deviceId/sign-out-by-token',
        queryParameters: {'token': widget.token},
      );
      if (response.statusCode == 200) {
        setState(() {
          _devices.removeWhere((d) => d['id'] == deviceId);
          _removingId = null;
        });
      } else {
        final msg = response.data?['error'] as String? ?? 'Failed to remove device';
        setState(() { _error = msg; _removingId = null; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _removingId = null; });
    }
  }

  Future<bool> _showConfirmDialog(int deviceId) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out Device?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This device will be signed out immediately. They\'ll need to log in again to regain access.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Never';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getDeviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('iphone') || n.contains('android') || n.contains('mobile')) return Icons.smartphone;
    if (n.contains('ipad') || n.contains('tablet')) return Icons.tablet;
    return Icons.laptop;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Nav bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/auth/sign-in'),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Back to Login'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.brand600, AppTheme.brand800]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('Knowvas', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      RevealAnimation(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.brand50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, size: 14, color: AppTheme.brand700),
                                  const SizedBox(width: 4),
                                  Text('Device Management', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.brand700)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Manage Your Devices', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                                children: [
                                  const TextSpan(text: "You've reached your device limit. Sign out a device below to free up a slot, then "),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => context.go('/auth/sign-in'),
                                      child: Text('go back to sign in', style: TextStyle(color: AppTheme.brandPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
                          child: Row(children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[800], fontSize: 13))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Loading
                      if (_loading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ))

                      // All cleared
                      else if (_devices.isEmpty)
                        RevealAnimation(
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 32),
                                Container(
                                  width: 72, height: 72,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [Colors.green, Color(0xFF059669)]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
                                ),
                                const SizedBox(height: 20),
                                const Text('All Devices Cleared', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text("You've signed out all devices. You can now sign in on this device.", style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/auth/sign-in'),
                                  icon: const Icon(Icons.login),
                                  label: const Text('Sign In Now'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => context.push('/subscription'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppTheme.brand200),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Upgrade Plan'),
                                ),
                              ],
                            ),
                          ),
                        )

                      // Device list
                      else ...[
                        Text('${_devices.length} ${_devices.length == 1 ? 'device' : 'devices'} signed in', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                        const SizedBox(height: 12),
                        ...List.generate(_devices.length, (i) {
                          final device = _devices[i];
                          final id = device['id'] as int;
                          final name = device['deviceName'] as String? ?? 'Unknown Device';
                          final lastUsed = device['lastUsed'] as String?;
                          final isCurrent = device['isCurrent'] as bool? ?? false;
                          final isRemoving = _removingId == id;

                          return RevealAnimation(
                            delay: Duration(milliseconds: i * 80),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [AppTheme.brand100, AppTheme.brand200]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_getDeviceIcon(name), color: AppTheme.brand600, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis)),
                                              if (isCurrent) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: AppTheme.brand100, borderRadius: BorderRadius.circular(10)),
                                                  child: Text('This device', style: TextStyle(fontSize: 11, color: AppTheme.brand700, fontWeight: FontWeight.w600)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                              const SizedBox(width: 4),
                                              Text(_formatDate(lastUsed), style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isCurrent)
                                      isRemoving
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                          : OutlinedButton(
                                              onPressed: () => _removeDevice(id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red[600],
                                                side: BorderSide(color: Colors.red[200]!),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Sign Out', style: TextStyle(fontSize: 13)),
                                            ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 8),

                        // Info card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sign out devices you no longer use to free up slots. Once done, use the Back to Login link above to sign in on this device.',
                                  style: TextStyle(fontSize: 12, color: Colors.blue[800], height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Upgrade CTA
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.brand600, AppTheme.brand700]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Need more devices?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Upgrade your plan to use multiple devices at once.', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => context.push('/subscription'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.brand600,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: const Text('View Plans', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
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
      ),
    );
  }
}
