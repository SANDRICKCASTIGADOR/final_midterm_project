import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'homepage.dart';
import 'signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("database");

  await Supabase.initialize(
    url: 'https://cmicgsgbdnrkvxyfcipg.supabase.co',
    anonKey: 'sb_publishable_d_TE-KEGrzP15jPCIJ-R1A_6St9sDgD',
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final box = Hive.box("database");

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDark']),
      builder: (context, Box box, widget) {
        final isDark = box.get("isDark", defaultValue: false);

        return CupertinoApp(
          theme: CupertinoThemeData(
            primaryColor: CupertinoColors.systemBlue,
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          debugShowCheckedModeBanner: false,
          home: (box.get("username") != null) ? LoginPage() : SignupPage(),
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String msg = "";
  bool hidePassword = true;
  final box = Hive.box("database");
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  bool isLoading = false;

  bool get isDark => box.get("isDark", defaultValue: false);

  Future<void> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        setState(() {
          _username.text = box.get("username");
          _password.text = box.get("password");
          msg = "";
        });
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => Homepage()),
        );
      } else {
        setState(() {
          msg = "Cancelled by user";
        });
      }
    } catch (e) {
      setState(() {

        if (e.toString().contains('UserCancel') ||
            e.toString().contains('NotAvailable') ||
            e.toString().contains('cancel')) {
          msg = "Cancelled by user";
        } else {
          msg = "Authentication error: $e";
        }
      });
    }
  }

  Future<void> resetData() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to reset data',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text(
                "Reset All Data?",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "This will delete all registered local data including your account and saved balance.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('Delete All'),
                  onPressed: () {
                    Navigator.pop(context);
                    box.clear();
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          msg = "Authentication failed";
        });
      }
    } catch (e) {
      setState(() {
        msg = "Authentication failed!";
      });
    }
  }

  void signIn() {
    if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
      setState(() {
        msg = "Please enter username and password";
      });
      return;
    }

    if (_username.text.trim() == box.get("username") &&
        _password.text.trim() == box.get("password")) {
      setState(() {
        msg = "";
      });
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => Homepage()),
      );
    } else {
      setState(() {
        msg = "Invalid username or password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CupertinoColors.systemBlue,
                      CupertinoColors.systemBlue.darkColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.wifi,
                    color: CupertinoColors.white,
                    size: 48,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 48),

              // Username Field
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: CupertinoTextField(
                  controller: _username,
                  placeholder: "Username",
                  prefix: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.darkBackgroundGray
                        : CupertinoColors.white,
                    border: Border.all(color: CupertinoColors.transparent),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Password Field
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: CupertinoTextField(
                  controller: _password,
                  placeholder: "Password",
                  obscureText: hidePassword,
                  prefix: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      CupertinoIcons.lock_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.darkBackgroundGray
                        : CupertinoColors.white,
                    border: Border.all(color: CupertinoColors.transparent),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      hidePassword
                          ? CupertinoIcons.eye_fill
                          : CupertinoIcons.eye_slash_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Error Message
              if (msg.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle_fill,
                        color: CupertinoColors.systemRed,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (msg.isNotEmpty) SizedBox(height: 24),

              // Sign In Button
              GestureDetector(
                onTap: isLoading ? null : signIn,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CupertinoColors.systemBlue,
                        CupertinoColors.systemBlue.darkColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemBlue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Biometric Auth Button
              if (box.get("biometrics") == true)
                GestureDetector(
                  onTap: authenticateWithBiometrics,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CupertinoColors.systemBlue.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.hand_raised_fill,
                          color: CupertinoColors.systemBlue,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Use Biometrics',
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (box.get("biometrics") == true) SizedBox(height: 16),

              // Reset Data Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Reset All Data',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: resetData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}