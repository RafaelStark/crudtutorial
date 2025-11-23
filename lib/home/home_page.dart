import 'package:flutter/material.dart';

import '../features/dashboard/pages/dashboard_page.dart';
import '../features/clientes/pages/clientes_page.dart';
import '../features/representadas/pages/representadas_page.dart';
import '../features/pedidos/pages/pedidos_page.dart';
import '../features/transportadoras/pages/transportadoras_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),       // Página inicial
    ClientesPage(),
    //FornecedoresPage(),
    //PedidosPage(),
    //TransportadorasPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ======================
          // MENU LATERAL MODERNO
          // ======================
          Container(
            width: 90,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4)
                )
              ],
              // blur style (glassmorphism)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: NavigationRail(
                backgroundColor: Colors.white.withOpacity(0.3),
                extended: false,
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorColor: Colors.blue.shade100,
                groupAlignment: -1.0,
                useIndicator: true,

                selectedIconTheme: const IconThemeData(
                  size: 32,
                  color: Colors.blue,
                ),
                unselectedIconTheme: IconThemeData(
                  size: 28,
                  color: Colors.grey.shade700,
                ),

                selectedLabelTextStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                unselectedLabelTextStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),

                onDestinationSelected: (i) {
                  setState(() => selectedIndex = i);
                },

                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text("Dashboard"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text("Clientes"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.factory_outlined),
                    selectedIcon: Icon(Icons.factory),
                    label: Text("Fornec."),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.shopping_bag_outlined),
                    selectedIcon: Icon(Icons.shopping_bag),
                    label: Text("Pedidos"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    selectedIcon: Icon(Icons.local_shipping),
                    label: Text("Transp."),
                  ),
                ],
              ),
            ),
          ),

          // ======================
          // ÁREA PRINCIPAL
          // ======================
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

}
