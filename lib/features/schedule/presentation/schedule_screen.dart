import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/schedule_providers.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程安排'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => context.go('/schedule/add'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '周视图', icon: Icon(Icons.view_week)),
            Tab(text: '月视图', icon: Icon(Icons.calendar_month)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WeekView(),
          MonthView(),
        ],
      ),
    );
  }
}
