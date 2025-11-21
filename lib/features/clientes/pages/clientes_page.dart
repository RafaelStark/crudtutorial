import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/clientes_service.dart';
import '../widgets/cliente_form.dart';
import '../widgets/cliente_details.dart'; // <--- IMPORTANTE: Importe o novo arquivo

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

          // Filtro de pesquisa
          final filtered = docs.where((d) {
            final data = d.data() as Map<String, dynamic>; // Cast seguro
            final s = search.toLowerCase();
            return (data["razaoSocial"] ?? '').toLowerCase().contains(s) ||
                (data["nomeFantasia"] ?? '').toLowerCase().contains(s) ||
                (data["cidade"] ?? '').toLowerCase().contains(s) ||
                (data["bairro"] ?? '').toLowerCase().contains(s) ||
                (data["cnpj"] ?? '').toLowerCase().contains(s);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÍTULO
                const Text(
                  "Clientes",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),

                // TOTAL DE CLIENTES
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
                    constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "$total clientes cadastrados",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BARRA DE PESQUISA + BOTÃO
                Row(
                  children: [
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
                          onChanged: (v) => setState(() => search = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Adicionar", style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () => showClienteForm(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // LISTA
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      // Usamos o widget customizado criado abaixo
                      return _ClienteTile(
                        data: c,
                        onDelete: () => service.deleteCliente(c.id),
                        onEdit: () => showClienteForm(context, docID: c.id, data: c),
                        onTap: () => showClienteDetails(context, c),
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

// ==============================================================================
// WIDGET CUSTOMIZADO PARA O ITEM DA LISTA (COM HOVER E ANIMAÇÃO)
// ==============================================================================
class _ClienteTile extends StatefulWidget {
  final DocumentSnapshot data;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ClienteTile({
    required this.data,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  State<_ClienteTile> createState() => _ClienteTileState();
}

class _ClienteTileState extends State<_ClienteTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Extrair dados para facilitar leitura
    final d = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap, // Abre os detalhes ao clicar no card
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            // A borda muda de cor ou o shadow aumenta no hover
            border: _isHovered
                ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.1 : 0.04),
                blurRadius: _isHovered ? 15 : 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              // Ícone ou Avatar para deixar mais bonito
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store,
                  color: _isHovered ? Colors.blue : Colors.blue[300],
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // TEXTOS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${d['razaoSocial']} - ${d['nomeFantasia']}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isHovered ? Colors.blue[900] : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "CNPJ: ${d['cnpj']}  |  Cidade: ${d['cidade']}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // BOTÕES DE AÇÃO (Edit/Delete)
              // Row separada para não propagar o clique do card
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: widget.onEdit,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}