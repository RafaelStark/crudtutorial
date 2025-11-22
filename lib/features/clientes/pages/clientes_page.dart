import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/clientes_service.dart';
import '../widgets/cliente_form_page.dart';
import '../widgets/cliente_dashboard.dart';

// NOVO ESTADO: Adicionamos o estado 'form'
enum ClientesView { list, dashboard, form }

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final FirestoreClientes service = FirestoreClientes();
  String search = "";

  // ESTADO: Gerenciar a vista atual (Lista, Dashboard, ou Formulário)
  ClientesView _currentView = ClientesView.list;
  DocumentSnapshot? _selectedClient; // Cliente para Dashboard/Edição
  String? _formDocID; // ID do documento para edição (só usado pelo _openForm)

  // Função para retornar à lista (serve para voltar do Dashboard e do Formulário)
  void _backToList() {
    setState(() {
      _currentView = ClientesView.list;
      _selectedClient = null;
      _formDocID = null;
    });
  }

  // Função para abrir o dashboard
  void _openDashboard(DocumentSnapshot client) {
    setState(() {
      _selectedClient = client;
      _currentView = ClientesView.dashboard;
    });
  }

  // Função para abrir o formulário
  void _openForm({String? docID, DocumentSnapshot? data}) {
    setState(() {
      _formDocID = docID;
      _selectedClient = data; // Armazena os dados temporariamente para o formulário
      _currentView = ClientesView.form;
    });
  }

  // Novo método para construir o conteúdo da página
  Widget _buildCurrentView() {
    if (_currentView == ClientesView.dashboard && _selectedClient != null) {
      // 1. Dashboard
      return ClienteDashboard(
        data: _selectedClient!,
        docID: _selectedClient!.id,
        onBack: _backToList,
        // Callback para que o dashboard possa iniciar a edição (e trocar de view)
        onEdit: () => _openForm(docID: _selectedClient!.id, data: _selectedClient!),
      );
    }

    if (_currentView == ClientesView.form) {
      // 2. Formulário
      return ClienteFormPage(
        docID: _formDocID,
        data: _selectedClient,
        onBack: _backToList, // Passa o callback para o formulário voltar à lista
      );
    }

    // 3. Lista (padrão)
    return StreamBuilder<QuerySnapshot>(
      stream: service.getClientesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;

        // Filtro de pesquisa (mantido)
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
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
              // ... Cabeçalho ...
              const Text(
                "Clientes",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
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

              // BARRA DE PESQUISA + BOTÃO ADICIONAR
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
                    onPressed: () => _openForm(),
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
                    return _ClienteTile(
                      data: c,
                      onDelete: () => service.deleteCliente(c.id),
                      onEdit: () => _openForm(docID: c.id, data: c),
                      onTap: () => _openDashboard(c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Retorna o widget que representa a view atual, mantendo o menu lateral fixo (assumindo que o widget pai fornece o Scaffold).
    return _buildCurrentView();
  }
}

// ==============================================================================
// WIDGET CUSTOMIZADO PARA o ITEM DA LISTA (NÃO ALTERADO)
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
    final d = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: widget.onEdit,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmação'),
                          content: const Text(
                              'Deseja realmente excluir este cliente?'),
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

                      if (confirm == true) {
                        widget.onDelete();
                      }
                    },
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