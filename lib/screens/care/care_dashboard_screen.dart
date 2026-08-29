import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'today_module.dart';
import 'scan_meal_module.dart';
import 'log_entry_module.dart';
import 'care_network_module.dart';
import 'community_module.dart';
import 'sync_devices_module.dart';
import '../../managers/bluetooth_manager.dart';

class CareDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  const CareDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CareDashboardScreen> createState() => CareDashboardScreenState();
}

class CareDashboardScreenState extends State<CareDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabs = [
    'Today',
    'Community',
    'Scan Meal',
    'Log Entry',
    'Care Network'
  ];

  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _tabController.animateTo(index);
      _scrollToTab(index);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
    );
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex != 0) {
        _scrollToTab(widget.initialTabIndex);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CareDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      switchTab(widget.initialTabIndex);
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _scrollToTab(_tabController.index);
    }
  }

  void _scrollToTab(int index) {
    double offset = index * 100.0 - 150.0; 
    if (offset < 0) offset = 0;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GlucoRhythm',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Your Diabetes Management Partner',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: BluetoothManager(),
            builder: (context, _) {
              final bleManager = BluetoothManager();
              final isConnected = bleManager.isConnected;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: 'Hardware & CGM Sync Hub',
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SyncDevicesModule()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green.withValues(alpha: 0.12)
                            : colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isConnected
                              ? Colors.green.withValues(alpha: 0.3)
                              : colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? Icons.sensors : Icons.bluetooth_searching,
                            size: 16,
                            color: isConnected ? Colors.green : colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConnected ? 'Synced' : 'Devices',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isConnected ? Colors.green : colorScheme.primary,
                            ),
                          ),
                          if (isConnected) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildAnimatedTabBar(colorScheme),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TodayModule(),
          CommunityModule(),
          ScanMealModule(),
          LogEntryModule(),
          CareNetworkModule(),
        ],
      ),
    );
  }

  Widget _buildAnimatedTabBar(ColorScheme colorScheme) {
    final animation = _tabController.animation;
    if (animation == null) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double animValueSnapshot = animation.value;
            return Stack(
              children: [
                // Custom Indicator (Pill)
                Positioned(
                  left: animValueSnapshot * 110.0, // Approximate width + margin
                  child: Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_tabs.length, (index) {
                    // Animation value for individual tab text
                    double tabAnim = (1.0 - (animValueSnapshot - index).abs()).clamp(0.0, 1.0);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _tabController.animateTo(index);
                      },
                      child: Container(
                        width: 110,
                        alignment: Alignment.center,
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            color: Color.lerp(Colors.grey[600], colorScheme.primary, tabAnim),
                            fontWeight: tabAnim > 0.5 ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13 + (tabAnim * 2),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
