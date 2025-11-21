import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/clientes_service.dart';
import '../widgets/cliente_form.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final FirestoreClientes service = FirestoreClientes();
  String search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getClientesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final total = docs.length;

          final filtered = docs.where((d) {
            final s = search.toLowerCase();
            return d["razaoSocial"].toLowerCase().contains(s) ||
                d["nomeFantasia"].toLowerCase().contains(s) ||
                d["cidade"].toLowerCase().contains(s) ||
                d["bairro"].toLowerCase().contains(s) ||
                d["cnpj"].toLowerCase().contains(s);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                // TÍTULO DA PÁGINA
                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                const Text(
                  "Clientes",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),

                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                // CABEÇALHO COM TOTAL DE CLIENTES
                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),

                    // 👇 define largura mínima e máxima para ficar tipo CARD
                    constraints: const BoxConstraints(
                      minWidth: 260,
                      maxWidth: 320, // você pode ajustar para 280 / 300
                    ),

                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "$total clientes cadastrados",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                // BARRA DE PESQUISA + BOTÃO "ADICIONAR"
                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                Row(
                  children: [
                    // CAMPO DE PESQUISA
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Pesquisar cliente...",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (v) {
                            setState(() => search = v);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // BOTÃO ADICIONAR
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Adicionar",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: () => showClienteForm(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                // LISTA DE CLIENTES
                // ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final c = filtered[i];

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // INFO DO CLIENTE
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${c['razaoSocial']} - ${c['nomeFantasia']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("CNPJ: ${c['cnpj']}"),
                                  Text("Cidade: ${c['cidade']}"),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // BOTÃO EDITAR
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showClienteForm(
                                context,
                                docID: c.id,
                                data: c,
                              ),
                            ),

                            // BOTÃO EXCLUIR
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => service.deleteCliente(c.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
