import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freshtrack/domain/common/civil_date.dart';

class CurrentDateScope extends InheritedWidget {
  const CurrentDateScope({required this.date, required super.child, super.key});
  final CivilDate date;

  static DateTime now(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CurrentDateScope>()
          ?.date
          .toLocalDateTime() ??
      DateTime.now();

  @override
  bool updateShouldNotify(CurrentDateScope oldWidget) => date != oldWidget.date;
}

/// Rebuilds date-dependent labels at midnight and after resuming the app.
class DayBoundary extends StatefulWidget {
  const DayBoundary({
    required this.child,
    this.clock = DateTime.now,
    super.key,
  });
  final Widget child;
  final DateTime Function() clock;
  @override
  State<DayBoundary> createState() => _DayBoundaryState();
}

class _DayBoundaryState extends State<DayBoundary> with WidgetsBindingObserver {
  Timer? _timer;
  late CivilDate _today;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = CivilDate.fromDateTime(widget.clock());
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = widget.clock();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), _refresh);
  }

  void _refresh() {
    if (!mounted) return;
    final today = CivilDate.fromDateTime(widget.clock());
    if (today != _today) setState(() => _today = today);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
    if (state == AppLifecycleState.paused) _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) =>
      CurrentDateScope(date: _today, child: widget.child);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
