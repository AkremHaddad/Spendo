import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive.dart';
import 'main_page_notifier.dart';
import 'mobile_navbar.dart';
import 'web_navbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Feature pages
import '../dashboard/presentation/dashboard_page.dart';
import '../categories/presentation/categories_page.dart';
import '../cashflow/presentation/cashflow_page.dart';
import '../account/account_page.dart';

class MainPage extends StatelessWidget {
  final String userId; // user ID from AuthNotifier
  const MainPage({super.key, required this.userId});

  /// Pages list — CashFlowPage directly consumes root-level provider
  List<Widget> pages() => const [
        CashFlowPage(),
        CategoriesPage(),
        DashboardPage(),
        AccountPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MainPageNotifier(),
      child: Consumer<MainPageNotifier>(
        builder: (context, notifier, _) {
          final mobile = isMobile(context);

          if (mobile) {
            return Scaffold(
              body: Column(
                children: [
                  // Top SVG section
                  SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/appbar.svg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        const Center(
                          child: Text(
                            "Hello World",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Page content
                  Expanded(
                    child: pages()[notifier.selectedIndex],
                  ),
                ],
              ),
              bottomNavigationBar: MobileNavbar(notifier: notifier),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
                backgroundColor: Theme.of(context).primaryColor,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
            );
          } else {
            // Desktop / Web layout
            return Scaffold(
              body: Row(
                children: [
                  WebNavbar(notifier: notifier),
                  Expanded(child: pages()[notifier.selectedIndex]),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
