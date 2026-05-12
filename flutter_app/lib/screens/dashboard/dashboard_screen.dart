// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_history_provider.dart';
import '../../core/constants.dart';
import '../../services/session_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpinTrack'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF0050CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppConstants.primaryColorValue).withOpacity(0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/spintrack_logo.png', width: 40, height: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to bowl?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create a session and start auto-recording your deliveries.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(AppConstants.primaryColorValue),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => context.go('/session/create'),
                      icon: const Icon(Icons.videocam),
                      label: const Text('Start New Session',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick stats row
              Text('Features', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: const [
                  _FeatureCard(icon: Icons.speed, label: 'Speed\nTracking'),
                  SizedBox(width: 12),
                  _FeatureCard(icon: Icons.blur_circular, label: 'Spin\nAnalysis'),
                  SizedBox(width: 12),
                  _FeatureCard(icon: Icons.map_outlined, label: 'Pitch\nMap'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _FeatureCard(icon: Icons.grid_3x3, label: 'Beehive\nChart'),
                  SizedBox(width: 12),
                  _FeatureCard(icon: Icons.person_pin, label: 'Release\nPoints'),
                  SizedBox(width: 12),
                  _FeatureCard(icon: Icons.auto_awesome, label: 'AI\nAuto-Detect'),
                ],
              ),
              const SizedBox(height: 32),
              
              // Recent Sessions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Sessions', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(sessionHistoryProvider);
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ref.watch(sessionHistoryProvider).when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text("No sessions yet. Start bowling!", style: TextStyle(color: Colors.white54))),
                    );
                  }
                  return ListView.builder(
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                        final dateStr = session.createdAt != null 
                            ? DateFormat('MMM d, yyyy • h:mm a').format(session.createdAt!) 
                            : 'Unknown Date';
                        
                        return Card(
                          color: const Color(AppConstants.cardBgColorValue),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(AppConstants.surfaceColorValue),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.sports_cricket, color: Color(AppConstants.primaryColorValue)),
                            ),
                            title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text('${session.sessionType} • $dateStr\nTap to view details', 
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(AppConstants.cardBgColorValue),
                                    title: const Text('Delete Session?', style: TextStyle(color: Colors.white)),
                                    content: const Text('Are you sure you want to delete this session? This cannot be undone.', style: TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true), 
                                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await SessionService().deleteSession(session.id);
                                    ref.invalidate(sessionHistoryProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
                                    }
                                  }
                                }
                              },
                            ),
                            onTap: () {
                              context.go('/session/results?sessionId=${session.id}');
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) {
                    final errStr = error.toString();
                    if (errStr.contains('401') || errStr.contains('403') || errStr.contains('Unauthorized')) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'Session expired. Please log out and back in.',
                            style: TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Failed to load past sessions: $errStr', style: const TextStyle(color: Colors.redAccent))),
                    );
                  },
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(AppConstants.cardBgColorValue),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(AppConstants.surfaceColorValue), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(AppConstants.primaryColorValue), size: 26),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
