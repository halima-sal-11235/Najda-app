import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';


// ---------------------------------------------------------------------------
// CONFIG: use the public "anon" key only, never the service role key
// ---------------------------------------------------------------------------
const supabaseUrl = 'https://lzrqbhunmqeiuehmvkop.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6cnFiaHVubXFlaXVlaG12a29wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMzMDMwMjksImV4cCI6MjEwODg3OTAyOX0.-EjcGpfG8-50g8A1-votOK4HKAfxYkkpuJJvg4Rdp_o';

// 'unconfirmed' needs the status constraint SQL to be applied.
// If you get a "check constraint" error, change it to 'new' for now.
const initialAlertStatus = 'unconfirmed';

// Top-level variables are created lazily, so this is safe after initialize()
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

// ---------------------------------------------------------------------------
// APP: shows the login screen or the home screen depending on the session
// ---------------------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Najda',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session =
              snapshot.data?.session ?? supabase.auth.currentSession;
          return session == null ? const AuthScreen() : HomeScreen();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SERVICES (move them to lib/services/ later)
// ---------------------------------------------------------------------------

/// 0555123456 -> +213555123456
String normalizePhone(String raw) {
  final p = raw.replaceAll(RegExp(r'[\s\-\.]'), '');
  if (p.startsWith('+')) return p;
  if (p.startsWith('00')) return '+${p.substring(2)}';
  if (p.startsWith('0')) return '+213${p.substring(1)}';
  return '+213$p';
}

Future<Position> getCurrentPosition() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw Exception('Turn on location (GPS) on your phone');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Location permission denied');
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
}

/// Creates the alert in Supabase and returns its id.
Future<String> createAlert({
  required double impactG,
  required double speedBeforeKmh,
  String source = 'simulation',
}) async {
  final pos = await getCurrentPosition();
  final row = await supabase
      .from('alerts')
      .insert({
        'user_id': supabase.auth.currentUser?.id,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'impact_g': impactG,
        'speed_before_kmh': speedBeforeKmh,
        'source': source,
        'status': initialAlertStatus,
      })
      .select('id')
      .single();
  return row['id'] as String;
}

/// Used in step 4: cancelled, no_response, ...
Future<void> updateAlertStatus(String alertId, String status) async {
  await supabase.from('alerts').update({'status': status}).eq('id', alertId);
}

String errorText(Object e) {
  if (e is AuthException) return e.message;
  if (e is PostgrestException) return e.message;
  return e.toString().replaceFirst('Exception: ', '');
}

// ---------------------------------------------------------------------------
// SCREEN 1: sign in / sign up
// ---------------------------------------------------------------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.length < 6) {
      _show('Enter an email and a password of at least 6 characters');
      return;
    }
    if (_isSignUp &&
        (_name.text.trim().isEmpty || _phone.text.trim().isEmpty)) {
      _show('Name and phone number are required');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        // full_name and phone are read by the database trigger
        // that creates the row in the profiles table
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': _name.text.trim(),
            'phone': normalizePhone(_phone.text),
          },
        );
        if (res.session == null && mounted) {
          _show(
            'Account created. Check your email to confirm it, then sign in.',
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      // On success the StreamBuilder in MyApp switches to HomeScreen
    } catch (e) {
      if (mounted) _show(errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  //const Icon(Icons.shield, size: 72, color: Colors.red),
                  Image.asset(
  'assets/logonajda.png',
  width: 96,
  height: 96,
  fit: BoxFit.contain,
),   
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Create an account' : 'Sign in',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (_isSignUp) ...[
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number (0555 12 34 56)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Sign up' : 'Sign in'),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'I already have an account'
                          : 'Create an account',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2: home with the "Simulate crash" button
// ---------------------------------------------------------------------------
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   bool _busy = false;
//   String? _lastAlertId;

//   Future<void> _simulateCrash() async {
//     setState(() => _busy = true);
//     try {
//       final id = await createAlert(impactG: 6.2, speedBeforeKmh: 70);
//       if (!mounted) return;
//       setState(() => _lastAlertId = id);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Alert created')));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: ${errorText(e)}')));
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = supabase.auth.currentUser;
//     final name =
//         (user?.userMetadata?['full_name'] as String?) ?? user?.email ?? '';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Accident Alert'),
//         actions: [
//           IconButton(
//             tooltip: 'Sign out',
//             icon: const Icon(Icons.logout),
//             onPressed: () => supabase.auth.signOut(),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Hello $name',
//               style: Theme.of(context).textTheme.titleLarge,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Protection status: inactive (detection comes in step 3)',
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               height: 64,
//               child: FilledButton.icon(
//                 style: FilledButton.styleFrom(backgroundColor: Colors.red),
//                 onPressed: _busy ? null : _simulateCrash,
//                 icon: _busy
//                     ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.warning_amber_rounded),
//                 label: const Text(
//                   'Simulate crash',
//                   style: TextStyle(fontSize: 18),
//                 ),
//               ),
//             ),
//             if (_lastAlertId != null) ...[
//               const SizedBox(height: 24),
//               Text(
//                 'Last alert id:\n$_lastAlertId',
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
