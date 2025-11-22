// lib/features/clientes/pages/clientes_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/clientes_service.dart';
import 'cliente_form_page.dart';
import '../widgets/cliente_dashboard.dart';

//Importar botoes
import 'package:crudtutorial/features/clientes/widgets/app_button.dart';

// Estado de visualização
enum ClientesView { list, dashboard, form }

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final FirestoreClientes service = FirestoreClientes();
  String search = "";

  ClientesView _currentView = ClientesView.list;
  DocumentSnapshot? _selectedClient;
  String? _formDocID;

  void _backToList() {
    setState(() {
      _currentView = ClientesView.list;
      _selectedClient = null;
      _formDocID = null;
    });
  }

  void _openDashboard(DocumentSnapshot client) {
    setState(() {
      _selectedClient = client;
      _currentView = ClientesView.dashboard;
    });
  }

  void _openForm({String? docID, DocumentSnapshot? data}) {
    setState(() {
      _formDocID = docID;
      _selectedClient = data;
      _currentView = ClientesView.form;
    });
  }

  Widget _buildCurrentView() {
    if (_currentView == ClientesView.dashboard && _selectedClient != null) {
      return ClienteDashboard(
        data: _selectedClient!,
        docID: _selectedClient!.id,
        onBack: _backToList,
        onEdit: () => _openForm(docID: _selectedClient!.id, data: _selectedClient!),
      );
    }

    if (_currentView == ClientesView.form) {
      return ClienteFormPage(docID: _formDocID, data: _selectedClient, onBack: _backToList);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.getClientesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        final total = docs.length;
        final filtered = docs.where((d) {
          final data = d.data();
          final s = search.toLowerCase();
          return (data["razaoSocial"] ?? '').toString().toLowerCase().contains(s) ||
              (data["nomeFantasia"] ?? '').toString().toLowerCase().contains(s) ||
              (data["cidade"] ?? '').toString().toLowerCase().contains(s) ||
              (data["bairro"] ?? '').toString().toLowerCase().contains(s) ||
              (data["cnpj"] ?? '').toString().toLowerCase().contains(s);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Clientes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))
                ]),
                constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
                child: Row(children: [
                  const Icon(Icons.people, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Text('$total clientes cadastrados', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Pesquisar cliente...', prefixIcon: Icon(Icons.search), border: InputBorder.none),
                    onChanged: (v) => setState(() => search = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppButton(
                  text: "Adicionar Cliente",
                  icon: Icons.add,
                  onPressed: () => _openForm(),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final d = c.data();
                  return _ClienteTile(
                    data: c,
                    onDelete: () => service.deleteCliente(c.id),
                    onEdit: () => _openForm(docID: c.id, data: c),
                    onTap: () => _openDashboard(c),
                  );
                },
              ),
            )
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildCurrentView();
}

// tile com animação de zoom ao passar o mouse
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
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: hovering ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(hovering ? 0.12 : 0.04),
                  blurRadius: hovering ? 18 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: hovering
                  ? Border.all(color: Colors.blue.withOpacity(0.45), width: 2)
                  : null,
            ),
            child: Row(
              children: [
                // Ícone da loja
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store,
                    size: 32,
                    color: hovering ? Colors.blue : Colors.blue[300],
                  ),
                ),

                const SizedBox(width: 14),

                // Dados do cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        '${d['razaoSocial']} - ${d['nomeFantasia']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                          hovering ? Colors.blue[900] : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        'CNPJ: ${d['cnpj']}  |  Cidade: ${d['cidade']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botões
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirmar'),
                            content: const Text(
                                'Deseja remover este cliente?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Excluir')),
                            ],
                          ),
                        );
                        if (confirm == true) widget.onDelete();
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
