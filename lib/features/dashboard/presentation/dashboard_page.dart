import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../categories/logic/categoryNotifier.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../logic/dashboardNotifier.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/monthly_income_expenses_chart.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/weekday_rhythm_chart.dart';
import '../widgets/forecast_area_chart.dart';

// ─── Shared card helper ──────────────────────────────────────────────────────
Widget _card({
  required BuildContext context,
  required Widget child,
  Color? bg,
  EdgeInsets padding = const EdgeInsets.all(24),
  bool hover = false,
}) {
  final theme = Theme.of(context);
  return Container(
    decoration: bg != null ? theme.tintCardDecoration(bg) : theme.cardDecoration,
    padding: padding,
    child: child,
  );
}

// ─── Progress Ring ───────────────────────────────────────────────────────────
class _Ring extends StatelessWidget {
  final double value; // 0..1 (clamped to 1.2 for over-budget)
  final Color trackColor;
  final Color progressColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const _Ring({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    this.size = 72,
    this.strokeWidth = 6,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped,
          trackColor: trackColor,
          progressColor: progressColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, trackPaint);
    if (progress > 0) {
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

// ─── Tiny sparkline ──────────────────────────────────────────────────────────
class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double width;
  final double height;

  const _Sparkline({
    required this.data,
    required this.color,
    this.width = 80,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  const _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return;

    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (size.height * (data[i] - min) / range);
      pts.add(Offset(x, y));
    }

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.data != data;
}

// ─── Dashboard Page ──────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _coachIdx = 0;

  /// Builds coach tips from this user's actual data (biggest category,
  /// spend pace vs income, savings rate, weekday spending pattern, logging
  /// gaps) instead of a fixed set of generic messages. Falls back to a
  /// single generic tip only when there's not enough data yet (e.g. a
  /// brand-new account) for any of the data-driven ones to apply.
  List<({String headline, String body, String tint})> _buildCoachTips(
    DashboardNotifier notifier,
    CategoryNotifier catNotifier,
    Map<String, double> spendByCat,
    double income,
    double expenses,
  ) {
    final tips = <({String headline, String body, String tint})>[];
    final now = DateTime.now();

    // Biggest expense category this month.
    if (spendByCat.isNotEmpty && expenses > 0) {
      final top = spendByCat.entries.reduce((a, b) => a.value > b.value ? a : b);
      final cat = catNotifier.getCategoryById(top.key);
      final pct = (top.value / expenses * 100).round();
      if (cat != null && pct >= 25) {
        tips.add((
          headline: '${catEmoji(cat.name)} ${cat.name} is your biggest spend',
          body: '${cat.name} is $pct% of your spending this month '
              '(\$${top.value.toStringAsFixed(0)}) — that\'s where a small cut goes furthest.',
          tint: 'butter',
        ));
      }
    }

    // End-of-month pace vs income (same math as the forecast card).
    if (income > 0 && now.day > 0 && expenses > 0) {
      final avgDaily = expenses / now.day;
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      final projected = avgDaily * daysInMonth;
      final projectedPct = (projected / income * 100).round();
      if (projected > income) {
        tips.add((
          headline: 'On pace to go over this month',
          body: 'At your current rate you\'ll spend \$${projected.toStringAsFixed(0)} this month '
              '— $projectedPct% of your income. Dial back to stay in the green.',
          tint: 'coral',
        ));
      } else if (projectedPct <= 70) {
        tips.add((
          headline: 'Comfortably under pace 🎉',
          body: 'Your spending projects to \$${projected.toStringAsFixed(0)} this month, '
              'only $projectedPct% of income — plenty of room to save.',
          tint: 'mint',
        ));
      }
    }

    // Savings rate this month.
    if (income > 0) {
      final savings = income - expenses;
      final rate = (savings / income * 100).round();
      if (savings > 0) {
        tips.add((
          headline: 'Saving $rate% this month',
          body: 'You\'ve saved \$${savings.toStringAsFixed(0)} of \$${income.toStringAsFixed(0)} '
              'income so far — keep logging to see it compound.',
          tint: 'lavender',
        ));
      }
    }

    // Weekday spending pattern (same 8-week window as the rhythm chart).
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 55));
    final weekdayTotals = List<double>.filled(7, 0);
    final weekdayCounts = List<int>.filled(7, 0);
    for (int i = 0; i <= 55; i++) {
      weekdayCounts[windowStart.add(Duration(days: i)).weekday - 1]++;
    }
    for (final cf in notifier.cashflows) {
      if (!cf.isExpense) continue;
      final day = DateTime(cf.date.year, cf.date.month, cf.date.day);
      if (day.isBefore(windowStart) || day.isAfter(today)) continue;
      weekdayTotals[day.weekday - 1] += cf.amount.abs();
    }
    final weekdayAvgs = List.generate(7, (i) => weekdayCounts[i] > 0 ? weekdayTotals[i] / weekdayCounts[i] : 0.0);
    final peakAvg = weekdayAvgs.fold(0.0, (p, e) => e > p ? e : p);
    if (peakAvg > 0) {
      const labels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final peakDay = labels[weekdayAvgs.indexOf(peakAvg)];
      tips.add((
        headline: '$peakDay hits your wallet hardest',
        body: 'You spend about \$${peakAvg.toStringAsFixed(0)} on average each $peakDay '
            '— plan ahead if you want to change that pattern.',
        tint: 'sky',
      ));
    }

    // Logging-gap nudge.
    if (notifier.cashflows.isNotEmpty) {
      final lastDate = notifier.cashflows.map((c) => c.date).reduce((a, b) => a.isAfter(b) ? a : b);
      final daysSince = today.difference(DateTime(lastDate.year, lastDate.month, lastDate.day)).inDays;
      if (daysSince >= 2) {
        tips.add((
          headline: 'It\'s been $daysSince days since your last entry',
          body: 'Logging regularly is what makes these numbers useful — jump into Cashflow and catch up.',
          tint: 'coral',
        ));
      }
    }

    if (tips.isEmpty) {
      tips.add((
        headline: 'Track every dollar 💰',
        body: 'Logging your expenses daily gives you a clear picture of where your money is going.',
        tint: 'mint',
      ));
    }

    return tips;
  }

