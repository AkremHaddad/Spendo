import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../categories/logic/categoryNotifier.dart';
import '../../categories/data/models/category.dart';
import '../../categories/category_style_options.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../logic/dashboardNotifier.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/monthly_income_expenses_chart.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/weekday_rhythm_chart.dart';
import '../widgets/forecast_area_chart.dart';
import '../widgets/net_worth_trend_chart.dart';

// ─── AI coach tip ────────────────────────────────────────────────────────────
// [categoryId] lets the card render that category's real icon/color (see
// _CoachCard) instead of a generic badge; [icon] is the badge for tips that
// aren't about one specific category and is ignored when categoryId is set.
typedef CoachTip = ({
  String headline,
  String body,
  String tint,
  String? categoryId,
  IconData? icon,
});

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


// ─── Dashboard Page ──────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _coachIdx = 0;

  /// Builds coach tips from this user's actual data: budget-goal overruns
  /// and near-misses, month-over-month category swings, the biggest expense
  /// category, spend pace vs income, savings rate, weekday spending pattern,
  /// and logging gaps — instead of a fixed set of generic messages. Tips
  /// tied to one category carry its id (see [CoachTip.categoryId]) so the
  /// card can render that category's real icon/color. Falls back to a
  /// single generic tip only when there's not enough data yet (e.g. a
  /// brand-new account) for any of the data-driven ones to apply.
  List<CoachTip> _buildCoachTips(
    DashboardNotifier notifier,
    CategoryNotifier catNotifier,
    Map<String, double> spendByCat,
    double income,
    double expenses,
  ) {
    final tips = <CoachTip>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysElapsed = now.day;
    final records = notifier.last6MonthlyRecords; // oldest → newest, always 6
    final prevRecord = records[records.length - 2];
    final prevTotal = prevRecord.expenses;
    // Floor below which a category's month-over-month swing is just noise —
    // scaled to the user's own prior spending rather than a fixed dollar
    // amount, so it holds up regardless of income/currency scale.
    final minSignal = prevTotal * 0.05;

    // Overall monthly budget goal (set on the balance doc, separate from any
    // per-category goals) — the single biggest-picture alert, so it leads
    // even the per-category budget tips below.
    final overallGoal = notifier.monthlyGoal;
    if (overallGoal != null && overallGoal > 0) {
      final ratio = expenses / overallGoal;
      if (expenses > overallGoal) {
        tips.add((
          headline: 'Over your monthly budget',
          body: 'You\'ve spent \$${expenses.toStringAsFixed(0)} of your \$${overallGoal.toStringAsFixed(0)} '
              'overall goal — \$${(expenses - overallGoal).toStringAsFixed(0)} over for the month.',
          tint: 'coral',
          categoryId: null,
          icon: Icons.report_problem_rounded,
        ));
      } else if (ratio >= 0.85) {
        tips.add((
          headline: 'Nearing your monthly budget',
          body: '\$${expenses.toStringAsFixed(0)} of your \$${overallGoal.toStringAsFixed(0)} goal spent '
              '(${(ratio * 100).round()}%) — pace yourself for the rest of the month.',
          tint: 'butter',
          categoryId: null,
          icon: Icons.speed_rounded,
        ));
      }
    }

    // Budget-goal overruns are the single most actionable thing a coach can
    // flag, so they lead the list — worst offender (by dollars over) first.
    final overBudget = <(Category, double, double)>[];
    final nearGoal = <(Category, double, double, double)>[];
    for (final cat in catNotifier.expenseCategories) {
      final goal = cat.monthlyGoal;
      if (goal == null || goal <= 0) continue;
      final spent = spendByCat[cat.id] ?? 0;
      if (spent > goal) {
        overBudget.add((cat, spent, goal));
      } else {
        final ratio = spent / goal;
        if (ratio >= 0.75) nearGoal.add((cat, spent, goal, ratio));
      }
    }
    if (overBudget.isNotEmpty) {
      overBudget.sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
      final (cat, spent, goal) = overBudget.first;
      tips.add((
        headline: '${cat.name} is over budget',
        body: 'You\'ve spent \$${spent.toStringAsFixed(0)} of your \$${goal.toStringAsFixed(0)} '
            '${cat.name} goal this month — \$${(spent - goal).toStringAsFixed(0)} over.',
        tint: 'coral',
        categoryId: cat.id,
        icon: Icons.warning_amber_rounded,
      ));
    }
    if (nearGoal.isNotEmpty) {
      nearGoal.sort((a, b) => b.$4.compareTo(a.$4));
      final (cat, spent, goal, ratio) = nearGoal.first;
      tips.add((
        headline: '${cat.name} is close to its limit',
        body: '\$${spent.toStringAsFixed(0)} of your \$${goal.toStringAsFixed(0)} goal spent '
            '(${(ratio * 100).round()}%) — a little more headroom to watch.',
        tint: 'butter',
        categoryId: cat.id,
        icon: Icons.speed_rounded,
      ));
    }

    // Biggest expense category this month.
    if (spendByCat.isNotEmpty && expenses > 0) {
      final top = spendByCat.entries.reduce((a, b) => a.value > b.value ? a : b);
      final cat = catNotifier.getCategoryById(top.key);
      final pct = (top.value / expenses * 100).round();
      if (cat != null && pct >= 25) {
        tips.add((
          headline: '${cat.name} is your biggest spend',
          body: '${cat.name} is $pct% of your spending this month '
              '(\$${top.value.toStringAsFixed(0)}) — that\'s where a small cut goes furthest.',
          tint: 'butter',
          categoryId: cat.id,
          icon: null,
        ));
      }
    }

    // Month-over-month category swings — biggest jump and biggest drop,
    // only against categories that already had meaningful spend last month
    // (so a category going from $0 to a few dollars doesn't read as a
    // "spike").
    if (prevTotal > 0) {
      (Category, double, double)? biggestJump; // (cat, curr, prev)
      (Category, double, double)? biggestDrop; // (cat, curr, prev)
      for (final entry in spendByCat.entries) {
        final cat = catNotifier.getCategoryById(entry.key);
        if (cat == null) continue;
        final prev = prevRecord.spendByCategory[entry.key] ?? 0;
        if (prev < minSignal) continue;
        final curr = entry.value;
        if (curr - prev >= prev * 0.4) {
          if (biggestJump == null || (curr - prev) > (biggestJump.$2 - biggestJump.$3)) {
            biggestJump = (cat, curr, prev);
          }
        } else if (prev - curr >= prev * 0.4) {
          if (biggestDrop == null || (prev - curr) > (biggestDrop.$3 - biggestDrop.$2)) {
            biggestDrop = (cat, curr, prev);
          }
        }
      }
      if (biggestJump != null) {
        final (cat, curr, prev) = biggestJump;
        final pct = ((curr - prev) / prev * 100).round();
        tips.add((
          headline: '${cat.name} spending jumped',
          body: 'Up $pct% vs last month — \$${prev.toStringAsFixed(0)} → \$${curr.toStringAsFixed(0)}.',
          tint: 'coral',
          categoryId: cat.id,
          icon: Icons.trending_up_rounded,
        ));
      }
      if (biggestDrop != null) {
        final (cat, curr, prev) = biggestDrop;
        final pct = ((prev - curr) / prev * 100).round();
        tips.add((
          headline: '${cat.name} spending is down',
          body: 'Down $pct% vs last month — \$${prev.toStringAsFixed(0)} → \$${curr.toStringAsFixed(0)}. Nice work.',
          tint: 'mint',
          categoryId: cat.id,
          icon: Icons.trending_down_rounded,
        ));
      }
    }

    // Income month-over-month — same idea as the category swings above, but
    // for total income.
    final prevIncome = prevRecord.income;
    if (prevIncome > 0) {
      final incomePct = ((income - prevIncome) / prevIncome * 100).round();
      if (income - prevIncome <= -prevIncome * 0.25) {
        tips.add((
          headline: 'Income is down this month',
          body: 'Down ${incomePct.abs()}% vs last month — \$${prevIncome.toStringAsFixed(0)} → \$${income.toStringAsFixed(0)}.',
          tint: 'coral',
          categoryId: null,
          icon: Icons.trending_down_rounded,
        ));
      } else if (income - prevIncome >= prevIncome * 0.25) {
        tips.add((
          headline: 'Income is up this month',
          body: 'Up $incomePct% vs last month — \$${prevIncome.toStringAsFixed(0)} → \$${income.toStringAsFixed(0)}. Nice.',
          tint: 'mint',
          categoryId: null,
          icon: Icons.trending_up_rounded,
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
          categoryId: null,
          icon: Icons.speed_rounded,
        ));
      } else if (projectedPct <= 70) {
        tips.add((
          headline: 'Comfortably under pace 🎉',
          body: 'Your spending projects to \$${projected.toStringAsFixed(0)} this month, '
              'only $projectedPct% of income — plenty of room to save.',
          tint: 'mint',
          categoryId: null,
          icon: Icons.savings_rounded,
        ));
      }
    }

    // Biggest single transaction this month — only worth calling out if it's
    // a meaningful chunk of the month's spending, not just the largest of a
    // handful of similar-sized purchases.
    final currentMonthExpenses = notifier.currentMonthCashflows.where((c) => c.isExpense).toList();
    if (currentMonthExpenses.isNotEmpty && expenses > 0) {
      final biggest = currentMonthExpenses.reduce((a, b) => a.amount.abs() > b.amount.abs() ? a : b);
      final amt = biggest.amount.abs();
      if (amt / expenses >= 0.15) {
        final cat = catNotifier.getCategoryById(biggest.categoryId);
        final daysAgo = today.difference(DateTime(biggest.date.year, biggest.date.month, biggest.date.day)).inDays;
        final whenLabel = daysAgo == 0 ? 'today' : daysAgo == 1 ? 'yesterday' : '$daysAgo days ago';
        tips.add((
          headline: 'Your biggest purchase this month',
          body: '\$${amt.toStringAsFixed(0)} on ${cat?.name ?? 'something'} $whenLabel '
              '— ${(amt / expenses * 100).round()}% of everything you\'ve spent this month.',
          tint: 'rose',
          categoryId: cat?.id,
          icon: cat == null ? Icons.receipt_long_rounded : null,
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
          categoryId: null,
          icon: Icons.savings_rounded,
        ));
      }
    }

    // No-spend days this month — a simple discipline signal once there's
    // enough of the month elapsed to make the count meaningful.
    if (daysElapsed >= 6) {
      final spentDays = currentMonthExpenses.map((c) => c.date.day).toSet().length;
      final noSpendDays = daysElapsed - spentDays;
      if (noSpendDays >= 3) {
        tips.add((
          headline: '$noSpendDays no-spend days this month',
          body: 'Out of $daysElapsed days so far, you kept spending at zero on $noSpendDays of them — that adds up.',
          tint: 'mint',
          categoryId: null,
          icon: Icons.event_available_rounded,
        ));
      }
    }

    // Frequent small purchases — a category with a lot of separate buys
    // this month, the "death by a thousand cuts" pattern that a single
    // biggest-category or over-budget tip wouldn't surface on its own.
    if (daysElapsed >= 10) {
      final txCounts = <String, int>{};
      for (final cf in currentMonthExpenses) {
        txCounts[cf.categoryId] = (txCounts[cf.categoryId] ?? 0) + 1;
      }
      final frequent = txCounts.entries.where((e) => e.value >= 6).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (frequent.isNotEmpty) {
        final cat = catNotifier.getCategoryById(frequent.first.key);
        final count = frequent.first.value;
        final total = spendByCat[frequent.first.key] ?? 0;
        if (cat != null) {
          tips.add((
            headline: '${cat.name}: $count purchases add up',
            body: '$count separate ${cat.name} purchases this month, totaling \$${total.toStringAsFixed(0)} '
                '— worth budgeting for as a whole instead of one at a time.',
            tint: 'sky',
            categoryId: cat.id,
            icon: Icons.repeat_rounded,
          ));
        }
      }
    }

    // Weekday spending pattern (same 8-week window as the rhythm chart).
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
        categoryId: null,
        icon: Icons.calendar_view_week_rounded,
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
          categoryId: null,
          icon: Icons.notifications_active_rounded,
        ));
      }
    }

    if (tips.isEmpty) {
      tips.add((
        headline: 'Track every dollar 💰',
        body: 'Logging your expenses daily gives you a clear picture of where your money is going.',
        tint: 'mint',
        categoryId: null,
        icon: Icons.auto_awesome_rounded,
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

    final last30DaysCashflows = notifier.last30DaysCashflows;
    final income = notifier.monthIncome;
    final expenses = notifier.monthExpenses;
    final balance = notifier.balance;

    // Current month's category totals — precomputed by DashboardNotifier
    // (see MonthlyRecord) instead of re-summing currentMonthCashflows here.
    final spendByCat = notifier.last6MonthlyRecords.last.spendByCategory;
    final maxCatSpend = spendByCat.values.fold(0.0, max);

    final coaches = _buildCoachTips(notifier, catNotifier, spendByCat, income, expenses);
    final coach = coaches[_coachIdx % coaches.length];

    // Recent transactions (last 6)
    final recent = notifier.last7DaysCashflows.take(6).toList();

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
              // ── Hero row: balance + income/expense + AI coach ────────────
              // Below `compact`, there isn't room for the balance card and
              // the income/expense+coach column to sit side by side without
              // cramming — stack them instead.
              mobile
                  ? Column(children: [
                      _BalanceCard(context, balance, income, expenses, last30DaysCashflows, () => _showEditBalanceDialog(context, notifier), mobile),
                      const SizedBox(height: 12),
                      _IncomeExpenseRow(context, income, expenses, mobile),
                      SizedBox(height: mobile ? 12 : 18),
                      _CoachCard(context, catNotifier, coach, () {
                        setState(() => _coachIdx = (_coachIdx + 1) % coaches.length);
                      }, mobile),
                    ])
                  : compact
                      ? Column(children: [
                          _BalanceCard(context, balance, income, expenses, last30DaysCashflows, () => _showEditBalanceDialog(context, notifier), mobile),
                          const SizedBox(height: 18),
                          _IncomeExpenseRow(context, income, expenses, mobile),
                          SizedBox(height: mobile ? 12 : 18),
                          _CoachCard(context, catNotifier, coach, () {
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
                            flex: 10,
                            // Fixed height matching the right column's own
                            // fixed total (income/spend row 90 + spacing 18
                            // + coach card 186 = 294) so the two columns
                            // always line up evenly. A literal height
                            // instead of IntrinsicHeight+stretch — see the
                            // note above on why that triggered a
                            // font-metrics overflow here. Keep this in sync
                            // if _IncomeExpenseRow or _CoachCard's fixed
                            // sizes ever change.
                            child: SizedBox(
                              height: 294,
                              child: _BalanceCard(context, balance, income, expenses, last30DaysCashflows, () => _showEditBalanceDialog(context, notifier), mobile),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 14,
                            child: Column(
                              children: [
                                _IncomeExpenseRow(context, income, expenses, mobile),
                                SizedBox(height: mobile ? 12 : 18),
                                _CoachCard(context, catNotifier, coach, () {
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
              // (6 items) is sized to roughly match the combined height of
              // the month summary + top-4 budget rings below it.
              compact
                  ? Column(
                      // stretch so _BudgetRingsCard (whose content doesn't
                      // otherwise force full width, unlike the others'
                      // Expanded rows / progress bar) matches its siblings'
                      // width instead of shrink-wrapping narrower.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RecentCard(context, recent, catNotifier, mobile),
                        SizedBox(height: mobile ? 12 : 18),
                        _MonthSummaryCard(context, income, expenses, mobile),
                        SizedBox(height: mobile ? 12 : 18),
                        _BudgetRingsCard(context, catNotifier, spendByCat, maxCatSpend, income, mobile),
                      ],
                    )
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
                              // stretch so _BudgetRingsCard matches
                              // _MonthSummaryCard's width instead of
                              // shrink-wrapping to its own (narrower)
                              // content — see the compact-branch comment.
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      _WeekdayRhythmCard(context, notifier, mobile, fillHeight: false),
                    ])
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _DonutCard(context, notifier, catNotifier, mobile)),
                          const SizedBox(width: 18),
                          Expanded(child: _WeekdayRhythmCard(context, notifier, mobile, fillHeight: true)),
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
  List<Cashflow> recentCashflows,
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
      // spaceBetween only has an effect when this card is height-constrained
      // (the desktop hero row pins it to 294 to match the right column) —
      // in mobile/compact contexts it sizes to content as before.
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        NetWorthTrendChart(
          cashflows: recentCashflows,
          currentBalance: balance,
          height: mobile ? 60 : 80,
        ),
      ],
    ),
  );
}

Widget _IncomeExpenseRow(BuildContext context, double income, double expenses, bool mobile) {
  final theme = Theme.of(context);
  // Fixed height (rather than left to Row+Expanded's own content-driven
  // sizing) because a Row's intrinsic-height computation for Expanded
  // children is only an approximation — it can diverge by a few px from
  // what real layout actually needs, and this Row can end up inside an
  // IntrinsicHeight ancestor (see hero row) where that gap shows up as an
  // overflow.
  return SizedBox(
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
  );
}

Widget _CoachCard(
  BuildContext context,
  CategoryNotifier catNotifier,
  CoachTip coach,
  VoidCallback onNext,
  bool mobile,
) {
  final theme = Theme.of(context);
  // Tips tied to a specific category (see CoachTip.categoryId) borrow that
  // category's own icon/color instead of a generic badge, so the card
  // visually matches the same category everywhere else in the app (donut
  // chart, budget rings, recent activity).
  final coachCategory = coach.categoryId != null ? catNotifier.getCategoryById(coach.categoryId!) : null;
  final Color bg, ink;
  final IconData badgeIcon;
  if (coachCategory != null) {
    ink = colorForCategoryKey(coachCategory.colorKey, theme.brightness);
    bg = ink.withOpacity(0.12);
    badgeIcon = iconForCategoryKey(coachCategory.icon);
  } else {
    (bg, ink) = _tintPair(theme, coach.tint);
    badgeIcon = coach.icon ?? Icons.auto_awesome_rounded;
  }

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
          // theme.bg (the opaque page background), not the tint's own `bg` —
          // that's a low-alpha wash in dark theme (by design, for card fills)
          // and made the icon glyph nearly invisible against the solid `ink`
          // circle behind it. theme.bg stays high-contrast against `ink` in
          // both themes since ink itself flips dark-muted/light-vivid.
          child: Icon(badgeIcon, color: theme.bg, size: 22),
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
        // Row of Expanded slots (not Wrap) so the top categories always sit
        // on one line, evenly splitting whatever width this card actually
        // has — including the narrow 10/24-flex column it shares with
        // "This month" above it, now that both stretch to the same width.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < topCats.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _buildRingItem(theme, topCats[i], spendByCat, income, mobile),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

Widget _buildRingItem(
  ThemeData theme,
  Category cat,
  Map<String, double> spendByCat,
  double income,
  bool mobile,
) {
  final spent = spendByCat[cat.id] ?? 0;
  final progress = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;
  final tintInk = colorForCategoryKey(cat.colorKey, theme.brightness);
  final tintBg = tintInk.withOpacity(0.12);

  return Column(
    children: [
      _Ring(
        value: progress,
        trackColor: tintBg,
        progressColor: tintInk,
        size: mobile ? 36 : 48,
        strokeWidth: 5,
        child: Icon(iconForCategoryKey(cat.icon), size: mobile ? 15 : 17, color: tintInk),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
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
            final tintInk = isIncome ? theme.tintMintInk : (cat != null ? colorForCategoryKey(cat.colorKey, theme.brightness) : theme.ink2);
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
                      child: Icon(
                        cat != null ? iconForCategoryKey(cat.icon) : Icons.category_rounded,
                        size: 18,
                        color: tintInk,
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
        const SizedBox(height: 28),
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
        Text('Spending by category', style: theme.sans(13, color: theme.ink2)),
        const SizedBox(height: 16),
        CategoryDonutChart(
          monthlyRecords: notifier.last6MonthlyRecords,
          categories: catNotifier.categories,
          stacked: mobile,
        ),
      ],
    ),
  );
}

Widget _WeekdayRhythmCard(BuildContext context, DashboardNotifier notifier, bool mobile, {required bool fillHeight}) {
  final theme = Theme.of(context);
  final chart = WeekdayRhythmChart(cashflows: notifier.cashflows);
  return _card(
    context: context,
    padding: EdgeInsets.all(mobile ? 18 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your spending rhythm', style: theme.serif(mobile ? 20 : 22)),
        const SizedBox(height: 2),
        Text('Average by day of week · last 8 weeks', style: theme.sans(13, color: theme.ink2)),
        if (fillHeight)
          // This card is stretched (via the IntrinsicHeight row it shares
          // with _DonutCard, desktop only) to match the donut card's taller
          // natural height, but the chart itself is a fixed 150px —
          // Expanded+Center soaks up the leftover space evenly above and
          // below it instead of leaving it all as dead space underneath.
          // Only safe here: in the compact/mobile stacked layout this card
          // has no imposed height, so Expanded would have unbounded height
          // to fill and Flutter would throw.
          Expanded(child: Center(child: chart))
        else ...[
          const SizedBox(height: 28),
          chart,
        ],
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
