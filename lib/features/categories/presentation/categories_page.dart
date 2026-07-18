import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../../dashboard/logic/dashboardNotifier.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../data/models/category.dart';
import '../category_style_options.dart';
import '../widgets/category_detail_dialog.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';

// ─── Card helper ──────────────────────────────────────────────────────────────
Widget _card({
  required BuildContext context,
  required Widget child,
  Color? bg,
  EdgeInsets padding = const EdgeInsets.all(20),
  bool hover = false,
}) {
  final theme = Theme.of(context);
  return Container(
    decoration: bg != null ? theme.tintCardDecoration(bg) : theme.cardDecoration,
    padding: padding,
    child: child,
  );
}

// ─── Progress ring (shared with dashboard) ────────────────────────────────────
class _Ring extends StatelessWidget {
  final double value;
  final Color trackColor;
  final Color progressColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const _Ring({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    this.size = 120,
    this.strokeWidth = 12,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: value.clamp(0.0, 1.0),
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
  const _RingPainter({required this.progress, required this.trackColor,
      required this.progressColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    if (progress > 0) {
      canvas.drawArc(rect, -3.14159 / 2, 2 * 3.14159 * progress, false,
          Paint()..color = progressColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}

// ─── Categories Page ──────────────────────────────────────────────────────────
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  int _tab = 0; // 0=Expense, 1=Income

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryNotifier>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = isMobile(context);
    final catNotifier = context.watch<CategoryNotifier>();
    final dashNotifier = context.watch<DashboardNotifier>();

    final expenses = catNotifier.expenseCategories;
    final income = catNotifier.incomeCategories;
    final displayed = _tab == 0 ? expenses : income;

    // Compute spending per category from current month cashflows
    final spendByCat = <String, double>{};
    for (final cf in dashNotifier.currentMonthCashflows) {
      if (cf.isExpense) {
        spendByCat[cf.categoryId] =
            (spendByCat[cf.categoryId] ?? 0) + cf.amount.abs();
      }
    }
    final totalExpenses = dashNotifier.monthExpenses;
    final monthlyGoal = dashNotifier.monthlyGoal;

    // Overall % = expenses / chosen budget goal (was expenses/income)
    final overall = (monthlyGoal != null && monthlyGoal > 0)
        ? (totalExpenses / monthlyGoal).clamp(0.0, 1.2)
        : 0.0;
    final remaining = (monthlyGoal ?? 0) - totalExpenses;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 16 : 28,
          mobile ? 16 : 28,
          mobile ? 16 : 28,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────────────────
            Text('Budgets & goals', style: theme.serif(mobile ? 28 : 36)),
            const SizedBox(height: 4),
            Text('Where your money lives', style: theme.sans(13.5, color: theme.ink2)),

            SizedBox(height: mobile ? 16 : 20),

            // ── Overall progress card ────────────────────────────────────
            // Wrapped in a width:double.infinity SizedBox because _card()'s
            // Container shrink-wraps to its child's natural width — on
            // desktop the Row below has an Expanded child that forces full
            // width on its own, but the mobile branch is a plain Column
            // with no such child, so without this the whole card floats at
            // less than full width instead of matching the cards below it.
            SizedBox(
              width: double.infinity,
              child: _card(
                context: context,
                padding: EdgeInsets.all(mobile ? 20 : 28),
                child: monthlyGoal == null
                    ? _NoGoalPrompt(
                        mobile: mobile,
                        onSetGoal: () => _showEditGoalDialog(context, dashNotifier),
                      )
                    : mobile
                        ? Column(
                            children: [
                              _OverallRing(
                                context: context,
                                overall: overall,
                                totalSpent: totalExpenses,
                                monthlyGoal: monthlyGoal,
                                mobile: mobile,
                              ),
                              const SizedBox(height: 16),
                              _OverallStats(
                                context: context,
                                expenses: expenses,
                                spendByCat: spendByCat,
                                remaining: remaining,
                                monthlyGoal: monthlyGoal,
                                mobile: mobile,
                                onEditGoal: () => _showEditGoalDialog(context, dashNotifier),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              _OverallRing(
                                context: context,
                                overall: overall,
                                totalSpent: totalExpenses,
                                monthlyGoal: monthlyGoal,
                                mobile: mobile,
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: _OverallStats(
                                  context: context,
                                  expenses: expenses,
                                  spendByCat: spendByCat,
                                  remaining: remaining,
                                  monthlyGoal: monthlyGoal,
                                  mobile: mobile,
                                  onEditGoal: () => _showEditGoalDialog(context, dashNotifier),
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            SizedBox(height: mobile ? 14 : 18),

            // ── Tabs + Add button ───────────────────────────────────────
            // The tab pills scroll horizontally inside their own Expanded
            // instead of relying on a Spacer — at compact widths (600-900px,
            // see Breakpoints.compact) the pills + "New category" button
            // don't fit on one line without this, same overflow class fixed
            // on the dashboard/cashflow/account pages.
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TabPill(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Expense',
                          active: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                        const SizedBox(width: 8),
                        _TabPill(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Income',
                          active: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => CategoryDetailDialog.showAddCategoryDialog(
                    context,
                    initialType: _tab == 0 ? CategoryType.expense : CategoryType.income,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _tab == 0 ? Colors.transparent : theme.accentColor,
                      border: _tab == 0 ? Border.all(color: theme.border) : null,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 15,
                            color: _tab == 0 ? theme.ink2 : theme.accentInkColor),
                        const SizedBox(width: 4),
                        Text(
                          _tab == 0 ? 'New category' : 'New income',
                          style: theme.sans(13, weight: FontWeight.w600,
                              color: _tab == 0 ? theme.ink2 : theme.accentInkColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: mobile ? 14 : 16),

            // ── Category grid ───────────────────────────────────────────
            if (displayed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(_tab == 0 ? Icons.category_rounded : Icons.payments_rounded,
                          size: 40, color: theme.ink3),
                      const SizedBox(height: 12),
                      Text('No categories yet',
                          style: theme.serif(20, color: theme.ink2)),
                      const SizedBox(height: 4),
                      Text('Tap "New category" to add one.',
                          style: theme.sans(13.5, color: theme.ink2)),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final cols = mobile ? 2 : (constraints.maxWidth / 280).floor().clamp(2, 4);
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      ...displayed.map((cat) {
                        final spent = spendByCat[cat.id] ?? 0;
                        final maxSpend = spendByCat.values.fold(0.0, (a, b) => a > b ? a : b);
                        return SizedBox(
                          width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                          child: _CategoryCard(
                            context: context,
                            category: cat,
                            spent: spent,
                            maxCategorySpend: maxSpend,
                            isExpense: _tab == 0,
                          ),
                        );
                      }),
                      // Add category card
                      SizedBox(
                        width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                        child: _AddCategoryCard(context: context, isExpense: _tab == 0),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Overall progress ring ────────────────────────────────────────────────────
class _OverallRing extends StatelessWidget {
  final BuildContext context;
  final double overall, totalSpent, monthlyGoal;
  final bool mobile;

  const _OverallRing({
    required this.context,
    required this.overall,
    required this.totalSpent,
    required this.monthlyGoal,
    required this.mobile,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final over = overall > 1;
    return _Ring(
      value: overall,
      trackColor: (over ? theme.tintCoralInk : theme.tintMintInk).withOpacity(0.15),
      progressColor: over ? theme.tintCoralInk : theme.tintMintInk,
      size: mobile ? 120 : 140,
      strokeWidth: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(overall * 100).round()}%',
            style: GoogleFonts.instrumentSerif(
              fontSize: mobile ? 28 : 32,
              color: theme.ink,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'spent',
            style: GoogleFonts.instrumentSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: theme.ink2,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallStats extends StatelessWidget {
  final BuildContext context;
  final List<Category> expenses;
  final Map<String, double> spendByCat;
  final double remaining;
  final double monthlyGoal;
  final bool mobile;
  final VoidCallback onEditGoal;

  const _OverallStats({
    required this.context,
    required this.expenses,
    required this.spendByCat,
    required this.remaining,
    required this.monthlyGoal,
    required this.mobile,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    // "On track" now means "has its own goal, and is within it" — categories
    // without a goal set aren't counted either way.
    final onTrack = expenses.where((c) {
      final goal = c.monthlyGoal;
      if (goal == null || goal <= 0) return false;
      final spent = spendByCat[c.id] ?? 0;
      return spent <= goal;
    }).length;

    return Column(
      crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${DateFormat.MMMM().format(DateTime.now())} overall',
          style: GoogleFonts.instrumentSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: theme.ink2,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '\$${spendByCat.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}',
                style: theme.serif(mobile ? 32 : 42),
              ),
              TextSpan(
                text: ' of \$${monthlyGoal.toStringAsFixed(0)} goal',
                style: theme.serif(mobile ? 18 : 22, color: theme.ink3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _Tag(bg: theme.tintMintBg, ink: theme.tintMintInk,
                label: '$onTrack on track'),
            _Tag(bg: theme.tintLavenderBg, ink: theme.tintLavenderInk,
                label: '\$${remaining.abs().toStringAsFixed(0)} ${remaining >= 0 ? "remaining" : "over"}'),
            GestureDetector(
              onTap: onEditGoal,
              child: _Tag(bg: theme.surface2, ink: theme.ink2, label: 'Edit goal'),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoGoalPrompt extends StatelessWidget {
  final bool mobile;
  final VoidCallback onSetGoal;

  const _NoGoalPrompt({required this.mobile, required this.onSetGoal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.flag_rounded, size: 32, color: theme.ink3),
        const SizedBox(height: 10),
        Text('No monthly budget goal set', style: theme.serif(mobile ? 18 : 20)),
        const SizedBox(height: 4),
        Text(
          'Set a target and track spending against it all month.',
          style: theme.sans(13, color: theme.ink2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        ElevatedButton(onPressed: onSetGoal, child: const Text('Set budget goal')),
      ],
    );
  }
}

void _showEditGoalDialog(BuildContext context, DashboardNotifier notifier) {
  final ctrl = TextEditingController(
    text: notifier.monthlyGoal != null ? notifier.monthlyGoal!.toStringAsFixed(0) : '',
  );
  showDialog(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: Text('Monthly budget goal', style: theme.serif(22)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Total budget for the month'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          if (notifier.monthlyGoal != null)
            TextButton(
              onPressed: () {
                notifier.updateMonthlyGoal(null);
                Navigator.pop(ctx);
              },
              child: Text('Clear', style: theme.sans(14, weight: FontWeight.w600, color: theme.tintCoralInk)),
            ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null) notifier.updateMonthlyGoal(v);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

// ─── Category budget card ─────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final BuildContext context;
  final Category category;
  final double spent;
  final double maxCategorySpend;
  final bool isExpense;

  const _CategoryCard({
    required this.context,
    required this.category,
    required this.spent,
    required this.maxCategorySpend,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    // colorForCategoryKey resolves the light- or dark-theme variant of the
    // category's curated color, so it always reads correctly in both themes
    // instead of the old single-fixed-Color approach.
    final tintInk = colorForCategoryKey(category.colorKey, theme.brightness);
    final tintBg = tintInk.withOpacity(0.1);
    final goal = category.monthlyGoal;
    final hasGoal = goal != null && goal > 0;
    final progress = hasGoal
        ? spent / goal
        : (maxCategorySpend > 0 ? spent / maxCategorySpend : 0.0);
    final over = hasGoal && progress > 1;
    final productCount = category.visibleProducts.length;
    final productLabel = productCount == 0 ? 'No products' : '$productCount products';

    return GestureDetector(
      onTap: () => CategoryDetailDialog.showCategoryDetailDialog(context, category),
      child: Container(
        decoration: theme.cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: tintBg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(iconForCategoryKey(category.icon), color: tintInk, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: theme.sans(14, weight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(isExpense ? 'Expense' : 'Income',
                          style: theme.sans(11.5, color: theme.ink2)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.ink3, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '\$${spent.toStringAsFixed(0)}',
                        style: GoogleFonts.instrumentSerif(
                            fontSize: 24, color: theme.ink, letterSpacing: -0.3),
                      ),
                      if (hasGoal)
                        TextSpan(
                          text: ' / \$${goal.toStringAsFixed(0)}',
                          style: GoogleFonts.instrumentSerif(fontSize: 14, color: theme.ink3),
                        ),
                    ],
                  ),
                ),
                if (hasGoal || maxCategorySpend > 0)
                  Text(
                    '${(progress * 100).round()}%',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: over ? theme.tintCoralInk : theme.ink2,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: tintBg,
                valueColor: AlwaysStoppedAnimation(over ? theme.tintCoralInk : tintInk),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasGoal ? productLabel : '$productLabel · no goal set',
              style: theme.sans(11.5, color: theme.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add category card ────────────────────────────────────────────────────────
class _AddCategoryCard extends StatelessWidget {
  final BuildContext context;
  final bool isExpense;
  const _AddCategoryCard({required this.context, required this.isExpense});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return GestureDetector(
      onTap: () => CategoryDetailDialog.showAddCategoryDialog(
        context,
        initialType: isExpense ? CategoryType.expense : CategoryType.income,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: theme.surface2, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.add_rounded, size: 22, color: theme.ink2),
            ),
            const SizedBox(height: 8),
            Text(isExpense ? 'New category' : 'New income', style: theme.sans(13, color: theme.ink2, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _TabPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? theme.surface : theme.ink2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? theme.ink : Colors.transparent,
          border: Border.all(color: active ? Colors.transparent : theme.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: theme.sans(13, weight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final Color bg, ink;
  final String label;
  const _Tag({required this.bg, required this.ink, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: theme.sans(11.5, color: ink)),
    );
  }
}

