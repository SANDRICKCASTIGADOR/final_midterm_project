import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'settings.dart';
import 'orders.dart';
import 'theme.dart';

class LaptopItem {
  final String name, specs, badge, imagePath;
  final int price;
  const LaptopItem({
    required this.name,
    required this.specs,
    required this.price,
    required this.badge,
    required this.imagePath,
  });
}

final List<LaptopItem> laptops = [
  const LaptopItem(
    name: 'Axioo Pongo 735',
    specs: 'i7-13620H · RTX 3050 · 16GB · 144Hz FHD',
    price: 12999,
    badge: 'LOCAL PRIDE',
    imagePath: 'assets/images/xioo_pongo_735.png',
  ),
  const LaptopItem(
    name: 'HP Victus 15',
    specs: 'i5-12450H · RTX 2050 · 8GB · 144Hz FHD',
    price: 13499,
    badge: 'BEST VALUE',
    imagePath: 'assets/images/hp_victus_15.png',
  ),
  const LaptopItem(
    name: 'MSI GF63 Thin',
    specs: 'i7-12650H · RTX 4050 · 16GB · 144Hz IPS',
    price: 18999,
    badge: 'THIN & LIGHT',
    imagePath: 'assets/images/msi_gf63_thin.png',
  ),
  const LaptopItem(
    name: 'Acer Nitro V15',
    specs: 'Ryzen 5 7535HS · RTX 4050 · 8GB · 144Hz',
    price: 16499,
    badge: 'POPULAR',
    imagePath: 'assets/images/acer_nitro_v15.jpg',
  ),
  const LaptopItem(
    name: 'Asus TUF A15',
    specs: 'Ryzen 7 7745HX · RTX 4060 · 16GB · 144Hz',
    price: 21999,
    badge: 'MIL-SPEC',
    imagePath: 'assets/images/asus_tuf_a15.jpg',
  ),
  const LaptopItem(
    name: 'Lenovo LOQ 15',
    specs: 'i7-13650HX · RTX 4060 · 16GB · 165Hz IPS',
    price: 22999,
    badge: 'TOP PICK',
    imagePath: 'assets/images/lenovo_loq_15.jpg',
  ),
];

// ─── A* Pathfinding ────────────────────────────────────────────────────────────
class _Node {
  final int row, col;
  double g, h;
  _Node? parent;
  bool walkable;

  _Node({required this.row, required this.col, this.walkable = true})
      : g = double.infinity,
        h = 0;

  double get f => g + h;

  @override
  bool operator ==(Object o) =>
      o is _Node && o.row == row && o.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

List<(int, int)> aStarPath({
  required int rows,
  required int cols,
  required (int, int) start,
  required (int, int) end,
  Set<(int, int)>? walls,
}) {
  final grid = List.generate(
    rows,
        (r) => List.generate(
      cols,
          (c) => _Node(
        row: r,
        col: c,
        walkable: !(walls?.contains((r, c)) ?? false),
      ),
    ),
  );

  final startNode = grid[start.$1][start.$2]..g = 0;
  final endNode = grid[end.$1][end.$2];
  startNode.h = ((startNode.row - endNode.row).abs() +
      (startNode.col - endNode.col).abs())
      .toDouble();

  final open = <_Node>{startNode};
  final closed = <_Node>{};

  while (open.isNotEmpty) {
    final current = open.reduce((a, b) => a.f < b.f ? a : b);
    if (current == endNode) {
      final path = <(int, int)>[];
      _Node? n = current;
      while (n != null) {
        path.add((n.row, n.col));
        n = n.parent;
      }
      return path.reversed.toList();
    }
    open.remove(current);
    closed.add(current);
    for (final d in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = current.row + d.$1;
      final nc = current.col + d.$2;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
      final nb = grid[nr][nc];
      if (!nb.walkable || closed.contains(nb)) continue;
      final tg = current.g + 1;
      if (tg < nb.g) {
        nb.parent = current;
        nb.g = tg;
        nb.h = ((nb.row - endNode.row).abs() +
            (nb.col - endNode.col).abs())
            .toDouble();
        open.add(nb);
      }
    }
  }
  return [];
}

// ─── Homepage (Tab Scaffold) ───────────────────────────────────────────────────
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final box = Hive.box("database");
  final supabase = Supabase.instance.client;
  final String _xenditKey =
      "xnd_development_PrRXlgnp6xvGZdEfzWWS544D2nxG43NSKnPQVu1ejeTFS14d7YfXBbQ2RUksi";