  void _showEditBalanceDialog(BuildContext context, DashboardNotifier notifier) {
    final ctrl = TextEditingController(text: notifier.balance.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Balance', style: theme.serif(22)),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Enter new balance'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: theme.sans(14, color: theme.ink2)),
            ),
            TextButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text);
                if (v != null) notifier.updateBalance(v);
                Navigator.pop(ctx);
              },
              child: Text('Save', style: theme.sans(14, weight: FontWeight.w600, color: theme.accentColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = Provider.of<DashboardNotifier>(context);
    final catNotifier = Provider.of<CategoryNotifier>(context);
    final mobile = isMobile(context);
    final compact = isCompact(context);

    if (notifier.loading) {
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
    }

    final allCashflows = notifier.last30DaysCashflows;
    final income = notifier.monthIncome;
    final expenses = notifier.monthExpenses;
    final balance = notifier.balance;

    // Build spending by category for budget rings
    final spendByCat = <String, double>{};
    for (final cf in notifier.currentMonthCashflows) {
      if (cf.isExpense) {
        spendByCat[cf.categoryId] = (spendByCat[cf.categoryId] ?? 0) + cf.amount.abs();
      }
    }
    final maxCatSpend = spendByCat.values.fold(0.0, max);

    final coaches = _buildCoachTips(notifier, catNotifier, spendByCat, income, expenses);
    final coach = coaches[_coachIdx % coaches.length];

    // Recent transactions (last 5)
    final recent = notifier.last7DaysCashflows.take(5).toList();

    // Daily spend sparkline for last 14 days
    final last14 = <double>[];
    final now = DateTime.now();
    for (int i = 13; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayTotal = allCashflows
          .where((c) =>
              c.isExpense &&
              c.date.year == day.year &&
              c.date.month == day.month &&
              c.date.day == day.day)
          .fold(0.0, (s, c) => s + c.amount.abs());
      last14.add(dayTotal);
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: _PageHeader(
            title: 'Good ${_greeting()}, ${_firstName(context)} ☀️',
            sub: 'Track your spending and grow your wealth',
            mobile: mobile,
          ),
        ),

        SizedBox(height: mobile ? 14 : 20),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 28),
          child: Column(
            children: [
              // ── Hero row: balance + streak + AI coach ────────────────────
              // Below `compact`, there isn't room for the balance card and
              // streak column to sit side by side without cramming — stack
              // them instead. True `mobile` keeps the minimal streak banner;
              // the wider-but-still-stacked band (mobile..compact) gets the
              // fuller streak column since a full-width column has plenty
              // of room for it. The AI coach card lives at the bottom of
              // this same column (under the streak/income-expense info)
              // rather than as its own full-width row.
              mobile
                  ? Column(children: [
                      _BalanceCard(context, balance, income, expenses, last14, () => _showEditBalanceDialog(context, notifier), mobile),
                      const SizedBox(height: 12),
                      _StreakRow(context, mobile),
                      SizedBox(height: mobile ? 12 : 18),
                      _CoachCard(context, coach, () {
                        setState(() => _coachIdx = (_coachIdx + 1) % coaches.length);
                      }, mobile),
                    ])
                  : compact
                      ? Column(children: [
                          _BalanceCard(context, balance, income, expenses, last14, () => _showEditBalanceDialog(context, notifier), mobile),
                          const SizedBox(height: 18),
                          _StreakColumn(context, income, expenses, mobile),
                          SizedBox(height: mobile ? 12 : 18),
                          _CoachCard(context, coach, () {
                            setState(() => _coachIdx = (_coachIdx + 1) % coaches.length);
                          }, mobile),
                        ])
                      : // Note: deliberately NOT using IntrinsicHeight+stretch
                      // here (unlike the other paired rows below) — with
                      // the AI coach card added, this right-hand column
                      // triggered a persistent few-px RenderFlex overflow
                      // under IntrinsicHeight that survived making every
                      // piece of its content deterministically sized
                      // (fixed heights, maxLines everywhere). That pointed
                      // to something below the widget layer (most likely
                      // web-font metrics settling after GoogleFonts loads,
                      // after IntrinsicHeight's dry-layout pass already
                      // ran) rather than an actual layout bug to fix here.
                      // Natural heights avoid the whole failure mode; this
                      // row wasn't the one flagged as visually unbalanced.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 14,
                            child: _BalanceCard(context, balance, income, expenses, last14, () => _showEditBalanceDialog(context, notifier), mobile),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 10,
                            child: Column(
                              children: [
                                _StreakColumn(context, income, expenses, mobile),
                                SizedBox(height: mobile ? 12 : 18),
                                _CoachCard(context, coach, () {
                                  setState(() => _coachIdx = (_coachIdx + 1) % coaches.length);
                                }, mobile),
                              ],
                            ),
                          ),
                        ],
                      ),

              SizedBox(height: mobile ? 12 : 18),

              // ── Recent activity + [This month, Spending this month] ─────
              // 1 card on the left, 2 stacked on the right — recent activity
              // (5 items) is sized to roughly match the combined height of
              // the month summary + top-4 budget rings below it.
              compact
                  ? Column(children: [
                      _RecentCard(context, recent, catNotifier, mobile),
                      SizedBox(height: mobile ? 12 : 18),
                      _MonthSummaryCard(context, income, expenses, mobile),
                      SizedBox(height: mobile ? 12 : 18),
                      _BudgetRingsCard(context, catNotifier, spendByCat, maxCatSpend, income, mobile),
                    ])
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 14,
                            child: _RecentCard(context, recent, catNotifier, mobile),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 10,
                            child: Column(
                              children: [
                                _MonthSummaryCard(context, income, expenses, mobile),
                                SizedBox(height: mobile ? 12 : 18),
                                _BudgetRingsCard(context, catNotifier, spendByCat, maxCatSpend, income, mobile),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

              SizedBox(height: mobile ? 12 : 18),

              // ── Forecast + income/spend row ──────────────────────────────
              compact
                  ? Column(children: [
                      _ForecastCard(context, notifier, mobile),
                      SizedBox(height: mobile ? 12 : 18),
                      _IncomeVsSpendCard(context, notifier, mobile),
                    ])
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _ForecastCard(context, notifier, mobile)),
                          const SizedBox(width: 18),
                          Expanded(child: _IncomeVsSpendCard(context, notifier, mobile)),
                        ],
                      ),
                    ),

              SizedBox(height: mobile ? 12 : 18),

              // ── Donut breakdown + weekday rhythm row ─────────────────────
              compact
                  ? Column(children: [
                      _DonutCard(context, notifier, catNotifier, mobile),
                      SizedBox(height: mobile ? 12 : 18),
                      _WeekdayRhythmCard(context, notifier, mobile),
                    ])
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _DonutCard(context, notifier, catNotifier, mobile)),
                          const SizedBox(width: 18),
                          Expanded(child: _WeekdayRhythmCard(context, notifier, mobile)),
                        ],
                      ),
                    ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(child: content),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  String _firstName(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'there';
    return name.split(' ').first;
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final String sub;
  final bool mobile;
  const _PageHeader({required this.title, required this.sub, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.serif(mobile ? 28 : 36)),
        const SizedBox(height: 4),
        Text(sub, style: theme.sans(13.5, color: theme.ink2)),
      ],
    );
  }
}

