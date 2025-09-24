import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive.dart';
import 'main_page_notifier.dart';   // ✅ fixed (no extra "main_page" folder)
import 'mobile_navbar.dart';
import 'web_navbar.dart';



// Import your feature pages:
import '../dashboard/dashboard_page.dart';
import '../categories/categories_page.dart';
import '../cashflow/cashflow_page.dart';
import '../account/account_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const List<Widget> pages = [
    DashboardPage(),
    CategoriesPage(),
    CashFlowPage(),
    AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainPageNotifier(),
      child: Consumer<MainPageNotifier>(
        builder: (context, notifier, _) {
          final mobile = isMobile(context);
          return Scaffold(
            // On web: show sidebar + content. On mobile: content only.
            body: mobile
                ? pages[notifier.selectedIndex]
                : Row(
                    children: [
                      WebNavbar(notifier: notifier),
                      Expanded(child: pages[notifier.selectedIndex]),
                    ],
                  ),

            // Mobile bottom bar
            bottomNavigationBar: mobile ? MobileNavbar(notifier: notifier) : null,

            // Mobile centered FAB
            floatingActionButton: mobile
                ? FloatingActionButton(
                    onPressed: () {
                      // your action
                    },
                    backgroundColor: Colors.blue,
                    shape: const CircleBorder(), // 👉 ensures perfect circle
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          );
        },
      ),
    );
  }
}