  Timer? pollingTimer;
  String paymentStatus = "";
  bool isPolling = false;

  bool get isDark => box.get("isDark", defaultValue: false);

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  // ─── Laptop card ────────────────────────────────────────────────────────────
  Widget _laptopCard(LaptopItem laptop, AppTheme t) {
    return GestureDetector(
      onTap: () {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const CupertinoAlertDialog(
            title: Text("Creating Order",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                CupertinoActivityIndicator(radius: 14),
                SizedBox(height: 12),
                Text("Please wait...", style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
        payNow(laptop.price, laptop.name);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        width: 200,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: kHighlight.withOpacity(t.isDark ? 0.12 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: t.cardImg,
                  child: Image.asset(
                    laptop.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(CupertinoIcons.desktopcomputer,
                          color: t.textSecondary, size: 55),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kHighlight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    laptop.badge,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laptop.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: t.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    laptop.specs,
                    style: TextStyle(
                        fontSize: 10,
                        color: t.textSecondary,
                        height: 1.45),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [kHighlight, kAccentMid]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: kHighlight.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${laptop.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                        const Icon(CupertinoIcons.cart_badge_plus,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Payment ─────────────────────────────────────────────────────────────────
  Future<void> payNow(int price, String itemName) async {
    try {
      const url = "https://api.xendit.co/v2/invoices";
      final auth =
          'Basic ' + base64Encode(utf8.encode(_xenditKey));
      final orderId =
          "order_${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": auth,
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "external_id": orderId,
          "amount": price,
          "description": "Laptop: $itemName"
        }),
      );
      final data = jsonDecode(response.body);
      final String id = data["id"];
      final String invoiceUrl = data["invoice_url"];
      await supabase.from('orders').insert(
          {'id': orderId, 'food_name': itemName, 'status': 'confirmed'});
      if (mounted) {
        setState(() {
          paymentStatus = "PENDING";
          isPolling = true;
        });
        Navigator.pop(context);
      }
      await Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (_) => PaymentPage(url: invoiceUrl)),
      );
      paymentPolling(id, auth, itemName, orderId);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Error"),
            content: Text("Failed to create order: $e"),
            actions: [
              CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        );
      }
    }
  }

  Future<void> paymentPolling(
      String id, String auth, String itemName, String orderId) async {
    pollingTimer?.cancel();
    pollingTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
          try {
            final response = await http.get(
                Uri.parse("https://api.xendit.co/v2/invoices/$id"),
                headers: {"Authorization": auth});
            final data = jsonDecode(response.body);
            final String status = data['status'];
            if (mounted) setState(() => paymentStatus = status);
            if (status == "PAID") {
              timer.cancel();
              pollingTimer = null;
              await supabase.from('rider_locations').upsert({
                'order_id': orderId,
                'rider_name': 'Miguel Santos',
                'rider_plate': 'TLG 8821',
                'rider_rating': 4.8,
                'lat': 15.4755,
                'lng': 120.5963,
                'eta_minutes': 1,
                'status': 'preparing',
              });
              if (mounted) {
                setState(() => isPolling = false);
                if (Navigator.canPop(context)) Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => LocationPinPage(
                        orderId: orderId, itemName: itemName),
                  ),
                );
              }
            } else if (status == "EXPIRED" || status == "FAILED") {
              timer.cancel();
              pollingTimer = null;
              if (mounted) setState(() => isPolling = false);
              if (mounted && Navigator.canPop(context)) Navigator.pop(context);
              if (mounted) {
                showCupertinoDialog(
                  context: context,
                  builder: (_) => CupertinoAlertDialog(
                    title: const Text("Order Failed"),
                    content: const Text(
                        "Payment not completed. Please try again."),
                    actions: [
                      CupertinoDialogAction(
                          child: const Text("OK"),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint("Polling error: $e");
          }
        });
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDark']),
      builder: (context, _, __) {
        final t = AppTheme(isDark: isDark);

        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: t.navBar,
            activeColor: kHighlight,
            inactiveColor: t.textSecondary,
            height: 65,
            iconSize: 26,
            border: Border(
              top: BorderSide(
                  color: t.navBarBorder.withOpacity(0.6), width: 0.5),
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(CupertinoIcons.house_fill),
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(CupertinoIcons.cube_box_fill),
                ),
                label: "Orders",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(CupertinoIcons.gear_alt_fill),
                ),
                label: "Settings",
              ),
            ],
          ),
          tabBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildHome(t);
              case 1:
                return const OrdersPage();
              case 2:
                return const Settings();
              default:
                return _buildHome(t);
            }
          },
        );
      },
    );
  }

  // ─── Home tab content ────────────────────────────────────────────────────────
  Widget _buildHome(AppTheme t) {
    final username =
    box.get("username", defaultValue: "User") as String;

    return CupertinoPageScaffold(
      backgroundColor: t.page,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [kHighlight, kAccentMid]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: kHighlight.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Center(
                              child: Text(
                                username[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back! 💻',
                                  style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                username,
                                style: TextStyle(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.4),
                              ),
                            ],
                          ),
                        ]),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: t.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: t.border, width: 1),
                          ),
                          child: const Icon(CupertinoIcons.bell,
                              color: kHighlight, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Location bar ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.border, width: 1),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: kHighlight,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(
                              CupertinoIcons.location_fill,
                              color: Colors.white,
                              size: 13),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Deliver to",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: t.textSecondary,
                                      fontWeight: FontWeight.w500)),
                              Text("Tarlac City, Central Luzon",
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: t.textPrimary)),
                            ],
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_down,
                            color: t.textSecondary, size: 14),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── Hero banner ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                              color: kHighlight.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kHighlight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: kHighlight.withOpacity(0.5),
                                      width: 0.8),
                                ),
                                child: const Text('FLASH SALE 🔥',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5)),
                              ),
                              const SizedBox(height: 10),
                              const Text('Find Your\nDream Laptop!',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Order now & track your\ncourier in real-time 🛵',
                                  style: TextStyle(
                                      color: Color(0xFFAAC4E8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const Text('💻',
                            style: TextStyle(fontSize: 64)),
                      ]),
                    ),
                    const SizedBox(height: 26),

                    // ── Payment status banner ─────────────────────────────────
                    if (isPolling) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: paymentStatus == "PAID"
                                  ? const Color(0xFF00E676)
                                  : kHighlight,
                              width: 1.3),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: paymentStatus == "PAID"
                                    ? const Color(0xFF00E676)
                                    : kHighlight,
                                borderRadius: BorderRadius.circular(8)),
                            child: Icon(
                              paymentStatus == "PAID"
                                  ? CupertinoIcons.check_mark
                                  : CupertinoIcons.clock,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order Status',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: t.textSecondary,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  paymentStatus,
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: paymentStatus == "PAID"
                                          ? const Color(0xFF00E676)
                                          : kHighlight),
                                ),
                              ],
                            ),
                          ),
                          if (paymentStatus == "PENDING")
                            const CupertinoActivityIndicator(
                                color: kHighlight, radius: 11),
                        ]),
                      ),
                      const SizedBox(height: 26),
                    ],

                    // ── Section header ────────────────────────────────────────
                    Text('🖥️ Gaming Laptops',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: t.textPrimary,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 5),
                    Text('Tap any laptop to order & get it delivered!',
                        style: TextStyle(
                            fontSize: 12,
                            color: t.textSecondary,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── Laptop horizontal list ───────────────────────────────────────
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: laptops
                      .map((l) => _laptopCard(l, AppTheme(isDark: isDark)))
                      .toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }
}

