import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../clientes/services/clientes_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreClientes firestoreClientes = FirestoreClientes();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ==== Linha 1 dos cards ====
            Row(
              children: [
                _indicatorCard(
                  "Vendas Hoje",
                  "R\$ 1.250,00",
                  Icons.attach_money,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestoreClientes.getClientesStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _indicatorCard(
                          "Clientes",
                          "...",
                          Icons.people_alt,
                        );
                      }

                      final total = snapshot.data!.docs.length;

                      return _indicatorCard(
                        "Clientes Cadastrados",
                        "$total clientes",
                        Icons.people_alt,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==== Linha 2 ====
            Row(
              children: [
                _indicatorCard(
                  "Pedidos Abertos",
                  "14 pedidos",
                  Icons.shopping_cart,
                ),
                const SizedBox(width: 12),
                _indicatorCard(
                  "Mensagens",
                  "3 novas",
                  Icons.message,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================= CARD DE INDICADOR =========================
  Widget _indicatorCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
