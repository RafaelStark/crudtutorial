import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          // Avatar + nome empresa
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue,
            child: Text(
              "R A", // R A Representações
              style: TextStyle(fontSize: 28, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "R A Representações",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Itens do menu
          Expanded(
            child: ListView(
              children: [
                _menuItem(
                  index: 0,
                  icon: Icons.dashboard,
                  label: "Dashboard",
                ),
                _menuItem(
                  index: 1,
                  icon: Icons.people,
                  label: "Clientes",
                ),
                _menuItem(
                  index: 2,
                  icon: Icons.storefront,
                  label: "Representadas",
                ),
                _menuItem(
                  index: 3,
                  icon: Icons.receipt_long,
                  label: "Pedidos",
                ),
                _menuItem(
                  index: 4,
                  icon: Icons.local_shipping,
                  label: "Transportadoras",
                ),
              ],
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "© 2025 R A Representações",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }

  Widget _menuItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool active = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelect(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blue.withOpacity(.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? Colors.blue : Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: active ? Colors.blue : Colors.grey[800],
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
