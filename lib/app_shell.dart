import 'package:flutter/material.dart';

import 'features/dashboard/pages/dashboard_page.dart';
import 'features/clientes/pages/clientes_page.dart';
import 'features/transportadoras/pages/transportadoras_page.dart';

import 'core/widgets/side_menu.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int pageIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    ClientesPage(),
    Placeholder(), // fornecedores
    Placeholder(), // pedidos
    TransportadorasPage(), // transportadoras
  ];

  void onMenuSelect(int index) {
    setState(() => pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selectedIndex: pageIndex,
            onSelect: onMenuSelect,
          ),

          // Conteúdo
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: pages[pageIndex],
            ),
          ),
        ],
      ),
    );
  }
}
