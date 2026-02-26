import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings.dart';
const kHighlight = Color(0xFF2563EB);
const kAccentMid = Color(0xFF1E4D8C);
const kGreen     = Color(0xFF22C55E);
class _T {
  final bool dark;
  const _T(this.dark);
  Color get page          => dark ? Colors.black              : const Color(0xFFF4F7FF);
  Color get card          => dark ? const Color(0xFF1A1A1A)   : Colors.white;
  Color get cardImg       => dark ? const Color(0xFF222222)   : const Color(0xFFEAF0FF);
  Color get border        => dark ? const Color(0xFF333333)   : const Color(0xFFD0DEFF);
  Color get tabBg         => dark ? Colors.black              : Colors.white;
  Color get textPrimary   => dark ? Colors.white              : const Color(0xFF0A1628);
  Color get textSecondary => dark ? const Color(0xFF9E9E9E)   : const Color(0xFF5A7299);
}
class LaptopItem {
  final String name, specs, badge, imagePath;
  final int price;
  const LaptopItem({
    required this.name, required this.specs, required this.price,
    required this.badge, required this.imagePath,
  });
}
final List<LaptopItem> laptops = [
  const LaptopItem(name:'Axioo Pongo 735',  specs:'i7-13620H · RTX 3050 · 16GB · 144Hz FHD', price:12999, badge:'LOCAL PRIDE', imagePath:'assets/images/xioo_pongo_735.png'),
  const LaptopItem(name:'HP Victus 15',     specs:'i5-12450H · RTX 2050 · 8GB · 144Hz FHD',  price:13499, badge:'BEST VALUE',  imagePath:'assets/images/hp_victus_15.png'),
  const LaptopItem(name:'MSI GF63 Thin',    specs:'i7-12650H · RTX 4050 · 16GB · 144Hz IPS', price:18999, badge:'THIN & LIGHT',imagePath:'assets/images/msi_gf63_thin.png'),
  const LaptopItem(name:'Acer Nitro V15',   specs:'Ryzen 5 7535HS · RTX 4050 · 8GB · 144Hz', price:16499, badge:'POPULAR',    imagePath:'assets/images/acer_nitro_v15.jpg'),
  const LaptopItem(name:'Asus TUF A15',     specs:'Ryzen 7 7745HX · RTX 4060 · 16GB · 144Hz',price:21999, badge:'MIL-SPEC',   imagePath:'assets/images/asus_tuf_a15.jpg'),
  const LaptopItem(name:'Lenovo LOQ 15',    specs:'i7-13650HX · RTX 4060 · 16GB · 165Hz IPS',price:22999, badge:'TOP PICK',   imagePath:'assets/images/lenovo_loq_15.jpg'),
];
class _Node {
  final int row, col;
  double g, h;
  _Node? parent;
  bool walkable;
  _Node({required this.row, required this.col, this.walkable = true})
      : g = double.infinity, h = 0;
  double get f => g + h;
  @override
  bool operator ==(Object other) =>
      other is _Node && other.row == row && other.col == col;
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
        (r) => List.generate(cols, (c) {
      final isWall = walls?.contains((r, c)) ?? false;
      return _Node(row: r, col: c, walkable: !isWall);
    }),
  );
  final startNode = grid[start.$1][start.$2]..g = 0;
  final endNode   = grid[end.$1][end.$2];
  double heuristic(_Node a, _Node b) =>
      ((a.row - b.row).abs() + (a.col - b.col).abs()).toDouble();
  startNode.h = heuristic(startNode, endNode);
  final open   = <_Node>{startNode};
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
    final dirs = [(-1,0),(1,0),(0,-1),(0,1)];
    for (final d in dirs) {
      final nr = current.row + d.$1;
      final nc = current.col + d.$2;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
      final neighbor = grid[nr][nc];
      if (!neighbor.walkable || closed.contains(neighbor)) continue;
      final tentativeG = current.g + 1;
      if (tentativeG < neighbor.g) {
        neighbor.parent = current;
        neighbor.g = tentativeG;
        neighbor.h = heuristic(neighbor, endNode);
        open.add(neighbor);
      }
    }
  }
  return [];
}
class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}
class _HomepageState extends State<Homepage> {
  final box     = Hive.box("database");
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
  Widget _laptopCard(LaptopItem laptop, _T t) {
    return GestureDetector(
      onTap: () {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Creating Order",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            content: Column(mainAxisSize: MainAxisSize.min, children: const [
              SizedBox(height: 16),
              CupertinoActivityIndicator(radius: 14),
              SizedBox(height: 12),
              Text("Please wait...", style: TextStyle(fontSize: 13)),
            ]),
          ),
        );
        payNow(laptop.price, laptop.name);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 210,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.border, width: 1.2),
          boxShadow: [BoxShadow(
              color: kHighlight.withOpacity(t.dark ? 0.18 : 0.10),
              blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 145, width: double.infinity, color: t.cardImg,
                  child: Image.asset(laptop.imagePath, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                          child: Icon(CupertinoIcons.desktopcomputer,
                              color: t.textSecondary, size: 60))),
                ),
              ),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: kHighlight, borderRadius: BorderRadius.circular(6)),
                  child: Text(laptop.badge, style: const TextStyle(fontSize: 9,
                      fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(laptop.name, style: TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 14, color: t.textPrimary)),
                const SizedBox(height: 4),
                Text(laptop.specs, style: TextStyle(fontSize: 10.5,
                    color: t.textSecondary, height: 1.45),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kHighlight, kAccentMid]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: kHighlight.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(
                      '₱${laptop.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const Icon(CupertinoIcons.cart_badge_plus, color: Colors.white, size: 17),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> payNow(int price, String itemName) async {
    try {
      const url = "https://api.xendit.co/v2/invoices";
      final auth = 'Basic ' + base64Encode(utf8.encode(_xenditKey));
      final orderId = "order_${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Authorization": auth, "Content-Type": "application/json"},
        body: jsonEncode({
          "external_id": orderId,
          "amount": price,
          "description": "Laptop: $itemName",
        }),
      );
      final data = jsonDecode(response.body);
      final String id = data["id"];
      final String invoiceUrl = data["invoice_url"];
      await supabase.from('orders').insert({
        'id': orderId,
        'food_name': itemName,
        'status': 'confirmed',
      });
      if (mounted) {
        setState(() { paymentStatus = "PENDING"; isPolling = true; });
        Navigator.pop(context);
      }
      await Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => PaymentPage(url: invoiceUrl)),
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
            actions: [CupertinoDialogAction(
                child: const Text("OK"), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }
  }
  Future<void> paymentPolling(String id, String auth, String itemName, String orderId) async {
    pollingTimer?.cancel();
    pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await http.get(
          Uri.parse("https://api.xendit.co/v2/invoices/$id"),
          headers: {"Authorization": auth},
        );
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
            'eta_minutes': 30,
            'status': 'preparing',
          });
          if (mounted) {
            setState(() => isPolling = false);
            if (Navigator.canPop(context)) Navigator.pop(context);
            Navigator.push(context, CupertinoPageRoute(
              builder: (_) => LocationPinPage(
                orderId: orderId,
                itemName: itemName,
              ),
            ));
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
                content: const Text("Payment not completed. Please try again."),
                actions: [CupertinoDialogAction(
                    child: const Text("OK"), onPressed: () => Navigator.pop(context))],
              ),
            );
          }
        }
      } catch (e) { debugPrint("Polling error: $e"); }
    });
  }
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDark']),
      builder: (context, _, __) {
        final t = _T(isDark);
        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: t.tabBg,
            activeColor: kHighlight,
            inactiveColor: t.textSecondary,
            height: 65,
            iconSize: 26,
            border: Border(top: BorderSide(color: t.border.withOpacity(0.6), width: 0.5)),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(top: 6),
                    child: Icon(CupertinoIcons.house_fill)),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(top: 6),
                    child: Icon(CupertinoIcons.gear_alt_fill)),
                label: "Settings",
              ),
            ],
          ),
          tabBuilder: (context, index) {
            if (index == 0) return _buildHome(t);
            return const Settings();
          },
        );
      },
    );
  }
  Widget _buildHome(_T t) {
    final username = box.get("username", defaultValue: "User") as String;
    return CupertinoPageScaffold(
      backgroundColor: t.page,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kHighlight, kAccentMid]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: kHighlight.withOpacity(0.35),
                              blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text(username[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Welcome back! 💻', style: TextStyle(
                            color: t.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(username, style: TextStyle(color: t.textPrimary,
                            fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.4)),
                      ]),
                    ]),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: t.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.border, width: 1)),
                      child: const Icon(CupertinoIcons.bell, color: kHighlight, size: 20),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: t.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.border, width: 1)),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: kHighlight,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(CupertinoIcons.location_fill,
                              color: Colors.white, size: 14)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Deliver to", style: TextStyle(fontSize: 10,
                            color: t.textSecondary, fontWeight: FontWeight.w500)),
                        Text("Tarlac City, Central Luzon", style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, color: t.textPrimary)),
                      ])),
                      Icon(CupertinoIcons.chevron_down, color: t.textSecondary, size: 14),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1628),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: const Color(0xFF0A1628).withOpacity(0.4),
                          blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kHighlight.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: kHighlight.withOpacity(0.5), width: 0.8),
                          ),
                          child: const Text('FLASH SALE 🔥', style: TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 10),
                        const Text('Find Your\nDream Laptop!', style: TextStyle(
                            color: Colors.white, fontSize: 21,
                            fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 6),
                        const Text('Order now & track your\ncourier in real-time 🛵',
                            style: TextStyle(color: Color(0xFFAAC4E8), fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ])),
                      const Text('💻', style: TextStyle(fontSize: 66)),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  if (isPolling) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(color: t.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: paymentStatus == "PAID"
                                  ? CupertinoColors.systemGreen : kHighlight,
                              width: 1.3)),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: paymentStatus == "PAID"
                                  ? CupertinoColors.systemGreen : kHighlight,
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(paymentStatus == "PAID"
                              ? CupertinoIcons.check_mark : CupertinoIcons.clock,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Order Status', style: TextStyle(fontSize: 11,
                              color: t.textSecondary, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(paymentStatus, style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: paymentStatus == "PAID"
                                  ? CupertinoColors.systemGreen : kHighlight)),
                        ])),
                        if (paymentStatus == "PENDING")
                          const CupertinoActivityIndicator(color: kHighlight, radius: 11),
                      ]),
                    ),
                    const SizedBox(height: 28),
                  ],
                  Text('🖥️ Gaming Laptops', style: TextStyle(fontSize: 19,
                      fontWeight: FontWeight.w800, color: t.textPrimary, letterSpacing: -0.4)),
                  const SizedBox(height: 6),
                  Text('Tap any laptop to order & get it delivered!',
                      style: TextStyle(fontSize: 12, color: t.textSecondary,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                    children: laptops.map((l) => _laptopCard(l, _T(isDark))).toList()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }
}
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
    final t = _T(box.get("isDark", defaultValue: false));
    return CupertinoPageScaffold(
      backgroundColor: t.page,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: t.card,
        border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
        middle: Text("Payment",
            style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: kHighlight),
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: const Text("Cancel Order?"),
                content: const Text("Are you sure you want to cancel?"),
                actions: [
                  CupertinoDialogAction(child: const Text("No"),
                      onPressed: () => Navigator.pop(context)),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text("Yes, Cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
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
class LocationPinPage extends StatefulWidget {
  final String orderId;
  final String itemName;
  const LocationPinPage({super.key, required this.orderId, required this.itemName});
  @override
  State<LocationPinPage> createState() => _LocationPinPageState();
}
class _LocationPinPageState extends State<LocationPinPage> {
  static const int kRows = 12;
  static const int kCols = 10;
  (int, int) _pin = (3, 7);
  static const double _baseLat = 15.4730;
  static const double _baseLng = 120.5930;
  static const double _latStep = 0.002;
  static const double _lngStep = 0.002;
  double get _pinLat => _baseLat + (kRows - 1 - _pin.$1) * _latStep;
  double get _pinLng => _baseLng + _pin.$2 * _lngStep;
  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");
    final t = _T(box.get("isDark", defaultValue: false));
    return CupertinoPageScaffold(
      backgroundColor: t.page,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: t.card,
        border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
        middle: Text("Pin Your Location 📍",
            style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: kHighlight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kHighlight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(CupertinoIcons.map_fill, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Tap to set delivery pin", style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: t.textPrimary)),
                const SizedBox(height: 2),
                Text("Lat: ${_pinLat.toStringAsFixed(4)}  Lng: ${_pinLng.toStringAsFixed(4)}",
                    style: TextStyle(fontSize: 11, color: t.textSecondary)),
              ])),
            ]),
          ),
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final RenderBox box =
                context.findRenderObject() as RenderBox;
                final size = box.size;
                final mapHeight = size.height - 220;
                final mapWidth  = size.width - 40;
                final cellW = mapWidth  / kCols;
                final cellH = mapHeight / kRows;
                final localPos = details.localPosition;
                final offsetY = 130.0;
                final tapX = localPos.dx - 20;
                final tapY = localPos.dy - offsetY;
                final col = (tapX / cellW).floor().clamp(0, kCols - 1);
                final row = (tapY / cellH).floor().clamp(0, kRows - 1);
                setState(() => _pin = (row, col));
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: kHighlight.withOpacity(0.1),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _GridMapPainter(
                      dark: t.dark,
                      rows: kRows, cols: kCols,
                      pin: _pin,
                      rider: (9, 2),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: t.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border)),
                child: Row(children: [
                  const Icon(CupertinoIcons.location_solid, color: kHighlight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    "Tarlac City · ${_pinLat.toStringAsFixed(4)}, ${_pinLng.toStringAsFixed(4)}",
                    style: TextStyle(fontSize: 12, color: t.textSecondary,
                        fontWeight: FontWeight.w500),
                  )),
                ]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: kHighlight,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () {
                    Navigator.pushReplacement(context, CupertinoPageRoute(
                      builder: (_) => RiderTrackerPage(
                        orderId: widget.orderId,
                        itemName: widget.itemName,
                        destGridRow: _pin.$1,
                        destGridCol: _pin.$2,
                        destLat: _pinLat,
                        destLng: _pinLng,
                      ),
                    ));
                  },
                  child: const Text("Confirm Location & Track Order 🛵",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
class _GridMapPainter extends CustomPainter {
  final bool dark;
  final int rows, cols;
  final (int, int) pin;
  final (int, int)? rider;
  const _GridMapPainter({
    required this.dark, required this.rows, required this.cols,
    required this.pin, this.rider,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width  / cols;
    final cellH = size.height / rows;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = dark ? const Color(0xFF0D0D0D) : const Color(0xFFE3EEFF));
    final road = Paint()
      ..color = dark ? const Color(0xFF2A2A2A) : Colors.white
      ..strokeWidth = 4;
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * cellH), Offset(size.width, r * cellH), road);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cellW, 0), Offset(c * cellW, size.height), road);
    }
    final block = Paint()..color = dark
        ? const Color(0xFF111111) : const Color(0xFFBDD5FF);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c) % 3 != 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellW + 2, r * cellH + 2,
                  cellW - 4, cellH - 4),
              const Radius.circular(3),
            ),
            block,
          );
        }
      }
    }
    final cx = (pin.$2 + 0.5) * cellW;
    final cy = (pin.$1 + 0.5) * cellH;
    canvas.drawCircle(Offset(cx, cy + 2),
        min(cellW, cellH) * 0.38,
        Paint()..color = kHighlight.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(cx, cy), min(cellW, cellH) * 0.35,
        Paint()..color = kHighlight);
    canvas.drawCircle(Offset(cx, cy), min(cellW, cellH) * 0.18,
        Paint()..color = Colors.white);
    if (rider != null) {
      final rx = (rider!.$2 + 0.5) * cellW;
      final ry = (rider!.$1 + 0.5) * cellH;
      canvas.drawCircle(Offset(rx, ry), min(cellW, cellH) * 0.3,
          Paint()..color = kGreen);
      canvas.drawCircle(Offset(rx, ry), min(cellW, cellH) * 0.15,
          Paint()..color = Colors.white);
    }
  }
  @override
  bool shouldRepaint(covariant _GridMapPainter old) =>
      old.pin != pin || old.dark != dark || old.rider != rider;
}
class RiderTrackerPage extends StatefulWidget {
  final String orderId;
  final String itemName;
  final int    destGridRow, destGridCol;
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
  static const int kRows = 12;
  static const int kCols = 10;
  static const (int, int) kRiderStart = (9, 2);
  Set<(int, int)> get _walls {
    final w = <(int, int)>{};
    for (int r = 0; r < kRows; r++) {
      for (int c = 0; c < kCols; c++) {
        if ((r + c) % 3 != 0) w.add((r, c));
      }
    }
    return w;
  }
  late List<(int, int)> _path;
  int _pathIndex = 0;
  (int, int) get _riderCell => _pathIndex < _path.length ? _path[_pathIndex] : _path.last;
  final supabase = Supabase.instance.client;
  final box = Hive.box("database");
  String _riderName   = "Finding courier...";
  String _riderPlate  = "---";
  double _riderRating = 0.0;
  int    _etaMinutes  = 0;
  String _status      = "preparing";
  int    _statusStep  = 0;
  bool   _isDelivered = false;
  bool   _isLoading   = true;
  StreamSubscription? _subscription;
  Timer? _moveTimer;
  Timer? _countdownTimer;
  Timer? _statusAutoTimer;
  final List<Map<String, String>> _steps = [
    {"title": "Order Confirmed",    "sub": "We received your order 💻"},
    {"title": "Packing Items",      "sub": "Your laptop is being packed 📦"},
    {"title": "Courier On the Way", "sub": "Courier picked up your package 🛵"},
    {"title": "Almost There!",      "sub": "Courier is nearby your location 📍"},
    {"title": "Delivered! 🎉",      "sub": "Enjoy your new laptop!"},
  ];
  @override
  void initState() {
    super.initState();
    _path = aStarPath(
      rows: kRows, cols: kCols,
      start: kRiderStart,
      end: (widget.destGridRow, widget.destGridCol),
      walls: _walls,
    );
    if (_path.isEmpty) _path = [kRiderStart];
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
  void _scheduleStatusAutoUpdate() {
    _statusAutoTimer = Timer(const Duration(minutes: 1), () async {
      if (!mounted || _isDelivered) return;
      if (_status == 'preparing') {
        await supabase.from('rider_locations').update({
          'status': 'on_the_way',
        }).eq('order_id', widget.orderId);
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
      if (data.isEmpty) { setState(() => _isLoading = true); return; }
      final row = data.first;
      setState(() {
        _isLoading   = false;
        _riderName   = row['rider_name']   ?? 'Unknown';
        _riderPlate  = row['rider_plate']  ?? '---';
        _riderRating = (row['rider_rating'] ?? 0.0).toDouble();
        _etaMinutes  = row['eta_minutes']  ?? 0;
        _status      = row['status']       ?? 'preparing';
        switch (_status) {
          case 'confirmed':  _statusStep = 0; break;
          case 'preparing':  _statusStep = 1; break;
          case 'on_the_way': _statusStep = 2; break;
          case 'nearby':     _statusStep = 3; break;
          case 'delivered':
            _statusStep = 4;
            _isDelivered = true;
            _moveTimer?.cancel();
            break;
        }
      });
    });
  }
  void _startRiderMovement() {
    _moveTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted || _isDelivered) return;
      if (_pathIndex < _path.length - 1) {
        setState(() => _pathIndex++);
      } else {
        timer.cancel();
        if (!_isDelivered) {
          supabase.from('rider_locations').update({
            'status': 'delivered',
            'eta_minutes': 0,
          }).eq('order_id', widget.orderId);
        }
      }
    });
  }
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!mounted || _isDelivered) { timer.cancel(); return; }
      final newEta = _etaMinutes - 1;
      String newStatus = _status;
      if (newEta <= 0) {
        timer.cancel();
        await supabase.from('rider_locations').update({
          'eta_minutes': 0, 'status': 'delivered',
        }).eq('order_id', widget.orderId);
      } else {
        if (newEta <= 5)             newStatus = 'nearby';
        else if (newEta <= 15)       newStatus = 'on_the_way';
        await supabase.from('rider_locations').update({
          'eta_minutes': newEta, 'status': newStatus,
        }).eq('order_id', widget.orderId);
      }
    });
  }
  Widget _buildMap(BuildContext context, _T t) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kHighlight.withOpacity(0.15),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          CustomPaint(
            painter: _TrackerMapPainter(
              dark: t.dark,
              rows: kRows, cols: kCols,
              path: _path,
              riderIndex: _pathIndex,
              dest: (widget.destGridRow, widget.destGridCol),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(CupertinoIcons.clock, size: 13, color: kHighlight),
                const SizedBox(width: 5),
                Text(
                  _isDelivered ? "Delivered!" : _isLoading ? "Loading..." : "$_etaMinutes mins",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.textPrimary),
                ),
              ]),
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: kHighlight, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ]),
            ),
          ),
          Positioned(
            bottom: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('A* PATHFINDING', style: TextStyle(
                  color: Colors.white, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: t.card.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${(_path.length - 1 - _pathIndex).clamp(0, 999)} steps left',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: t.textPrimary),
              ),
            ),
          ),
        ]),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDark']),
      builder: (context, _, __) {
        final t = _T(box.get("isDark", defaultValue: false));
        return CupertinoPageScaffold(
          backgroundColor: t.page,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: t.card,
            border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
            middle: Text("Track Your Courier 🛵",
                style: TextStyle(fontWeight: FontWeight.w600, color: t.textPrimary)),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.back, color: kHighlight),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CupertinoActivityIndicator(color: kHighlight, radius: 16),
              const SizedBox(height: 16),
              Text("Finding your courier...",
                  style: TextStyle(color: t.textSecondary, fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]))
                : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: const Color(0xFF0A1628).withOpacity(0.4),
                        blurRadius: 24, offset: const Offset(0, 12))],
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_isDelivered ? "Delivered! 🎉" : "Arriving in",
                          style: const TextStyle(color: Color(0xFFAAC4E8), fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(_isDelivered ? "🎉" : "$_etaMinutes mins",
                          style: const TextStyle(color: Colors.white, fontSize: 44,
                              fontWeight: FontWeight.w800, height: 1)),
                      const SizedBox(height: 4),
                      Text(widget.itemName, style: const TextStyle(color: Color(0xFFAAC4E8),
                          fontSize: 13, fontWeight: FontWeight.w600)),
                    ])),
                    Text(_isDelivered ? '🎉' : '📦',
                        style: const TextStyle(fontSize: 52)),
                  ]),
                ),
                const SizedBox(height: 18),
                _buildMap(context, t),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _legend(kGreen, "Green = Route (A*)", t),
                  const SizedBox(width: 16),
                  _legend(kHighlight, "Blue = Destination 📍", t),
                ]),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: t.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: t.border, width: 1)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Delivery Status", style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700, color: t.textPrimary)),
                    const SizedBox(height: 14),
                    ...List.generate(_steps.length, (i) {
                      final bool isActive  = _statusStep >= i;
                      final bool isCurrent = _statusStep == i;
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Column(children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                color: isActive ? kHighlight : t.border),
                            child: Center(
                              child: isCurrent && !_isDelivered
                                  ? const CupertinoActivityIndicator(
                                  color: Colors.white, radius: 7)
                                  : Icon(isActive ? CupertinoIcons.check_mark
                                  : CupertinoIcons.circle,
                                  color: isActive ? Colors.white : t.textSecondary,
                                  size: 13),
                            ),
                          ),
                          if (i < _steps.length - 1)
                            Container(width: 2, height: 34,
                                color: _statusStep > i ? kHighlight : t.border),
                        ]),
                        const SizedBox(width: 12),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_steps[i]["title"]!, style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive ? t.textPrimary : t.textSecondary)),
                            if (isActive) ...[
                              const SizedBox(height: 2),
                              Text(_steps[i]["sub"]!, style: TextStyle(
                                  fontSize: 11,
                                  color: isCurrent ? kHighlight : t.textSecondary,
                                  fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400)),
                            ],
                            const SizedBox(height: 18),
                          ]),
                        )),
                      ]);
                    }),
                  ]),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: t.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: t.border, width: 1)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text("Your Courier", style: TextStyle(fontSize: 12,
                          color: t.textSecondary, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: kHighlight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('FROM API ✅', style: TextStyle(fontSize: 9,
                            color: kHighlight, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [kHighlight, kAccentMid]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(
                            _riderName.isNotEmpty ? _riderName[0] : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_riderName, style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700, color: t.textPrimary)),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(CupertinoIcons.star_fill, size: 11, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text('$_riderRating · $_riderPlate',
                              style: TextStyle(fontSize: 11, color: t.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ])),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11)),
                        child: const Icon(CupertinoIcons.phone_fill,
                            color: CupertinoColors.systemGreen, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                            color: kHighlight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11)),
                        child: const Icon(CupertinoIcons.chat_bubble_fill,
                            color: kHighlight, size: 18),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: t.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: t.border, width: 1)),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: kHighlight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(CupertinoIcons.doc_text, color: kHighlight, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Order ID", style: TextStyle(fontSize: 10,
                          color: t.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(widget.orderId, style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600, color: t.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        );
      },
    );
  }
  Widget _legend(Color color, String label, _T t) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: t.textSecondary,
          fontWeight: FontWeight.w500)),
    ]);
  }
}
class _TrackerMapPainter extends CustomPainter {
  final bool dark;
  final int rows, cols;
  final List<(int, int)> path;
  final int riderIndex;
  final (int, int) dest;
  const _TrackerMapPainter({
    required this.dark, required this.rows, required this.cols,
    required this.path, required this.riderIndex, required this.dest,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width  / cols;
    final cellH = size.height / rows;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = dark ? const Color(0xFF0D0D0D) : const Color(0xFFE3EEFF));
    final road = Paint()
      ..color = dark ? const Color(0xFF2A2A2A) : Colors.white
      ..strokeWidth = 4;
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * cellH), Offset(size.width, r * cellH), road);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cellW, 0), Offset(c * cellW, size.height), road);
    }
    final block = Paint()..color = dark
        ? const Color(0xFF111111) : const Color(0xFFBDD5FF);
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c) % 3 != 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellW + 2, r * cellH + 2, cellW - 4, cellH - 4),
              const Radius.circular(3),
            ),
            block,
          );
        }
      }
    }
    if (path.length > 1) {
      final pastPaint = Paint()
        ..color = kGreen.withOpacity(0.25)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final futurePaint = Paint()
        ..color = kGreen
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      Offset cellCenter(int r, int c) =>
          Offset((c + 0.5) * cellW, (r + 0.5) * cellH);
      if (riderIndex > 0) {
        final pastPath = Path()..moveTo(cellCenter(path[0].$1, path[0].$2).dx,
            cellCenter(path[0].$1, path[0].$2).dy);
        for (int i = 1; i <= riderIndex && i < path.length; i++) {
          pastPath.lineTo(cellCenter(path[i].$1, path[i].$2).dx,
              cellCenter(path[i].$1, path[i].$2).dy);
        }
        canvas.drawPath(pastPath, pastPaint);
      }
      if (riderIndex < path.length - 1) {
        final futurePath = Path()
          ..moveTo(cellCenter(path[riderIndex].$1, path[riderIndex].$2).dx,
              cellCenter(path[riderIndex].$1, path[riderIndex].$2).dy);
        for (int i = riderIndex + 1; i < path.length; i++) {
          futurePath.lineTo(cellCenter(path[i].$1, path[i].$2).dx,
              cellCenter(path[i].$1, path[i].$2).dy);
        }
        canvas.drawPath(futurePath, futurePaint);
      }
    }
    final dx = (dest.$2 + 0.5) * cellW;
    final dy = (dest.$1 + 0.5) * cellH;
    final r  = min(cellW, cellH) * 0.38;
    canvas.drawCircle(Offset(dx, dy + 3), r,
        Paint()..color = kHighlight.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(dx, dy), r, Paint()..color = kHighlight);
    canvas.drawCircle(Offset(dx, dy), r * 0.45, Paint()..color = Colors.white);
    if (riderIndex < path.length) {
      final rc = path[riderIndex];
      final rx = (rc.$2 + 0.5) * cellW;
      final ry = (rc.$1 + 0.5) * cellH;
      final rr = min(cellW, cellH) * 0.32;
      canvas.drawCircle(Offset(rx, ry + 3), rr,
          Paint()..color = kGreen.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(Offset(rx, ry), rr, Paint()..color = kGreen);
      canvas.drawCircle(Offset(rx, ry), rr * 0.4, Paint()..color = Colors.white);
    }
  }
  @override
  bool shouldRepaint(covariant _TrackerMapPainter old) =>
      old.riderIndex != riderIndex || old.dark != dark || old.dest != dest;
}