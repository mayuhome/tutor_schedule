import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/color_schemes.dart';
import 'widgets/week_view.dart';
import 'widgets/month_view.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IosColors.systemBackground(context),
      appBar: AppBar(
        title: const Text('课程安排'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled, size: 24),
            onPressed: () => context.go('/schedule/add'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: IosColors.systemBlue,
          unselectedLabelColor: IosColors.secondaryLabel(context),
          indicatorColor: IosColors.systemBlue,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: IosColors.separator(context),
          tabs: const [
            Tab(text: '周视图'),
            Tab(text: '月视图'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [WeekView(), MonthView()],
      ),
    );
  }
}
