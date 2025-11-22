// lib/features/clientes/pages/cliente_form_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/clientes_service.dart';
import 'package:crudtutorial/features/contatos/services/contatos_service.dart';

// IMPORTANTE: botão padronizado
import 'package:crudtutorial/features/clientes/widgets/app_button.dart';

/// Página de formulário para criar/editar cliente + contatos (contatos como subcoleção)
class ClienteFormPage extends StatefulWidget {
  final String? docID; // null = novo cliente
  final DocumentSnapshot? data; // dados do cliente (se editing)
  final VoidCallback onBack;

  const ClienteFormPage({
    super.key,
    this.docID,
    this.data,
    required this.onBack,
  });

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final FirestoreClientes clientesService = FirestoreClientes();
  final ContatosService contatosService = ContatosService();

  // Controllers Cliente
  late final MaskedTextController cnpj;
  late final TextEditingController ie;
  late final TextEditingController razao;
  late final TextEditingController fantasia;
  late final TextEditingController email;
  late final MaskedTextController telefone;
  late final TextEditingController endereco;
  late final TextEditingController numero;
  late final TextEditingController bairro;
  late final TextEditingController cidade;
  late final TextEditingController uf;
  late final MaskedTextController cep;

  // Controllers Contato (usados para adicionar à lista pendente)
  final TextEditingController contatoNome = TextEditingController();
  final TextEditingController contatoCargo = TextEditingController();
  final MaskedTextController contatoTelefone = MaskedTextController(mask: '(00) 00000-0000');
  final TextEditingController contatoEmail = TextEditingController();

  // Lista temporária de contatos pendentes (adicionados antes de salvar o cliente)
  List<Map<String, dynamic>> contatosPendentes = [];

