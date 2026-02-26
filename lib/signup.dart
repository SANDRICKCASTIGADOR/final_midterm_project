import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("database");
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool enableBiometrics = false;
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  TextEditingController _confirmPassword = TextEditingController();
  String msg = "";

  bool get isDark => box.get("isDark", defaultValue: false);

  void signUp() {
    if (_username.text.trim().isEmpty ||
        _password.text.trim().isEmpty ||
        _confirmPassword.text.trim().isEmpty) {
      setState(() {
        msg = "Please fill in all fields";
      });
      return;
    }

    if (_password.text.trim() != _confirmPassword.text.trim()) {
      setState(() {
        msg = "Passwords do not match";
      });
      return;
    }

    if (_password.text.trim().length < 6) {
      setState(() {
        msg = "Password must be at least 6 characters";
      });
      return;
    }

    box.put("username", _username.text.trim());
    box.put("password", _password.text.trim());
    box.put("biometrics", enableBiometrics);
    box.put("totalGB", 0.0);

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),

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
                'Create Account',
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
                'Set up your local account',
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
              SizedBox(height: 16),

              // Confirm Password Field
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
                  controller: _confirmPassword,
                  placeholder: "Confirm Password",
                  obscureText: hideConfirmPassword,
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
                      hideConfirmPassword
                          ? CupertinoIcons.eye_fill
                          : CupertinoIcons.eye_slash_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword = !hideConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Biometrics Toggle
              Container(
                padding: EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.hand_raised_fill,
                        color: CupertinoColors.systemBlue,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Biometrics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Quick login with fingerprint',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: enableBiometrics,
                      activeColor: CupertinoColors.systemBlue,
                      onChanged: (value) {
                        setState(() {
                          enableBiometrics = value;
                        });
                      },
                    ),
                  ],
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

              // Sign Up Button
              GestureDetector(
                onTap: signUp,
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
                      'Create Account',
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
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}