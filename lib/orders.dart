import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
import 'theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final supabase = Supabase.instance.client;
  final box = Hive.box("database");

  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  final Map<String, Map<String, dynamic>> _riderData = {};
  StreamSubscription? _ordersSubscription;

  bool get isDark => box.get("isDark", defaultValue: false);

  @override
  void initState() {
    super.initState();
    _listenToOrders();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _listenToOrders() {
    _ordersSubscription = supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((rows) async {
      if (!mounted) return;
      setState(() {
        _orders = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
      await _fetchRiderData();
    });
  }

  Future<void> _fetchRiderData() async {
    if (_orders.isEmpty) return;
    final ids = _orders.map((o) => o['id'] as String).toList();
    try {
      final rows = await supabase
          .from('rider_locations')
          .select()
          .inFilter('order_id', ids);
      if (!mounted) return;
      final Map<String, Map<String, dynamic>> map = {};
      for (final r in (rows as List)) {
        map[r['order_id'] as String] = Map<String, dynamic>.from(r);
      }
      setState(() => _riderData.addAll(map));
    } catch (_) {}
  }

  Future<void> _refreshOrders() async {
    setState(() => _isLoading = true);
    try {
      final rows = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _orders = List<Map<String, dynamic>>.from(rows as List);
        _isLoading = false;
      });
      await _fetchRiderData();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered': return const Color(0xFF34A853);
      case 'on_the_way':
      case 'nearby': return const Color(0xFF1a73e8);
      case 'preparing': return const Color(0xFFF59E0B);
      default: return const Color(0xFF9E9E9E);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'delivered': return CupertinoIcons.checkmark_seal_fill;
      case 'on_the_way':
      case 'nearby': return CupertinoIcons.arrow_right_circle_fill;
      case 'preparing': return CupertinoIcons.archivebox_fill;
      default: return CupertinoIcons.clock_fill;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered': return 'Delivered';
      case 'on_the_way': return 'On the Way 🛵';
      case 'nearby': return 'Almost There 📍';
      case 'preparing': return 'Preparing 📦';
      case 'confirmed': return 'Confirmed ✅';
      default: return status.toUpperCase();
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, AppTheme t) {
    final orderId = order['id'] as String? ?? '';
    final itemName = order['food_name'] as String? ?? 'Unknown Item';
    final rider = _riderData[orderId];
    final riderStatus = rider?['status'] as String? ??
        order['status'] as String? ?? 'confirmed';
    final etaMinutes = rider?['eta_minutes'] as int? ?? 0;

    final isDelivered = riderStatus == 'delivered';
    final isTrackable = riderStatus == 'preparing' ||
        riderStatus == 'on_the_way' ||
        riderStatus == 'nearby';
    final statusColor = _statusColor(riderStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kHighlight.withOpacity(t.isDark ? 0.10 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [kHighlight, kAccentMid]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.desktopcomputer,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(itemName,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        orderId.length > 26
                            ? '${orderId.substring(0, 26)}…'
                            : orderId,
                        style: TextStyle(
                            fontSize: 10, color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(riderStatus),
                          color: statusColor, size: 11),
                      const SizedBox(width: 4),
                      Text(_statusLabel(riderStatus),
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),

            if (!isDelivered && etaMinutes > 0) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  Icon(CupertinoIcons.clock,
                      size: 11, color: t.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'ETA: $etaMinutes min${etaMinutes > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        color: t.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            if (rider != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: t.cardImg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Color(0xFF34A853),
                          Color(0xFF1a7a3a),
                        ]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          (rider['rider_name'] as String? ?? '?')
                              .isNotEmpty
                              ? (rider['rider_name'] as String)[0]
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rider['rider_name'] as String? ?? '---',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: t.textPrimary)),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.star_fill,
                                  size: 10, color: Color(0xFFFFC107)),
                              const SizedBox(width: 3),
                              Text(
                                '${rider['rider_rating'] ?? '--'} · ${rider['rider_plate'] ?? '---'}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: t.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.person_crop_circle,
                        color: Color(0xFF34A853), size: 16),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            if (isTrackable)
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: kHighlight,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _openTracker(order, rider),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.map_fill,
                          size: 13, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Track Location 🗺️',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),

            if (isDelivered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF34A853).withOpacity(0.35)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.checkmark_circle_fill,
                        size: 13, color: Color(0xFF34A853)),
                    SizedBox(width: 6),
                    Text('Delivered 🎉',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF34A853))),
                  ],
                ),
              ),

            if (!isTrackable && !isDelivered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: t.cardImg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(
                        color: kHighlight, radius: 7),
                    const SizedBox(width: 8),
                    Text('Waiting for rider...',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── UPDATED: Added riderStartLat & riderStartLng (Santa Ana, Pampanga) ──
  void _openTracker(
      Map<String, dynamic> order, Map<String, dynamic>? rider) {
    final orderId = order['id'] as String? ?? '';
    final itemName = order['food_name'] as String? ?? 'Your Order';

    // ── Santa Ana, Pampanga ──
    const double riderStartLat = 15.0820;
    const double riderStartLng = 120.7780;

    final destLat =
        (rider?['lat'] as num?)?.toDouble() ?? riderStartLat;
    final destLng =
        (rider?['lng'] as num?)?.toDouble() ?? riderStartLng;

    const double latStep = 0.002;
    const double lngStep = 0.002;
    const int kRows = 12;
    const int kCols = 10;

    final int destGridRow =
    ((riderStartLat + (kRows - 1) * latStep - destLat) / latStep)
        .round()
        .clamp(0, kRows - 1);
    final int destGridCol =
    ((destLng - riderStartLng) / lngStep)
        .round()
        .clamp(0, kCols - 1);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => RiderTrackerPage(
          orderId: orderId,
          itemName: itemName,
          destGridRow: destGridRow,
          destGridCol: destGridCol,
          destLat: destLat,
          destLng: destLng,
          riderStartLat: riderStartLat,   // ← ADDED
          riderStartLng: riderStartLng,   // ← ADDED
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['isDark']),
      builder: (context, _, __) {
        final t = AppTheme(isDark: isDark);

        return CupertinoPageScaffold(
          backgroundColor: t.page,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: t.card,
            border: Border(
                bottom: BorderSide(color: t.border, width: 0.5)),
            middle: Text('My Orders 📦',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary)),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _refreshOrders,
              child: const Icon(CupertinoIcons.refresh_circled,
                  color: kHighlight, size: 22),
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(
                      color: kHighlight, radius: 16),
                  const SizedBox(height: 14),
                  Text('Loading orders...',
                      style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )
                : _orders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📦',
                      style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text('No orders yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'Your orders will appear here\nafter you purchase a laptop!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: t.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            )
                : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        18, 18, 18, 8),
                    child: Row(
                      children: [
                        Text(
                          '${_orders.length} Order${_orders.length != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: kHighlight.withOpacity(0.12),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: const Text('REAL-TIME ⚡',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: kHighlight,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      18, 4, 18, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, i) =>
                          _buildOrderCard(_orders[i], t),
                      childCount: _orders.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}