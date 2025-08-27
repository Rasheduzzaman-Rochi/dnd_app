import 'package:flutter/material.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

void main() {
  runApp(const MaterialApp(home: DndApp(), debugShowCheckedModeBanner: false));
}

class DndApp extends StatefulWidget {
  const DndApp({super.key});

  @override
  State<DndApp> createState() => _DndAppState();
}

class _DndAppState extends State<DndApp> {
  final _dndPlugin = DoNotDisturbPlugin();
  bool _isDndEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkDndEnabled();
  }

  Future<void> _checkDndEnabled() async {
    try {
      final bool isDndEnabled = await _dndPlugin.isDndEnabled();
      setState(() {
        _isDndEnabled = isDndEnabled;
      });
    } catch (e) {
      print('Error checking DND status: $e');
    }
  }

  Future<void> _toggleDndMode() async {
    try {
      final bool hasAccess = await _dndPlugin
          .isNotificationPolicyAccessGranted();

      if (!hasAccess) {
        await _dndPlugin.openNotificationPolicyAccessSettings();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please grant notification policy access.'),
            ),
          );
        }
        return;
      }

      if (_isDndEnabled) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      } else {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.alarms);
      }
      _checkDndEnabled();
    } catch (e) {
      print('Error toggling DND mode: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Do Not Disturb',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'DND Enabled: $_isDndEnabled',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleDndMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDndEnabled ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _isDndEnabled ? 'Turn DND Off' : 'Turn DND On',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
