import 'package:flutter/material.dart';
import 'package:do_not_disturb/do_not_disturb.dart';

void main() {
  runApp(const DndApp());
}

class DndApp extends StatelessWidget {
  const DndApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Do Not Disturb',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DndHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DndHomePage extends StatefulWidget {
  const DndHomePage({super.key});

  @override
  State<DndHomePage> createState() => _DndHomePageState();
}

class _DndHomePageState extends State<DndHomePage> {
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
    // First, check for permission, as this is a prerequisite and can't be optimistic.
    try {
      final bool hasAccess =
          await _dndPlugin.isNotificationPolicyAccessGranted();

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
    } catch (e) {
      print('Error checking notification policy access: $e');
      // Optionally show an error to the user
      return;
    }

    // Optimistic UI update
    final bool previousState = _isDndEnabled;
    setState(() {
      _isDndEnabled = !previousState;
    });

    // Perform the async operation
    try {
      if (previousState) {
        // If it was enabled, disable it
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      } else {
        // If it was disabled, enable it
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.alarms);
      }
      // After the operation, verify the actual state. This handles cases where the system might not honor the request immediately.
      await _checkDndEnabled();
    } catch (e) {
      print('Error toggling DND mode: $e');
      // If there was an error, revert the UI to the previous state
      setState(() {
        _isDndEnabled = previousState;
      });
      // Optionally, show a message to the user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to change DND mode.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDndEnabled ? Icons.nights_stay : Icons.wb_sunny,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              'Do Not Disturb',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _isDndEnabled ? Colors.red.shade300 : Colors.blue.shade300,
              _isDndEnabled ? Colors.red.shade900 : Colors.blue.shade900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  _isDndEnabled
                      ? Icons.notifications_off
                      : Icons.notifications_active,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  'DND Status: ${_isDndEnabled ? 'Enabled' : 'Disabled'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _toggleDndMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        _isDndEnabled ? Colors.redAccent : Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    _isDndEnabled ? 'Turn DND Off' : 'Turn DND On',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}