  bool _isCnpjSearching = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    cnpj = MaskedTextController(mask: '00.000.000/0000-00', text: widget.data?["cnpj"]);
    ie = TextEditingController(text: widget.data?["ie"]);
    razao = TextEditingController(text: widget.data?["razaoSocial"]);
    fantasia = TextEditingController(text: widget.data?["nomeFantasia"]);
    email = TextEditingController(text: widget.data?["email"]);
    telefone = MaskedTextController(mask: '(00) 00000-0000', text: widget.data?["telefone"]);
    endereco = TextEditingController(text: widget.data?["endereco"]);
    numero = TextEditingController(text: widget.data?["numero"]);
    bairro = TextEditingController(text: widget.data?["bairro"]);
    cidade = TextEditingController(text: widget.data?["cidade"]);
    uf = TextEditingController(text: widget.data?["uf"]);
    cep = MaskedTextController(mask: '00000-000', text: widget.data?["cep"]);
  }

  @override
  void dispose() {
    cnpj.dispose();
    ie.dispose();
    razao.dispose();
    fantasia.dispose();
    email.dispose();
    telefone.dispose();
    endereco.dispose();
    numero.dispose();
    bairro.dispose();
    cidade.dispose();
    uf.dispose();
    cep.dispose();

    contatoNome.dispose();
    contatoCargo.dispose();
    contatoTelefone.dispose();
    contatoEmail.dispose();
    super.dispose();
  }

  // Input helper
  Widget _input(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Buscar dados do CNPJ (BrasilAPI)
  Future<void> _fetchCnpjData() async {
    final raw = cnpj.text;
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CNPJ incompleto.')));
      return;
    }

    setState(() => _isCnpjSearching = true);
    try {
      final url = Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$cleaned');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (mounted) {
          setState(() {
            razao.text = data['razao_social'] ?? '';
            fantasia.text = data['nome_fantasia'] ?? '';
            endereco.text = data['logradouro'] ?? '';
            numero.text = data['numero'] ?? '';
            bairro.text = data['bairro'] ?? '';
            cidade.text = data['municipio'] ?? '';
            uf.text = data['uf'] ?? '';
            cep.text = (data['cep'] ?? '').toString().replaceAll(RegExp(r'[^\d]'), '');
            final rawTel = data['ddd_telefone_1'] ?? data['ddd_telefone_2'] ?? '';
            telefone.text = rawTel.toString().replaceAll(RegExp(r'[^\d]'), '');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados preenchidos.')));
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro CNPJ: ${resp.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro rede: $e')));
    } finally {
      if (mounted) setState(() => _isCnpjSearching = false);
    }
  }

  // Adiciona contato à lista pendente
  void _addContact() {
    if (contatoNome.text.trim().isEmpty || contatoEmail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome e e-mail são obrigatórios'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      contatosPendentes.add({
        'nome': contatoNome.text.trim(),
        'cargo': contatoCargo.text.trim(),
        'telefone': contatoTelefone.text.trim(),
        'email': contatoEmail.text.trim(),
      });
      contatoNome.clear();
      contatoCargo.clear();
      contatoTelefone.clear();
      contatoEmail.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contato adicionado à lista'), backgroundColor: Colors.green));
  }

  // Excluir contato pendente
  void _removePendingContact(int idx) {
    setState(() {
      contatosPendentes.removeAt(idx);
    });
  }

  // Salvar cliente + contatos
  Future<void> _saveClient() async {
    if (_saving) return;
    setState(() => _saving = true);

    if (razao.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Razão social é obrigatória'), backgroundColor: Colors.red));
      setState(() => _saving = false);
      return;
    }

    final cleanedCnpj = cnpj.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanedCnpj.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CNPJ inválido'), backgroundColor: Colors.red));
      setState(() => _saving = false);
      return;
    }

    try {
      String clienteID;
      if (widget.docID == null) {
        final docRef = await clientesService.addCliente(
          cnpj: cnpj.text.trim(),
          ie: ie.text.trim(),
          razaoSocial: razao.text.trim(),
          nomeFantasia: fantasia.text.trim(),
          email: email.text.trim(),
          telefone: telefone.text.trim(),
          endereco: endereco.text.trim(),
          numero: numero.text.trim(),
          bairro: bairro.text.trim(),
          cidade: cidade.text.trim(),
          uf: uf.text.trim(),
          cep: cep.text.trim(),
        );
        clienteID = docRef.id;
      } else {
        await clientesService.updateCliente(
          widget.docID!,
          cnpj: cnpj.text.trim(),
          ie: ie.text.trim(),
          razaoSocial: razao.text.trim(),
          nomeFantasia: fantasia.text.trim(),
          email: email.text.trim(),
          telefone: telefone.text.trim(),
          endereco: endereco.text.trim(),
          numero: numero.text.trim(),
          bairro: bairro.text.trim(),
          cidade: cidade.text.trim(),
          uf: uf.text.trim(),
          cep: cep.text.trim(),
        );
        clienteID = widget.docID!;
      }

      // Salva contatos pendentes
      for (final contato in contatosPendentes) {
        await contatosService.salvarContato(clienteID, contato);
      }

      setState(() => contatosPendentes.clear());

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente salvo com sucesso'), backgroundColor: Colors.green));
      widget.onBack();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.docID != null;
    final pageTitle = isEditing ? 'Editar Cliente' : 'Adicionar Novo Cliente';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ---------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                Text(
                  pageTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ]),

              /// BOTÃO SALVAR CLIENTE (Padronizado)
              AppButton(
                text: "Salvar Cliente",
                icon: Icons.save,
                onPressed: _saveClient,
              ),
            ],
          ),

          const Divider(height: 20),

          Expanded(
            child: SelectionArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Cliente form ----------------------------------------
                  Expanded(
                    flex: 7,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dados Gerais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),

                            Row(children: [
                              Expanded(
                                flex: 2,
                                child: _input('CNPJ', cnpj, keyboardType: TextInputType.number),
                              ),
                              const SizedBox(width: 12),

                              /// BOTÃO BUSCAR CNPJ (Padronizado)
                              SizedBox(
                                width: 170,
                                child: AppButton(
                                  text: _isCnpjSearching ? "Buscando..." : "Buscar CNPJ",
                                  icon: Icons.search,
                                  onPressed: _isCnpjSearching ? null : _fetchCnpjData,
                                ),
                              ),
                            ]),

                            _input('Razão Social', razao),
                            _input('Nome Fantasia', fantasia),
                            _input('Inscrição Estadual', ie),

                            const SizedBox(height: 16),
                            const Text('Contato e Endereço', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            _input('E-mail', email, keyboardType: TextInputType.emailAddress),
                            _input('Telefone', telefone, keyboardType: TextInputType.phone),
                            _input('CEP', cep, keyboardType: TextInputType.number),
                            _input('Endereço', endereco),

                            Row(children: [
                              Expanded(child: _input('Número', numero, keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _input('Bairro', bairro)),
                            ]),

                            Row(children: [
                              Expanded(child: _input('Cidade', cidade)),
                              const SizedBox(width: 12),
                              Expanded(child: _input('UF', uf)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // RIGHT: Contatos -------------------------------------------
                  Expanded(
                    flex: 3,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Adicionar Contato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),

                            _input('Nome', contatoNome),
                            _input('Cargo', contatoCargo),
                            _input('Telefone', contatoTelefone, keyboardType: TextInputType.phone),
                            _input('E-mail', contatoEmail, keyboardType: TextInputType.emailAddress),

                            const SizedBox(height: 8),

                            /// BOTÃO ADICIONAR CONTATO (Padronizado)
                            AppButton(
                              text: "Adicionar Contato",
                              icon: Icons.person_add,
                              onPressed: _addContact,
                            ),

                            const SizedBox(height: 16),

                            // Lista de contatos pendentes
                            if (contatosPendentes.isNotEmpty) ...[
                              const Text('Contatos a adicionar:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),

                              ...contatosPendentes.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final c = entry.value;

                                return ListTile(
                                  leading: const Icon(Icons.person, color: Colors.orange),
                                  title: Text(c['nome']),
                                  subtitle: Text(c['cargo']),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removePendingContact(idx),
                                  ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }),

                              const Divider(height: 20),
                            ],

                            // Contatos do Firestore (caso edição)
                            if (isEditing) ...[
                              const SizedBox(height: 12),
                              const Text('Contatos existentes:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),

                              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                stream: contatosService.listarContatos(widget.docID!),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                                  final docs = snapshot.data!.docs;

                                  if (docs.isEmpty) {
                                    return const Text("Nenhum contato cadastrado.");
                                  }

                                  return Column(
                                    children: docs.map((doc) {
                                      final d = doc.data();
                                      return ListTile(
                                        leading: const Icon(Icons.person, color: Colors.blue),
                                        title: Text(d['nome']),
                                        subtitle: Text(d['cargo']),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => contatosService.excluirContato(widget.docID!, doc.id),
                                        ),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            ),

          ),
        ],
      ),
    );
  }
}
