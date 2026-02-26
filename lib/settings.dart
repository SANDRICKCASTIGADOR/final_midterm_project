import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final box = Hive.box("database");
  final LocalAuthentication auth = LocalAuthentication();

  // Remove the local isDark variable, use Hive directly
  bool get isDark => box.get("isDark", defaultValue: false);

  Widget tiles(IconData icon, String title, dynamic trailing, Color color) {
    return CupertinoListTile(
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Icon(
          icon,
          size: 15,
          color: CupertinoColors.white,
        ),
      ),
      trailing: trailing,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  void logout() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            "Logout",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "Are you sure you want to logout?",
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
              child: Text('Logout'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? CupertinoColors.black
          : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark
            ? CupertinoColors.darkBackgroundGray.withOpacity(0.95)
            : CupertinoColors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey5.withOpacity(0.15)
                : CupertinoColors.systemGrey5.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 32),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CupertinoColors.systemBlue,
                            CupertinoColors.systemBlue.darkColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemBlue.withOpacity(0.4),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.wifi,
                          color: CupertinoColors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Data Manager",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Version 1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemBlue,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 40),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "ACCOUNT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.systemGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: CupertinoColors.transparent,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? CupertinoColors.black.withOpacity(0.2)
                          : CupertinoColors.systemGrey.withOpacity(0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                children: [
                  tiles(
                    CupertinoIcons.person_fill,
                    box.get("username", defaultValue: "User"),
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: CupertinoColors.systemBlue,
                      size: 20,
                    ),
                    CupertinoColors.systemBlue,
                  ),
                  tiles(
                    CupertinoIcons.chart_bar_fill,
                    "Data Balance",
                    Text(
                      "${box.get("totalGB", defaultValue: 0.0).toStringAsFixed(2)} GB",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                    CupertinoColors.systemGreen,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "APPEARANCE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.systemGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: CupertinoColors.transparent,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? CupertinoColors.black.withOpacity(0.2)
                          : CupertinoColors.systemGrey.withOpacity(0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                children: [
                  tiles(
                    CupertinoIcons.moon_fill,
                    "Dark Mode",
                    CupertinoSwitch(
                      value: isDark,
                      activeColor: CupertinoColors.systemBlue,
                      onChanged: (value) {
                        setState(() {
                          box.put("isDark", value); // Save to Hive
                        });
                      },
                    ),
                    CupertinoColors.systemPurple,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "SECURITY",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.systemGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: CupertinoColors.transparent,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? CupertinoColors.black.withOpacity(0.2)
                          : CupertinoColors.systemGrey.withOpacity(0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                children: [
                  tiles(
                    CupertinoIcons.hand_raised_fill,
                    "Biometrics",
                    CupertinoSwitch(
                      value: box.get("biometrics", defaultValue: false),
                      activeColor: CupertinoColors.systemBlue,
                      onChanged: (value) {
                        setState(() {
                          box.put("biometrics", value);
                        });
                      },
                    ),
                    CupertinoColors.systemGreen,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "GENERAL",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.systemGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: CupertinoListSection.insetGrouped(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                backgroundColor: CupertinoColors.transparent,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? CupertinoColors.black.withOpacity(0.2)
                          : CupertinoColors.systemGrey.withOpacity(0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                children: [
                  GestureDetector(
                    onTap: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: Text(
                              "About Data Manager",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                "Data Manager v1.0.0\n\nManage your mobile data with ease. Purchase data packages securely using Xendit payment gateway.",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: tiles(
                      CupertinoIcons.info_circle_fill,
                      "About",
                      Icon(
                        CupertinoIcons.chevron_forward,
                        color: CupertinoColors.systemGrey2,
                        size: 20,
                      ),
                      CupertinoColors.systemBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: logout,
                    child: tiles(
                      CupertinoIcons.arrow_right_square_fill,
                      "Logout",
                      Icon(
                        CupertinoIcons.chevron_forward,
                        color: CupertinoColors.systemGrey2,
                        size: 20,
                      ),
                      CupertinoColors.systemRed,
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}