import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';

final hourlyRateProvider = StateProvider<double>((ref) => 200.0);
final reminderEnabledProvider = StateProvider<bool>((ref) => true);
final defaultReminderMinutesProvider = StateProvider<int>((ref) => 30);
