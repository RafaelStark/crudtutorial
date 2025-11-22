// lib/contatos/pages/contatos_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/contatos_service.dart';

class ContatosPage extends StatelessWidget {
  final String clienteId;
  final String clienteNome; // opcional, só para mostrar no AppBar

  const ContatosPage({
    super.key,
    required this.clienteId,
    this.clienteNome = '',
  });

  @override
  Widget build(BuildContext context) {
    final service = ContatosService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Contatos ${clienteNome.isNotEmpty ? "• $clienteNome" : ""}'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => ContatoForm(clienteId: clienteId),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.listarContatos(clienteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum contato cadastrado.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              return ListTile(
                title: Text(data['nome'] ?? '—'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((data['cargo'] ?? '').toString().isNotEmpty)
                      Text(data['cargo']),
                    if ((data['telefone'] ?? '').toString().isNotEmpty)
                      Text(data['telefone']),
                    if ((data['email'] ?? '').toString().isNotEmpty)
                      Text(data['email']),
                  ],
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'editar') {
                      showDialog(
                        context: context,
                        builder: (_) => ContatoForm(
                          clienteId: clienteId,
                          contatoId: doc.id,
                          dados: doc,
                        ),
                      );
                    } else if (v == 'excluir') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmar'),
                          content: const Text('Deseja excluir este contato?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Excluir')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await service.excluirContato(clienteId, doc.id);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ContatoForm extends StatefulWidget {
  final String clienteId;
  final String? contatoId;
  final DocumentSnapshot<Map<String, dynamic>>? dados;

  const ContatoForm({
    super.key,
    required this.clienteId,
    this.contatoId,
    this.dados,
  });

  @override
  State<ContatoForm> createState() => _ContatoFormState();
}

class _ContatoFormState extends State<ContatoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _cargoCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.dados != null) {
      final d = widget.dados!.data()!;
      _nomeCtrl.text = d['nome'] ?? '';
      _cargoCtrl.text = d['cargo'] ?? '';
      _telCtrl.text = d['telefone'] ?? '';
      _emailCtrl.text = d['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cargoCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contatoId == null ? 'Novo contato' : 'Editar contato'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
              ),
              TextFormField(
                controller: _cargoCtrl,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.isNotEmpty && !v.contains('@')) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _saving ? null : _onSalvar,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _onSalvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'nome': _nomeCtrl.text.trim(),
      'cargo': _cargoCtrl.text.trim(),
      'telefone': _telCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    };

    try {
      await ContatosService()
          .salvarContato(widget.clienteId, data, contatoId: widget.contatoId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // mostrar erro simples
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
