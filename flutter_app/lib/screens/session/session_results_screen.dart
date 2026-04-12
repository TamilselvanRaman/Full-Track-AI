// lib/screens/session/session_results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/session_provider.dart';

class SessionResultsScreen extends ConsumerWidget {
  final int? sessionId;
  const SessionResultsScreen({super.key, this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session   = ref.watch(sessionProvider);
    final deliveries = session.deliveries;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.currentSession?.name ?? 'Session Results'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
      ),
      body: deliveries.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cyclone,
                      size: 60, color: Color(AppConstants.textSecondaryValue)),
                  SizedBox(height: 16),
                  Text('No deliveries recorded yet.',
                      style: TextStyle(color: Color(AppConstants.textSecondaryValue))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: deliveries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = deliveries[index];
                return _DeliveryCard(
                  delivery: d,
                  onTap: d.isComplete
                      ? () => context.go(
                            '/delivery/results?filename=${d.filename}&deliveryId=${d.number}',
                          )
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        onPressed: () => context.go('/session/camera?sessionId=$sessionId'),
        icon: const Icon(Icons.videocam),
        label: const Text('Continue Recording'),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryStatus delivery;
  final VoidCallback? onTap;
  const _DeliveryCard({required this.delivery, this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = delivery.isComplete;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(AppConstants.cardBgColorValue),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done
                ? const Color(AppConstants.accentGreenValue).withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: done
                    ? const Color(AppConstants.accentGreenValue).withOpacity(0.12)
                    : const Color(AppConstants.surfaceColorValue),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${delivery.number}',
                  style: TextStyle(
                    color: done
                        ? const Color(AppConstants.accentGreenValue)
                        : const Color(AppConstants.textSecondaryValue),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ball ${delivery.number}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    done ? 'Analysis complete — tap to view' : 'Processing...',
                    style: TextStyle(
                      color: done
                          ? const Color(AppConstants.accentGreenValue)
                          : const Color(AppConstants.textSecondaryValue),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (done)
              const Icon(Icons.arrow_forward_ios,
                  color: Color(AppConstants.accentGreenValue), size: 16)
            else
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(AppConstants.textSecondaryValue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