// ─── Payment Page ──────────────────────────────────────────────────────────────
class PaymentPage extends StatefulWidget {
  final String url;
  const PaymentPage({super.key, required this.url});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");
    final t = AppTheme(isDark: box.get("isDark", defaultValue: false));

    return CupertinoPageScaffold(
      backgroundColor: t.page,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: t.card,
        border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
        middle: Text("Payment",
            style: TextStyle(
                fontWeight: FontWeight.w600, color: t.textPrimary)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: kHighlight),
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: const Text("Cancel Order?"),
                content:
                const Text("Are you sure you want to cancel?"),
                actions: [
                  CupertinoDialogAction(
                      child: const Text("No"),
                      onPressed: () => Navigator.pop(context)),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text("Yes, Cancel"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }),
                ],
              ),
            );
          },
        ),
      ),
      child: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}

// ─── Location Pin Page ─────────────────────────────────────────────────────────
class LocationPinPage extends StatefulWidget {
  final String orderId;
  final String itemName;
  const LocationPinPage(
      {super.key, required this.orderId, required this.itemName});

  @override
  State<LocationPinPage> createState() => _LocationPinPageState();
}

class _LocationPinPageState extends State<LocationPinPage> {
  static const LatLng _center = LatLng(15.4755, 120.5963);
  LatLng _pinLocation = const LatLng(15.4755, 120.5963);
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('delivery'),
        position: _pinLocation,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow:
        const InfoWindow(title: 'Delivery Location'),
        onDragEnd: (newPos) =>
            setState(() => _pinLocation = newPos),
      ),
    };
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _pinLocation = pos;
      _markers = {
        Marker(
          markerId: const MarkerId('delivery'),
          position: _pinLocation,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow:
          const InfoWindow(title: 'Delivery Location'),
          onDragEnd: (newPos) =>
              setState(() => _pinLocation = newPos),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");
    final t = AppTheme(isDark: box.get("isDark", defaultValue: false));

    const double baseLat = 15.4730;
    const double baseLng = 120.5930;
    const double latStep = 0.002;
    const double lngStep = 0.002;
    const int kRows = 12;
    const int kCols = 10;

    final int gridRow =
    ((baseLat + (kRows - 1) * latStep - _pinLocation.latitude) /
        latStep)
        .round()
        .clamp(0, kRows - 1);
    final int gridCol =
    ((_pinLocation.longitude - baseLng) / lngStep)
        .round()
        .clamp(0, kCols - 1);

    return CupertinoPageScaffold(
      backgroundColor: t.page,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: t.card,
        border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
        middle: Text("Pin Your Location 📍",
            style: TextStyle(
                fontWeight: FontWeight.w600, color: t.textPrimary)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: kHighlight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: kHighlight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(CupertinoIcons.map_fill,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Tap map or drag pin to set delivery location",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                        "Lat: ${_pinLocation.latitude.toStringAsFixed(4)}  Lng: ${_pinLocation.longitude.toStringAsFixed(4)}",
                        style: TextStyle(
                            fontSize: 11, color: t.textSecondary)),
                  ],
                ),
              ),
            ]),
          ),

          // Google Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: kHighlight.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                      target: _center, zoom: 15),
                  onMapCreated: (c) => _mapController = c,
                  onTap: _onMapTap,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border)),
                child: Row(children: [
                  const Icon(CupertinoIcons.location_solid,
                      color: kHighlight, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tarlac City · ${_pinLocation.latitude.toStringAsFixed(4)}, ${_pinLocation.longitude.toStringAsFixed(4)}",
                      style: TextStyle(
                          fontSize: 12,
                          color: t.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: kHighlight,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => RiderTrackerPage(
                          orderId: widget.orderId,
                          itemName: widget.itemName,
                          destGridRow: gridRow,
                          destGridCol: gridCol,
                          destLat: _pinLocation.latitude,
                          destLng: _pinLocation.longitude,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                      "Confirm Location & Track Order 🛵",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Rider Tracker Page ────────────────────────────────────────────────────────
class RiderTrackerPage extends StatefulWidget {
  final String orderId, itemName;
  final int destGridRow, destGridCol;
  final double destLat, destLng;

  const RiderTrackerPage({
    super.key,
    required this.orderId,
    required this.itemName,
    required this.destGridRow,
    required this.destGridCol,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<RiderTrackerPage> createState() => _RiderTrackerPageState();
}

class _RiderTrackerPageState extends State<RiderTrackerPage> {
  static const int kRows = 12, kCols = 10;
  static const (int, int) kRiderStart = (9, 2);
  static const double _baseLat = 15.4730, _baseLng = 120.5930;
  static const double _latStep = 0.002, _lngStep = 0.002;

  Set<(int, int)> get _walls {
    final w = <(int, int)>{};
    for (int r = 0; r < kRows; r++)
      for (int c = 0; c < kCols; c++)
        if ((r + c) % 3 != 0) w.add((r, c));
    return w;
  }

  LatLng _gridToLatLng(int row, int col) => LatLng(
    _baseLat + (kRows - 1 - row) * _latStep,
    _baseLng + col * _lngStep,
  );

  late List<(int, int)> _path;
  int _pathIndex = 0;

  (int, int) get _riderCell =>
      _pathIndex < _path.length ? _path[_pathIndex] : _path.last;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  final supabase = Supabase.instance.client;
  final box = Hive.box("database");

  String _riderName = "Finding courier...";
  String _riderPlate = "---";
  double _riderRating = 0.0;
  int _etaMinutes = 0;
  String _status = "preparing";
  int _statusStep = 0;
  bool _isDelivered = false;
  bool _isLoading = true;

  StreamSubscription? _subscription;
  Timer? _moveTimer, _countdownTimer, _statusAutoTimer;

  final List<Map<String, String>> _steps = [
    {"title": "Order Confirmed", "sub": "We received your order 💻"},
    {"title": "Packing Items", "sub": "Your laptop is being packed 📦"},
    {
      "title": "Courier On the Way",
      "sub": "Courier picked up your package 🛵"
    },
    {
      "title": "Almost There!",
      "sub": "Courier is nearby your location 📍"
    },
    {"title": "Delivered! 🎉", "sub": "Enjoy your new laptop!"},
  ];

  @override
  void initState() {
    super.initState();
    _path = aStarPath(
      rows: kRows,
      cols: kCols,
      start: kRiderStart,
      end: (widget.destGridRow, widget.destGridCol),
      walls: _walls,
    );
    if (_path.isEmpty) _path = [kRiderStart];
    _updateMapElements();
    _listenToCourierAPI();
    _startRiderMovement();
    _startCountdown();
    _scheduleStatusAutoUpdate();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _moveTimer?.cancel();
    _countdownTimer?.cancel();
    _statusAutoTimer?.cancel();
    super.dispose();
  }

  void _updateMapElements() {
    final riderLatLng =
    _gridToLatLng(_riderCell.$1, _riderCell.$2);
    final destLatLng = LatLng(widget.destLat, widget.destLng);

    final pastPoints = _path
        .take(_pathIndex + 1)
        .map((p) => _gridToLatLng(p.$1, p.$2))
        .toList();
    final futurePoints = _path
        .skip(_pathIndex)
        .map((p) => _gridToLatLng(p.$1, p.$2))
        .toList();

    _polylines = {
      if (pastPoints.length > 1)
        Polyline(
          polylineId: const PolylineId('past'),
          points: pastPoints,
          color: const Color(0xFF00E676).withOpacity(0.35),
          width: 5,
          patterns: [PatternItem.dash(12), PatternItem.gap(6)],
        ),
      if (futurePoints.length > 1)
        Polyline(
          polylineId: const PolylineId('future'),
          points: futurePoints,
          color: const Color(0xFF00E676),
          width: 5,
        ),
    };

    _markers = {
      Marker(
        markerId: const MarkerId('rider'),
        position: riderLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
            title: _riderName, snippet: 'Your rider 🛵'),
      ),
      Marker(
        markerId: const MarkerId('dest'),
        position: destLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
            title: 'Delivery Location',
            snippet: 'Your address 📍'),
      ),
    };
  }

  void _scheduleStatusAutoUpdate() {
    _statusAutoTimer =
        Timer(const Duration(minutes: 1), () async {
          if (!mounted || _isDelivered) return;
          if (_status == 'preparing') {
            await supabase
                .from('rider_locations')
                .update({'status': 'on_the_way'}).eq(
                'order_id', widget.orderId);
          }
        });
  }

  void _listenToCourierAPI() {
    _subscription = supabase
        .from('rider_locations')
        .stream(primaryKey: ['order_id'])
        .eq('order_id', widget.orderId)
        .listen((data) {
      if (!mounted) return;
      if (data.isEmpty) {
        setState(() => _isLoading = true);
        return;
      }
      final row = data.first;
      setState(() {
        _isLoading = false;
        _riderName = row['rider_name'] ?? 'Unknown';
        _riderPlate = row['rider_plate'] ?? '---';
        _riderRating =
            (row['rider_rating'] ?? 0.0).toDouble();
        _etaMinutes = row['eta_minutes'] ?? 0;
        _status = row['status'] ?? 'preparing';
        switch (_status) {
          case 'confirmed':
            _statusStep = 0;
            break;
          case 'preparing':
            _statusStep = 1;
            break;
          case 'on_the_way':
            _statusStep = 2;
            break;
          case 'nearby':
            _statusStep = 3;
            break;
          case 'delivered':
            _statusStep = 4;
            _isDelivered = true;
            _moveTimer?.cancel();
            break;
        }
        _updateMapElements();
      });
    });
  }

  void _startRiderMovement() {
    _moveTimer = Timer.periodic(
        const Duration(milliseconds: 900), (timer) {
      if (!mounted || _isDelivered) return;
      if (_pathIndex < _path.length - 1) {
        setState(() {
          _pathIndex++;
          _updateMapElements();
        });
        if (_mapController != null) {
          final riderLatLng =
          _gridToLatLng(_riderCell.$1, _riderCell.$2);
          _mapController!
              .animateCamera(CameraUpdate.newLatLng(riderLatLng));
        }
      } else {
        timer.cancel();
        if (!_isDelivered) {
          supabase.from('rider_locations').update(
              {'status': 'delivered', 'eta_minutes': 0}).eq(
              'order_id', widget.orderId);
        }
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(
        const Duration(seconds: 10), (timer) async {
      if (!mounted || _isDelivered) {
        timer.cancel();
        return;
      }
      final newEta = _etaMinutes - 1;
      if (newEta <= 0) {
        timer.cancel();
        await supabase.from('rider_locations').update(
            {'eta_minutes': 0, 'status': 'delivered'}).eq(
            'order_id', widget.orderId);
      } else {
        String newStatus = newEta <= 5
            ? 'nearby'
            : newEta <= 15
            ? 'on_the_way'
            : _status;
        await supabase.from('rider_locations').update({
          'eta_minutes': newEta,
          'status': newStatus,
        }).eq('order_id', widget.orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDark']),
      builder: (context, _, __) {
        final t = AppTheme(
            isDark: box.get("isDark", defaultValue: false));

        if (_isLoading) {
          return CupertinoPageScaffold(
            backgroundColor: t.page,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(
                        color: kHighlight, radius: 16),
                    const SizedBox(height: 16),
                    Text("Finding your courier...",
                        style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }

        return CupertinoPageScaffold(
          backgroundColor: t.page,
          child: Stack(children: [
            // ── Full screen Google Map ──
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: _gridToLatLng(
                        _riderCell.$1, _riderCell.$2),
                    zoom: 15),
                onMapCreated: (c) => _mapController = c,
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                mapType: MapType.normal,
              ),
            ),

            // ── Top bar ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.2),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(CupertinoIcons.back,
                            color: Colors.black87, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.15),
                                blurRadius: 10)
                          ],
                        ),
                        child: Row(children: [
                          const Icon(
                              CupertinoIcons.location_solid,
                              color: Color(0xFF34A853),
                              size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: const [
                                Text("Tarlac City, Central Luzon",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87)),
                                Text("Delivery destination",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // ── LIVE badge ──
            Positioned(
              top: 110,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA4335),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFEA4335)
                            .withOpacity(0.4),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),

            // ── A* badge ──
            Positioned(
              bottom: 330,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('A* PATHFINDING',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ),

            // ── Steps left badge ──
            Positioned(
              bottom: 330,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4)
                  ],
                ),
                child: Text(
                  '${(_path.length - 1 - _pathIndex).clamp(0, 999)} steps left',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
              ),
            ),

            // ── Bottom Sheet ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: t.page,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 10, bottom: 6),
                      child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: t.border,
                              borderRadius:
                              BorderRadius.circular(2))),
                    ),

                    // Arriving banner
                    Container(
                      padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                  _isDelivered
                                      ? "Delivered! 🎉"
                                      : "Arriving in",
                                  style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                              Text(
                                _isDelivered
                                    ? "🎉"
                                    : "$_etaMinutes min",
                                style: const TextStyle(
                                    color: Color(0xFF1a73e8),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1),
                              ),
                              Text(widget.itemName,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: t.textPrimary)),
                            ],
                          ),
                        ),
                        Text(_isDelivered ? '🎉' : '🛵',
                            style: const TextStyle(fontSize: 42)),
                      ]),
                    ),

                    // Courier row
                    Container(
                      margin:
                      const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.border)),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF34A853),
                              Color(0xFF1a7a3a)
                            ]),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              _riderName.isNotEmpty
                                  ? _riderName[0]
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(_riderName,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: t.textPrimary)),
                              Row(children: [
                                const Icon(CupertinoIcons.star_fill,
                                    size: 11,
                                    color: Color(0xFFFFC107)),
                                const SizedBox(width: 4),
                                Text(
                                    '$_riderRating · $_riderPlate',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: t.textSecondary)),
                                const Text(' · FROM API ✅',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF34A853),
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: const Color(0xFFe8f5e9),
                              borderRadius:
                              BorderRadius.circular(20)),
                          child: const Icon(
                              CupertinoIcons.phone_fill,
                              color: Color(0xFF34A853),
                              size: 15),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: const Color(0xFFe3f2fd),
                              borderRadius:
                              BorderRadius.circular(20)),
                          child: const Icon(
                              CupertinoIcons.chat_bubble_fill,
                              color: Color(0xFF1a73e8),
                              size: 15),
                        ),
                      ]),
                    ),

                    // Status steps
                    Container(
                      margin:
                      const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Delivery Status",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary)),
                          const SizedBox(height: 10),
                          ...List.generate(_steps.length, (i) {
                            final isActive = _statusStep >= i;
                            final isCurrent = _statusStep == i;
                            return Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Column(children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? const Color(0xFF34A853)
                                          : t.border,
                                    ),
                                    child: Center(
                                      child: isCurrent &&
                                          !_isDelivered
                                          ? const CupertinoActivityIndicator(
                                          color: Colors.white,
                                          radius: 6)
                                          : Icon(
                                          isActive
                                              ? CupertinoIcons
                                              .check_mark
                                              : CupertinoIcons
                                              .circle,
                                          color: isActive
                                              ? Colors.white
                                              : t.textSecondary,
                                          size: 11),
                                    ),
                                  ),
                                  if (i < _steps.length - 1)
                                    Container(
                                        width: 2,
                                        height: 22,
                                        color: _statusStep > i
                                            ? const Color(0xFF34A853)
                                            : t.border),
                                ]),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 2),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _steps[i]["title"]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isActive
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: isCurrent
                                                ? const Color(
                                                0xFF1a73e8)
                                                : isActive
                                                ? t.textPrimary
                                                : t.textSecondary,
                                          ),
                                        ),
                                        if (isActive)
                                          Text(
                                            _steps[i]["sub"]!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isCurrent
                                                  ? const Color(
                                                  0xFF34A853)
                                                  : t.textSecondary,
                                            ),
                                          ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}