Widget _BalanceCard(
  BuildContext context,
  double balance,
  double income,
  double expenses,
  List<double> sparkData,
  VoidCallback onEdit,
  bool mobile,
) {
  final theme = Theme.of(context);
  final savings = income - expenses;
  final savingsPct = income > 0 ? (savings / income * 100) : 0.0;
  final positive = savings >= 0;

  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 22 : 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'NET WORTH · THIS MONTH',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.instrumentSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: theme.ink2,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Edit', style: theme.sans(12, color: theme.ink2)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '\$${balance.toStringAsFixed(2)}',
          style: GoogleFonts.instrumentSerif(
            fontSize: mobile ? 44 : 62,
            color: theme.ink,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: positive ? theme.tintMintBg : theme.tintCoralBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 12,
                    color: positive ? theme.tintMintInk : theme.tintCoralInk,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${savingsPct.abs().toStringAsFixed(1)}% saved',
                    style: theme.sans(12.5, weight: FontWeight.w600,
                        color: positive ? theme.tintMintInk : theme.tintCoralInk),
                  ),
                ],
              ),
            ),
            Text('this month', style: theme.sans(12.5, color: theme.ink2)),
          ],
        ),
        const SizedBox(height: 16),
        if (sparkData.isNotEmpty)
          _Sparkline(
            data: sparkData,
            color: theme.accentColor,
            width: double.infinity,
            height: mobile ? 60 : 80,
          ),
      ],
    ),
  );
}

