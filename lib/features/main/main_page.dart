import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/responsive.dart';
import 'main_page_notifier.dart';
import 'mobile_navbar.dart';
import 'web_navbar.dart';
import '../cashflow/logic/cashflowNotifier.dart';
import '../cashflow/widgets/add_transaction_form.dart';
import '../categories/widgets/category_detail_dialog.dart';
// Feature pages
import '../dashboard/presentation/dashboard_page.dart';
import '../categories/presentation/categories_page.dart';
import '../cashflow/presentation/cashflow_page.dart';
import '../account/account_page.dart';

class MainPage extends StatelessWidget {
  final String userId;
  const MainPage({super.key, required this.userId});

  List<Widget> pages() => const [
    DashboardPage(),
    CashFlowPage(),
    CategoriesPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => MainPageNotifier(),
      child: Consumer<MainPageNotifier>(
        builder: (context, notifier, _) {
          final mobile = isMobile(context);
          final idx = notifier.selectedIndex;

          void showAddTransaction() {
            final cashflowNotifier =
                Provider.of<CashflowNotifier>(context, listen: false);
            // Bug fix: this always defaulted to today, ignoring whatever date
            // was selected in the CashFlowPage calendar — CashFlowPage's own
            // inline add-button already reads lastSelectedDate correctly
            // (see cashflow_page.dart), this FAB (mobile bottom-nav only;
            // web has no FAB, see web_navbar.dart) just never did.
            final initialDate = cashflowNotifier.lastSelectedDate ?? DateTime.now();
            showDialog(
              context: context,
              builder: (_) => ChangeNotifierProvider.value(
                value: cashflowNotifier,
                child: AddTransactionForm(initialDate: initialDate),
              ),
            );
          }

          void onFabTap() {
            if (idx == 0 || idx == 1) {
              showAddTransaction();
            } else if (idx == 2) {
              CategoryDetailDialog.showAddCategoryDialog(context);
            }
          }

          if (mobile) {
            return Scaffold(
              backgroundColor: theme.bg,
              body: pages()[idx],
              bottomNavigationBar: MobileNavbar(
                notifier: notifier,
                onFabTap: onFabTap,
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: theme.bg,
              body: Row(
                children: [
                  WebNavbar(notifier: notifier),
                  Expanded(child: pages()[idx]),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
