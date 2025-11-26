import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/app_shell.dart';
import 'package:crudtutorial/core/widgets/custom_add_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/pedidos_service.dart';
import 'pedido_form_page.dart';

class PedidosPage extends StatelessWidget {
  const PedidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PedidosService();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomAddButton(
                  label: 'Novo Pedido',
                  icon: Icons.add_shopping_cart,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppShell(
                          initialIndex: 3, // Aba de Pedidos
                          child: PedidoFormPage(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.getPedidosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Erro ao carregar pedidos'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('Nenhum pedido realizado.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final id = doc.id;
                    
                    final clienteNome = data['cliente']?['razaoSocial'] ?? 'Cliente Removido';
                    final repNome = data['representada']?['nomeFantasia'] ?? 'Representada Removida';
                    final valor = data['valorTotal'] ?? 0.0;
                    final numPedido = data['numeroPedido'] ?? 0;
                    
                    final date = (data['dataCriacao'] as Timestamp?)?.toDate();
                    final dateStr = date != null ? dateFormat.format(date) : '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text('#$numPedido', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                        title: Text(clienteNome),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rep: $repNome'),
                            Text('Data: $dateStr'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currency.format(valor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            Text('${data['quantidadeItens'] ?? 0} itens', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        onTap: () {
                          // Abrir detalhes/edição
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppShell(
                                initialIndex: 3,
                                child: PedidoFormPage(pedidoId: id, data: data),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