Widget _StreakColumn(BuildContext context, double income, double expenses, bool mobile) {
  final theme = Theme.of(context);
  return Column(
    children: [
      // Streak card. Fixed-height Row for the same reason as the mini
      // cards below — Row's intrinsic height for Expanded children is
      // only approximate and can overflow by a few px under
      // IntrinsicHeight.
      _card(
        context: context,
        bg: theme.tintButterBg,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: theme.tintButterInk,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🔥', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Keep logging!',
                      style: theme.serif(22, color: theme.tintButterInk),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Every day counts',
                      style: theme.sans(12, color: theme.tintButterInk.withOpacity(0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      // Income / Expense mini cards. Fixed height (rather than left to
      // Row+Expanded's own content-driven sizing) because a Row's
      // intrinsic-height computation for Expanded children is only an
      // approximation — it can diverge by a few px from what real layout
      // actually needs, and this Row can end up inside an IntrinsicHeight
      // ancestor (see hero row) where that gap shows up as an overflow.
      SizedBox(
        height: 90,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _card(
                context: context,
                bg: theme.tintMintBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('INCOME · MTD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSans(
                      fontSize: 10.5, fontWeight: FontWeight.w700,
                      color: theme.tintMintInk, letterSpacing: 0.8,
                    )),
                    const SizedBox(height: 6),
                    Text('\$${income.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.serif(28, color: theme.tintMintInk)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _card(
                context: context,
                bg: theme.tintCoralBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('SPENT · MTD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.instrumentSans(
                      fontSize: 10.5, fontWeight: FontWeight.w700,
                      color: theme.tintCoralInk, letterSpacing: 0.8,
                    )),
                    const SizedBox(height: 6),
                    Text('\$${expenses.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.serif(28, color: theme.tintCoralInk)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _StreakRow(BuildContext context, bool mobile) {
  final theme = Theme.of(context);
  return _card(
    context: context,
    bg: theme.tintButterBg,
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: theme.tintButterInk, shape: BoxShape.circle),
          child: const Center(child: Text('🔥', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keep logging!',
                  style: theme.serif(20, color: theme.tintButterInk),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('Every day counts', style: theme.sans(12, color: theme.tintButterInk.withOpacity(0.8))),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _CoachCard(
  BuildContext context,
  ({String headline, String body, String tint}) coach,
  VoidCallback onNext,
  bool mobile,
) {
  final theme = Theme.of(context);
  final (bg, ink) = _tintPair(theme, coach.tint);

  return _card(
    context: context,
    bg: bg,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          child: Icon(Icons.auto_awesome_rounded, color: bg, size: 22),
        ),
        const SizedBox(width: 16),
        // Fixed height for the same IntrinsicHeight-vs-real-layout reason
        // as the body text below — this card's outer Row (icon + this
        // Expanded content) is itself subject to the same approximate
        // Row-intrinsic-height computation, so it needs the same
        // determinism to avoid overflowing when this card sits inside an
        // IntrinsicHeight ancestor (see hero row).
        Expanded(
          child: SizedBox(
            height: mobile ? 132 : 138,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SPENDO · AI COACH',
                  style: GoogleFonts.instrumentSans(
                      fontSize: 10.5, fontWeight: FontWeight.w700,
                      color: ink.withOpacity(0.7), letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(coach.headline,
                  style: theme.serif(mobile ? 20 : 24, color: ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // Fixed height (not just maxLines) so this card's height
              // can't vary between IntrinsicHeight's dry-layout pass and
              // its real layout pass — with unconstrained wrapping, subtle
              // width differences between those two passes can wrap the
              // text to a different number of lines and overflow the card
              // by a few px. A tight-height SizedBox always reports the
              // same size regardless of what its child would need.
              SizedBox(
                height: 36,
                child: Text(coach.body,
                    style: theme.sans(13.5, color: ink.withOpacity(0.82)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: ink.withOpacity(0.15),
                    border: Border.all(color: ink.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next tip', style: theme.sans(12.5, color: ink)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14, color: ink),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _BudgetRingsCard(
  BuildContext context,
  CategoryNotifier catNotifier,
  Map<String, double> spendByCat,
  double maxSpend,
  double income,
  bool mobile,
) {
  final theme = Theme.of(context);
  // Top 4 by amount actually spent, not just the first 4 in list order —
  // that's what makes this card useful at a glance.
  final cats = catNotifier.expenseCategories.toList()
    ..sort((a, b) => (spendByCat[b.id] ?? 0).compareTo(spendByCat[a.id] ?? 0));
  final topCats = cats.take(4).toList();
  if (topCats.isEmpty) return const SizedBox.shrink();

  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spending this month', style: theme.serif(mobile ? 20 : 22)),
        const SizedBox(height: 2),
        Text('Top ${topCats.length} categories',
            style: theme.sans(13, color: theme.ink2)),
        const SizedBox(height: 18),
        // Rings need real room to breathe. This card can end up in very
        // different width contexts (full-width row, or one of two stacked
        // cards in a narrower column) — a fixed item width lets Wrap
        // reflow naturally to however many columns actually fit, without
        // needing to measure the container (which would require
        // LayoutBuilder, and this card can sit inside an IntrinsicHeight
        // ancestor for row-height matching, which LayoutBuilder can't
        // support — see CategoryDonutChart for the same constraint).
        Wrap(
          spacing: 12,
          runSpacing: 18,
          children: topCats.map((cat) {
            final spent = spendByCat[cat.id] ?? 0;
            final progress = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;
            final tintInk = _colorFromCategory(theme, cat.color);
            final tintBg = tintInk.withOpacity(0.12);

            return SizedBox(
              // Sized so all 4 fit on one line within this card's width —
              // this card shares its column with "This month" above it, so
              // it never gets more than roughly that card's width even on
              // a wide screen (this is a 10/24-flex column, not the full
              // page), so a fixed small size is safe rather than needing
              // to measure the container.
              width: mobile ? 78 : 104,
              child: Column(
                children: [
                  _Ring(
                    value: progress,
                    trackColor: tintBg,
                    progressColor: tintInk,
                    size: mobile ? 36 : 48,
                    strokeWidth: 5,
                    child: Text(
                      catEmoji(cat.name),
                      style: TextStyle(fontSize: mobile ? 13 : 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    cat.name,
                    style: theme.sans(12, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '\$${spent.toStringAsFixed(0)}',
                    style: theme.sans(11.5, color: theme.ink2),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _RecentCard(
  BuildContext context,
  List<Cashflow> transactions,
  CategoryNotifier catNotifier,
  bool mobile,
) {
  final theme = Theme.of(context);
  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent activity', style: theme.serif(mobile ? 20 : 22)),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('No recent transactions', style: theme.sans(13.5, color: theme.ink2)),
            ),
          )
        else
          ...transactions.asMap().entries.map((entry) {
            final i = entry.key;
            final tx = entry.value;
            final cat = catNotifier.getCategoryById(tx.categoryId);
            final catName = cat?.name ?? 'Unknown';
            final isIncome = tx.isIncome;
            final tintInk = isIncome ? theme.tintMintInk : (cat != null ? _colorFromCategory(theme, cat.color) : theme.ink2);
            final tintBg = tintInk.withOpacity(0.12);
            final daysAgo = DateTime.now().difference(tx.date).inDays;
            final timeLabel = daysAgo == 0 ? 'Today' : daysAgo == 1 ? 'Yesterday' : '${daysAgo}d ago';

            return Container(
              decoration: BoxDecoration(
                border: i > 0 ? Border(top: BorderSide(color: theme.border)) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: tintBg, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(catEmoji(catName), style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(catName, style: theme.sans(14, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('$timeLabel · ${tx.date.hour.toString().padLeft(2,'0')}:${tx.date.minute.toString().padLeft(2,'0')}',
                              style: theme.sans(12, color: theme.ink2), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(
                      isIncome
                          ? '+\$${tx.amount.toStringAsFixed(2)}'
                          : '-\$${tx.amount.abs().toStringAsFixed(2)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? theme.tintMintInk : theme.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    ),
  );
}

Widget _MonthSummaryCard(
  BuildContext context,
  double income,
  double expenses,
  bool mobile,
) {
  final theme = Theme.of(context);
  final savings = income - expenses;
  final rate = income > 0 ? (savings / income * 100).clamp(0.0, 100.0) : 0.0;

  return _card(
    context: context,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This month', style: theme.serif(22)),
        const SizedBox(height: 16),
        _SummaryRow(
          context: context,
          label: 'Income',
          value: '\$${income.toStringAsFixed(2)}',
          tintBg: theme.tintMintBg,
          tintInk: theme.tintMintInk,
          icon: Icons.arrow_downward_rounded,
        ),
        const SizedBox(height: 10),
        _SummaryRow(
          context: context,
          label: 'Expenses',
          value: '\$${expenses.toStringAsFixed(2)}',
          tintBg: theme.tintCoralBg,
          tintInk: theme.tintCoralInk,
          icon: Icons.arrow_upward_rounded,
        ),
        const SizedBox(height: 14),
        Container(
          height: 1,
          color: theme.border,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved', style: theme.sans(13.5, weight: FontWeight.w600)),
            Text(
              '\$${savings.toStringAsFixed(2)}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: savings >= 0 ? theme.tintMintInk : theme.tintCoralInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Save rate bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate / 100,
            minHeight: 6,
            backgroundColor: theme.surface2,
            valueColor: AlwaysStoppedAnimation(
                savings >= 0 ? theme.tintMintInk : theme.tintCoralInk),
          ),
        ),
        const SizedBox(height: 6),
        Text('${rate.toStringAsFixed(1)}% saving rate',
            style: theme.sans(11.5, color: theme.ink2)),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final BuildContext context;
  final String label;
  final String value;
  final Color tintBg;
  final Color tintInk;
  final IconData icon;

  const _SummaryRow({
    required this.context,
    required this.label,
    required this.value,
    required this.tintBg,
    required this.tintInk,
    required this.icon,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: tintBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: tintInk, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.sans(13.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: tintInk,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.sans(11.5, color: theme.ink2)),
      ],
    );
  }
}

Widget _IncomeVsSpendCard(BuildContext context, DashboardNotifier notifier, bool mobile) {
  final theme = Theme.of(context);
  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income vs spend', style: theme.serif(mobile ? 20 : 22)),
                  const SizedBox(height: 2),
                  Text('Last 6 months', style: theme.sans(13, color: theme.ink2)),
                ],
              ),
            ),
            Row(children: [
              _Legend(color: theme.tintMintInk, label: 'income'),
              const SizedBox(width: 12),
              _Legend(color: theme.tintCoralInk, label: 'spend'),
            ]),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: MonthlyIncomeExpensesChart(
            cashflows: notifier.last6MonthsCashflows,
          ),
        ),
      ],
    ),
  );
}

Widget _ForecastCard(BuildContext context, DashboardNotifier notifier, bool mobile) {
  final theme = Theme.of(context);
  final now = DateTime.now();
  final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
  final daysElapsed = now.day;
  final expenses = notifier.monthExpenses;
  final avgDailySpend = daysElapsed > 0 ? expenses / daysElapsed : 0.0;
  final projectedExpenses = avgDailySpend * daysInMonth;
  final projectedSavings = notifier.monthIncome - projectedExpenses;
  final onTrack = projectedSavings >= 0;

  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('End-of-month forecast', style: theme.serif(mobile ? 20 : 22)),
        const SizedBox(height: 2),
        Text('Based on your pace this month', style: theme.sans(13, color: theme.ink2)),
        const SizedBox(height: 14),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              '${projectedSavings >= 0 ? '+' : '-'}\$${projectedSavings.abs().toStringAsFixed(0)}',
              style: theme.serif(mobile ? 32 : 36),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: onTrack ? theme.tintMintBg : theme.tintCoralBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  onTrack ? 'on track' : 'over budget',
                  style: theme.sans(11.5, weight: FontWeight.w600, color: onTrack ? theme.tintMintInk : theme.tintCoralInk),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Projected spend: \$${projectedExpenses.toStringAsFixed(0)} by month end',
          style: theme.sans(12.5, color: theme.ink2),
        ),
        const SizedBox(height: 16),
        ForecastAreaChart(cashflows: notifier.currentMonthCashflows),
      ],
    ),
  );
}

Widget _DonutCard(
  BuildContext context,
  DashboardNotifier notifier,
  CategoryNotifier catNotifier,
  bool mobile,
) {
  final theme = Theme.of(context);
  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Where it goes', style: theme.serif(mobile ? 20 : 22)),
        const SizedBox(height: 2),
        Text('Spending by category · this month', style: theme.sans(13, color: theme.ink2)),
        const SizedBox(height: 16),
        CategoryDonutChart(
          cashflows: notifier.currentMonthCashflows,
          categories: catNotifier.categories,
          stacked: mobile,
        ),
      ],
    ),
  );
}

Widget _WeekdayRhythmCard(BuildContext context, DashboardNotifier notifier, bool mobile) {
  final theme = Theme.of(context);
  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your spending rhythm', style: theme.serif(mobile ? 20 : 22)),
        const SizedBox(height: 2),
        Text('Average by day of week · last 8 weeks', style: theme.sans(13, color: theme.ink2)),
        const SizedBox(height: 16),
        WeekdayRhythmChart(cashflows: notifier.cashflows),
      ],
    ),
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

(Color, Color) _tintPair(ThemeData theme, String tint) {
  switch (tint) {
    case 'mint':     return (theme.tintMintBg,     theme.tintMintInk);
    case 'coral':    return (theme.tintCoralBg,    theme.tintCoralInk);
    case 'butter':   return (theme.tintButterBg,   theme.tintButterInk);
    case 'lavender': return (theme.tintLavenderBg, theme.tintLavenderInk);
    case 'sky':      return (theme.tintSkyBg,      theme.tintSkyInk);
    case 'rose':     return (theme.tintRoseBg,     theme.tintRoseInk);
    default:         return (theme.tintMintBg,     theme.tintMintInk);
  }
}

Color _colorFromCategory(ThemeData theme, Color catColor) {
  // Map the category's stored color to the nearest semantic tint ink
  final palette = [
    theme.tintMintInk, theme.tintCoralInk, theme.tintButterInk,
    theme.tintLavenderInk, theme.tintSkyInk, theme.tintRoseInk,
  ];
  // Find closest by hue
  double bestDist = double.infinity;
  Color best = theme.tintMintInk;
  for (final c in palette) {
    final dist = _colorDist(catColor, c);
    if (dist < bestDist) {
      bestDist = dist;
      best = c;
    }
  }
  return best;
}

double _colorDist(Color a, Color b) {
  final dr = (a.red - b.red).toDouble();
  final dg = (a.green - b.green).toDouble();
  final db = (a.blue - b.blue).toDouble();
  return dr * dr + dg * dg + db * db;
}

String catEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('food') || n.contains('grocer') || n.contains('eat')) return '🥬';
  if (n.contains('dine') || n.contains('restaur') || n.contains('cafe')) return '🍜';
  if (n.contains('transport') || n.contains('uber') || n.contains('taxi')) return '🚇';
  if (n.contains('rent') || n.contains('hous') || n.contains('home')) return '🏠';
  if (n.contains('shop') || n.contains('cloth')) return '🛍️';
  if (n.contains('sub') || n.contains('stream')) return '📺';
  if (n.contains('health') || n.contains('gym') || n.contains('well')) return '🧘';
  if (n.contains('fun') || n.contains('entertain') || n.contains('movie')) return '🎟️';
  if (n.contains('salary') || n.contains('income') || n.contains('pay')) return '💰';
  if (n.contains('invest') || n.contains('saving')) return '📈';
  return '💳';
}
