import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../logic/categoryNotifier.dart';
import '../../dashboard/logic/dashboardNotifier.dart';
import '../../cashflow/data/models/cashflow.dart';
import '../data/models/category.dart';
import '../widgets/category_detail_dialog.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/presentation/dashboard_page.dart' show catEmoji;

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
    final totalIncome = dashNotifier.monthIncome;

    // Overall % = expenses / income
    final overall = totalIncome > 0 ? (totalExpenses / totalIncome).clamp(0.0, 1.2) : 0.0;
    final remaining = totalIncome - totalExpenses;

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
            _card(
              context: context,
              padding: EdgeInsets.all(mobile ? 20 : 28),
              child: mobile
                  ? Column(
                      children: [
                        _OverallRing(
                          context: context,
                          overall: overall,
                          totalSpent: totalExpenses,
                          totalIncome: totalIncome,
                          mobile: mobile,
                        ),
                        const SizedBox(height: 16),
                        _OverallStats(
                          context: context,
                          expenses: expenses,
                          spendByCat: spendByCat,
                          remaining: remaining,
                          mobile: mobile,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _OverallRing(
                          context: context,
                          overall: overall,
                          totalSpent: totalExpenses,
                          totalIncome: totalIncome,
                          mobile: mobile,
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: _OverallStats(
                            context: context,
                            expenses: expenses,
                            spendByCat: spendByCat,
                            remaining: remaining,
                            mobile: mobile,
                          ),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: mobile ? 14 : 18),

            // ── Tabs + Add button ───────────────────────────────────────
            Row(
              children: [
                _TabPill(
                  label: '📊 Expense',
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: '💰 Income',
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => CategoryDetailDialog.showAddCategoryDialog(context),
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
                      Text(_tab == 0 ? '🗂️' : '💰',
                          style: const TextStyle(fontSize: 40)),
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
                        final pct = maxSpend > 0 ? spent / maxSpend : 0.0;
                        return SizedBox(
                          width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                          child: _CategoryCard(
                            context: context,
                            category: cat,
                            spent: spent,
                            progress: pct,
                            isExpense: _tab == 0,
                          ),
                        );
                      }),
                      // Add category card
                      SizedBox(
                        width: (constraints.maxWidth - (cols - 1) * 14) / cols,
                        child: _AddCategoryCard(context: context),
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
  final double overall, totalSpent, totalIncome;
  final bool mobile;

  const _OverallRing({
    required this.context,
    required this.overall,
    required this.totalSpent,
    required this.totalIncome,
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
  final bool mobile;

  const _OverallStats({
    required this.context,
    required this.expenses,
    required this.spendByCat,
    required this.remaining,
    required this.mobile,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final onTrack = expenses.where((c) {
      final spent = spendByCat[c.id] ?? 0;
      final maxSpend = spendByCat.values.fold(0.0, (a, b) => a > b ? a : b);
      return maxSpend > 0 ? spent / maxSpend < 0.8 : true;
    }).length;

    return Column(
      crossAxisAlignment: mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'May overall',
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
                text: ' of income',
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
          ],
        ),
      ],
    );
  }
}

// ─── Category budget card ─────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final BuildContext context;
  final Category category;
  final double spent;
  final double progress;
  final bool isExpense;

  const _CategoryCard({
    required this.context,
    required this.category,
    required this.spent,
    required this.progress,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final tintInk = _nearestTintInk(theme, category.color);
    final tintBg = tintInk.withOpacity(0.1);

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
                  child: Center(
                    child: Text(catEmoji(category.name),
                        style: const TextStyle(fontSize: 22)),
                  ),
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
                Text(
                  '\$${spent.toStringAsFixed(0)}',
                  style: GoogleFonts.instrumentSerif(
                      fontSize: 24, color: theme.ink, letterSpacing: -0.3),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 12, fontWeight: FontWeight.w600, color: theme.ink2,
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
                valueColor: AlwaysStoppedAnimation(tintInk),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.products.where((p) => !p.isDeleted).isEmpty
                  ? 'No products'
                  : '${category.products.where((p) => !p.isDeleted).length} products',
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
  const _AddCategoryCard({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return GestureDetector(
      onTap: () => CategoryDetailDialog.showAddCategoryDialog(context),
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
            Text('New category', style: theme.sans(13, color: theme.ink2, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _TabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        child: Text(label,
            style: theme.sans(13, weight: FontWeight.w500,
                color: active ? theme.surface : theme.ink2)),
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

// ─── Color helper ─────────────────────────────────────────────────────────────
Color _nearestTintInk(ThemeData theme, Color cat) {
  final opts = [
    theme.tintMintInk, theme.tintCoralInk, theme.tintButterInk,
    theme.tintLavenderInk, theme.tintSkyInk, theme.tintRoseInk,
  ];
  double best = double.infinity;
  Color result = theme.tintMintInk;
  for (final c in opts) {
    final dr = (cat.red - c.red).toDouble();
    final dg = (cat.green - c.green).toDouble();
    final db = (cat.blue - c.blue).toDouble();
    final d = dr * dr + dg * dg + db * db;
    if (d < best) { best = d; result = c; }
  }
  return result;
}
