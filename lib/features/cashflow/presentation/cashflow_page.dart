import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../logic/cashflowNotifier.dart';
import '../../categories/logic/categoryNotifier.dart';
import '../../dashboard/logic/dashboardNotifier.dart';
import '../data/models/cashflow.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/transaction_edit_dialog.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/presentation/dashboard_page.dart' show catEmoji;

// ─── Card helper (same pattern as Dashboard) ─────────────────────────────────
Widget _card({
  required BuildContext context,
  required Widget child,
  Color? bg,
  EdgeInsets padding = const EdgeInsets.all(20),
}) {
  final theme = Theme.of(context);
  return Container(
    decoration: bg != null ? theme.tintCardDecoration(bg) : theme.cardDecoration,
    padding: padding,
    child: child,
  );
}

// ─── Filter pills ─────────────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = active ? (activeColor?.withOpacity(0.15) ?? theme.accentSoftColor) : Colors.transparent;
    final ink = active ? (activeColor ?? theme.accentInkSoftColor) : theme.ink2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: active ? Colors.transparent : theme.border,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: theme.sans(12.5, color: ink)),
      ),
    );
  }
}

// ─── Cashflow Page ────────────────────────────────────────────────────────────
class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage> {
  DateTime _selectedDate = DateTime.now();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<CashflowNotifier>();
      final last = notifier.lastSelectedDate ?? DateTime.now();
      setState(() => _selectedDate = last);
      notifier.loadCashflowsForDate(_selectedDate);
    });
  }

  Future<void> _pickDate(CashflowNotifier notifier) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: Theme.of(ctx).accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      notifier.setLastSelectedDate(picked);
      notifier.loadCashflowsForDate(picked);
    }
  }

  List<Cashflow> _filtered(List<Cashflow> txs) {
    switch (_filter) {
      case 'income':  return txs.where((t) => t.isIncome).toList();
      case 'expense': return txs.where((t) => t.isExpense).toList();
      default:        return txs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = isMobile(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Consumer3<CashflowNotifier, CategoryNotifier, DashboardNotifier>(
        builder: (ctx, cashflowNotifier, categoryNotifier, dashNotifier, _) {
          final allTxs = cashflowNotifier.cashflows;
          final filtered = _filtered(allTxs);
          final income = dashNotifier.monthIncome;
          final expenses = dashNotifier.monthExpenses;

          final dayIncome = allTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
          final dayExpenses = allTxs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount.abs());

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 28,
              mobile ? 16 : 28,
              mobile ? 16 : 28,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ─────────────────────────────────────────
                Text('Cashflow', style: theme.serif(mobile ? 28 : 36)),
                const SizedBox(height: 4),
                Text('Every dollar, in and out',
                    style: theme.sans(13.5, color: theme.ink2)),

                SizedBox(height: mobile ? 16 : 20),

                // ── Summary strip ───────────────────────────────────────
                _SummaryStrip(
                  context: ctx,
                  dayIncome: dayIncome,
                  dayExpenses: dayExpenses,
                  monthIncome: income,
                  monthExpenses: expenses,
                  mobile: mobile,
                ),

                SizedBox(height: mobile ? 14 : 18),

                // ── Date picker + filters + add ─────────────────────────
                Row(
                  children: [
                    // Date chip
                    GestureDetector(
                      onTap: () => _pickDate(cashflowNotifier),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.accentSoftColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 14, color: theme.accentInkSoftColor),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_selectedDate),
                              style: theme.sans(13, color: theme.accentInkSoftColor,
                                  weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Filter pills
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterPill(label: 'All · ${allTxs.length}', active: _filter == 'all',
                                onTap: () => setState(() => _filter = 'all')),
                            const SizedBox(width: 6),
                            _FilterPill(label: 'Income', active: _filter == 'income',
                                activeColor: theme.tintMintInk,
                                onTap: () => setState(() => _filter = 'income')),
                            const SizedBox(width: 6),
                            _FilterPill(label: 'Expense', active: _filter == 'expense',
                                activeColor: theme.tintCoralInk,
                                onTap: () => setState(() => _filter = 'expense')),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Add button
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: ctx,
                          builder: (_) => ChangeNotifierProvider.value(
                            value: cashflowNotifier,
                            child: AddTransactionForm(initialDate: _selectedDate),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: theme.accentInkColor),
                            const SizedBox(width: 4),
                            Text('Add', style: theme.sans(14,
                                color: theme.accentInkColor,
                                weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: mobile ? 14 : 18),

                // ── Transaction list + side rail ────────────────────────
                mobile
                    ? _TransactionList(
                        context: ctx,
                        transactions: filtered,
                        categoryNotifier: categoryNotifier,
                        mobile: mobile,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 16,
                            child: _TransactionList(
                              context: ctx,
                              transactions: filtered,
                              categoryNotifier: categoryNotifier,
                              mobile: mobile,
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 260,
                            child: _SideRail(
                              context: ctx,
                              categoryNotifier: categoryNotifier,
                              allTxs: allTxs,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

// ─── Summary strip ────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final BuildContext context;
  final double dayIncome, dayExpenses, monthIncome, monthExpenses;
  final bool mobile;

  const _SummaryStrip({
    required this.context,
    required this.dayIncome,
    required this.dayExpenses,
    required this.monthIncome,
    required this.monthExpenses,
    required this.mobile,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final items = mobile
        ? [
            (label: 'Day in',  value: '+\$${dayIncome.toStringAsFixed(0)}',  tint: theme.tintMintBg,  ink: theme.tintMintInk),
            (label: 'Day out', value: '-\$${dayExpenses.toStringAsFixed(0)}', tint: theme.tintCoralBg, ink: theme.tintCoralInk),
          ]
        : [
            (label: 'Day income',  value: '+\$${dayIncome.toStringAsFixed(2)}',  tint: theme.tintMintBg,     ink: theme.tintMintInk),
            (label: 'Day expenses',value: '-\$${dayExpenses.toStringAsFixed(2)}', tint: theme.tintCoralBg,   ink: theme.tintCoralInk),
            (label: 'Month income',value: '+\$${monthIncome.toStringAsFixed(0)}', tint: theme.tintSkyBg,     ink: theme.tintSkyInk),
            (label: 'Month spent', value: '-\$${monthExpenses.toStringAsFixed(0)}',tint: theme.tintLavenderBg,ink: theme.tintLavenderInk),
          ];

    return Row(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
            child: _card(
              context: ctx,
              bg: item.tint,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.instrumentSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: item.ink, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.instrumentSerif(
                        fontSize: mobile ? 22 : 26,
                        color: item.ink,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Transaction list ─────────────────────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  final BuildContext context;
  final List<Cashflow> transactions;
  final CategoryNotifier categoryNotifier;
  final bool mobile;

  const _TransactionList({
    required this.context,
    required this.transactions,
    required this.categoryNotifier,
    required this.mobile,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);

    if (transactions.isEmpty) {
      return _card(
        context: ctx,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Text('🧾', style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('No transactions yet',
                  style: theme.serif(20, color: theme.ink2)),
              const SizedBox(height: 4),
              Text('Tap Add to record one.',
                  style: theme.sans(13.5, color: theme.ink2)),
            ],
          ),
        ),
      );
    }

    return _card(
      context: ctx,
      padding: EdgeInsets.all(mobile ? 16 : 20),
      child: Column(
        children: transactions.asMap().entries.map((entry) {
          final i = entry.key;
          final tx = entry.value;
          final cat = categoryNotifier.getCategoryById(tx.categoryId);
          final catName = cat?.name ?? 'Unknown';
          final isIncome = tx.isIncome;
          final tintInk = isIncome
              ? theme.tintMintInk
              : (cat != null ? _nearestTintInk(theme, cat.color) : theme.ink2);
          final tintBg = tintInk.withOpacity(0.12);

          return GestureDetector(
            onTap: () => showDialog(
              context: ctx,
              builder: (_) => TransactionEditDialog(cashflow: tx),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: i > 0 ? Border(top: BorderSide(color: theme.border)) : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: tintBg, borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(catEmoji(catName),
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catName, style: theme.sans(14, weight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                          style: theme.sans(12, color: theme.ink2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isIncome
                        ? '+\$${tx.amount.toStringAsFixed(2)}'
                        : '-\$${tx.amount.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isIncome ? theme.tintMintInk : theme.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Side rail (desktop only) ─────────────────────────────────────────────────
class _SideRail extends StatelessWidget {
  final BuildContext context;
  final CategoryNotifier categoryNotifier;
  final List<Cashflow> allTxs;

  const _SideRail({
    required this.context,
    required this.categoryNotifier,
    required this.allTxs,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);

    // Build spending per category
    final spendByCat = <String, double>{};
    for (final tx in allTxs) {
      if (tx.isExpense) {
        spendByCat[tx.categoryId] = (spendByCat[tx.categoryId] ?? 0) + tx.amount.abs();
      }
    }
    final maxSpend = spendByCat.values.fold(0.0, (a, b) => a > b ? a : b);

    final sorted = spendByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          context: ctx,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By category', style: theme.serif(20)),
              const SizedBox(height: 14),
              if (sorted.isEmpty)
                Text('No expenses today',
                    style: theme.sans(13.5, color: theme.ink2))
              else
                ...sorted.take(6).map((e) {
                  final cat = categoryNotifier.getCategoryById(e.key);
                  final name = cat?.name ?? 'Unknown';
                  final pct = maxSpend > 0 ? e.value / maxSpend : 0.0;
                  final tintInk = cat != null
                      ? _nearestTintInk(theme, cat.color)
                      : theme.ink2;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${catEmoji(name)} $name',
                                style: theme.sans(12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '\$${e.value.toStringAsFixed(0)}',
                              style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.5, fontWeight: FontWeight.w600,
                                  color: theme.ink,
                                  fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: theme.surface2,
                            valueColor: AlwaysStoppedAnimation(tintInk),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Color _nearestTintInk(ThemeData theme, Color cat) {
  final opts = [
    theme.tintMintInk, theme.tintCoralInk, theme.tintButterInk,
    theme.tintLavenderInk, theme.tintSkyInk, theme.tintRoseInk,
  ];
  double best = double.infinity;
  Color result = theme.tintMintInk;
  for (final c in opts) {
    final d = _dist(cat, c);
    if (d < best) { best = d; result = c; }
  }
  return result;
}

double _dist(Color a, Color b) {
  final dr = (a.red - b.red).toDouble();
  final dg = (a.green - b.green).toDouble();
  final db = (a.blue - b.blue).toDouble();
  return dr * dr + dg * dg + db * db;
}
