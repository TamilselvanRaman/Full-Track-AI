// lib/screens/session/create_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/session_provider.dart';
import '../../services/session_service.dart';
import '../../widgets/common/selection_button.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _nameCtrl = TextEditingController(text: 'Session ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}');
  String _sessionType  = 'Solo Session';
  String _bowlingType  = 'Bowling/Throwing';
  String _filmingMethod= 'Tripod';
  double _pitchLength  = 22.0;
  bool _loading = false;

  final _service = SessionService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final session = await _service.createSession(
        name:          _nameCtrl.text.trim(),
        sessionType:   _sessionType,
        bowlingType:   _bowlingType,
        filmingMethod: _filmingMethod,
        pitchLength:   _pitchLength,
      );
      ref.read(sessionProvider.notifier).setSession(session);
      if (mounted) {
        context.go('/session/camera?sessionId=${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating session: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.textSecondaryValue),
            letterSpacing: 1.2,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Session'),
        leading: BackButton(onPressed: () => context.go('/dashboard')),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                    )
                  : TextButton(
                      onPressed: _create,
                      child: const Text(
                        'Create',
                        style: TextStyle(
                          color: Color(AppConstants.primaryColorValue),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('SESSION NAME'),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Morning Practice'),
            ),

            _label('SESSION TYPE'),
            Row(
              children: [
                SelectionButton(
                  label: 'Solo Session',
                  selected: _sessionType == 'Solo Session',
                  onTap: () => setState(() => _sessionType = 'Solo Session'),
                ),
                SelectionButton(
                  label: 'Team Session',
                  selected: _sessionType == 'Team Session',
                  onTap: () => setState(() => _sessionType = 'Team Session'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Use "Team Session" for multiple players.',
              style: TextStyle(fontSize: 12, color: Color(AppConstants.textSecondaryValue)),
            ),

            _label('DELIVERY TYPE'),
            Row(
              children: [
                SelectionButton(
                  label: 'Bowling/Throwing',
                  selected: _bowlingType == 'Bowling/Throwing',
                  onTap: () => setState(() => _bowlingType = 'Bowling/Throwing'),
                ),
                SelectionButton(
                  label: 'Machine',
                  selected: _bowlingType == 'Machine',
                  onTap: () => setState(() => _bowlingType = 'Machine'),
                ),
              ],
            ),

            _label('FILMING METHOD'),
            Row(
              children: [
                SelectionButton(
                  label: 'Tripod',
                  selected: _filmingMethod == 'Tripod',
                  onTap: () => setState(() => _filmingMethod = 'Tripod'),
                ),
                SelectionButton(
                  label: 'Match Umpire Cam',
                  selected: _filmingMethod == 'Match',
                  onTap: () => setState(() => _filmingMethod = 'Match'),
                ),
              ],
            ),

            _label('PITCH LENGTH'),
            const SizedBox(height: 4),
            Text(
              '${_pitchLength.toStringAsFixed(0)} Yards',
              style: const TextStyle(
                  color: Color(AppConstants.primaryColorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Slider(
              value: _pitchLength,
              min: 10,
              max: 30,
              divisions: 20,
              activeColor: const Color(AppConstants.primaryColorValue),
              inactiveColor: const Color(AppConstants.surfaceColorValue),
              onChanged: (v) => setState(() => _pitchLength = v),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loading ? null : _create,
              child: const Text('Create Session ->'),
            ),
          ],
        ),
      ),
    );
  }
}
