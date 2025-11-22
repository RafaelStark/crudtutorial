import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../services/clientes_service.dart';
import 'package:crudtutorial/features/contatos/services/contatos_service.dart';

// --- WIDGETS AUXILIARES ---

// Widget auxiliar para Títulos
Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        color: Colors.blue[800],
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// Widget auxiliar para Input (Simplificado)
Widget _input(String label, TextEditingController ctrl, {bool enabled = true, TextInputType keyboardType = TextInputType.text}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

// --------------------------------------------------------------------------
// PÁGINA PRINCIPAL: CLIENTE FORM PAGE
// --------------------------------------------------------------------------

class ClienteFormPage extends StatefulWidget {
  final String? docID;
  final DocumentSnapshot? data;
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

  // Controllers para os dados do Cliente
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

  // Controllers para o NOVO Contato
  final TextEditingController contatoNome = TextEditingController();
  final TextEditingController contatoCargo = TextEditingController();
  final MaskedTextController contatoTelefone = MaskedTextController(mask: '(00) 00000-0000');
  final TextEditingController contatoEmail = TextEditingController();

  bool _isCnpjSearching = false;

  @override
  void initState() {
    super.initState();
    // Inicialização dos controllers
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

  // Função de Busca de CNPJ (AGORA USANDO BRASILAPI)
  Future<void> _fetchCnpjData() async {
    final rawCnpj = cnpj.text;
    final cleanedCnpj = rawCnpj.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedCnpj.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o CNPJ completo (14 dígitos) para buscar.')),
      );
      return;
    }

    setState(() => _isCnpjSearching = true);

    try {
      // Usando BrasilAPI (API pública e gratuita)
      final url = Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$cleanedCnpj');
      // A BrasilAPI não requer headers de autorização
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Mapeamento dos campos (Adaptado para BrasilAPI)
            razao.text = data['razao_social'] ?? '';
            fantasia.text = data['nome_fantasia'] ?? '';
            endereco.text = data['logradouro'] ?? '';

            // O campo 'numero' da BrasilAPI é mapeado para 'numero' aqui.
            // Se a API não retornar um valor, ele será vazio.
            numero.text = data['numero'] ?? '';

            bairro.text = data['bairro'] ?? '';
            cidade.text = data['municipio'] ?? '';
            uf.text = data['uf'] ?? '';

            // Tratamento e limpeza do CEP e Telefone
            cep.text = data['cep']?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

            // O BrasilAPI retorna telefones como uma lista de strings. Pegamos o primeiro.
            final rawTelefone = data['ddd_telefone_1'] ?? data['ddd_telefone_2'] ?? '';
            telefone.text = rawTelefone.replaceAll(RegExp(r'[^\d]'), '');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dados do CNPJ preenchidos com sucesso!')),
            );
          });
        }
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CNPJ não encontrado.')),
        );
      } else {
        // Erro geral da API, mas a requisição de rede foi bem-sucedida
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar CNPJ. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Este catch é ativado em caso de erro de rede (como o 'Failed to fetch')
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de Rede: Verifique sua conexão com a internet. Detalhe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCnpjSearching = false);
    }
  }

  // Lógica para Salvar/Atualizar Cliente (inalterada)
  Future<void> _saveClient() async {
    if (email.text.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail inválido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (cnpj.text.replaceAll(RegExp(r'[^\d]'), '').length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O CNPJ é obrigatório e deve ter 14 dígitos.')),
      );
      return;
    }

    if (widget.docID != null) {
      await clientesService.updateCliente(
        widget.docID!,
        cnpj: cnpj.text, ie: ie.text, razaoSocial: razao.text, nomeFantasia: fantasia.text,
        email: email.text, telefone: telefone.text, endereco: endereco.text, numero: numero.text,
        bairro: bairro.text, cidade: cidade.text, uf: uf.text, cep: cep.text,
      );
    } else {
      await clientesService.addCliente(
        cnpj: cnpj.text, ie: ie.text, razaoSocial: razao.text, nomeFantasia: fantasia.text,
        email: email.text, telefone: telefone.text, endereco: endereco.text, numero: numero.text,
        bairro: bairro.text, cidade: cidade.text, uf: uf.text, cep: cep.text,
      );
    }

    widget.onBack();
  }

  // Lógica para Adicionar NOVO Contato (inalterada)
  void _addContact() async {
    if (widget.docID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salve o cliente antes de adicionar contatos.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (contatoNome.text.isEmpty || contatoEmail.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e Email do contato são obrigatórios.'), backgroundColor: Colors.red),
      );
      return;
    }

    Future<void> salvarContato(
        String clienteId,
        String? contatoId,
        Map<String, dynamic> data,
        ) async {
      final contatosRef = FirebaseFirestore.instance
          .collection('clientes')
          .doc(clienteId)
          .collection('contatos');

      if (contatoId == null) {
        await contatosRef.add(data);
      } else {
        await contatosRef.doc(contatoId).update(data);
      }
    }

    contatoNome.clear();
    contatoCargo.clear();
    contatoTelefone.clear();
    contatoEmail.clear();
  }


  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.docID != null;
    final String pageTitle = isEditing ? "Editar Cliente" : "Adicionar Novo Cliente";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO DA PÁGINA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                    tooltip: 'Voltar para a Lista',
                  ),
                  Text(
                    pageTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.blue),
                onPressed: _saveClient,
                tooltip: 'Salvar Cliente',
              ),
            ],
          ),
          const Divider(height: 20),

          // CORPO (DUAS COLUNAS)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLUNA 1 (ESQUERDA): FORMULÁRIO PRINCIPAL (70%)
                Expanded(
                  flex: 7,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- DADOS GERAIS ---
                          _sectionTitle("Dados Gerais"),

                          // CAMPO CNPJ DENTRO DE UM ROW COM O BOTÃO BUSCAR
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _input("CNPJ", cnpj, keyboardType: TextInputType.number),
                              ),
                              const SizedBox(width: 12),
                              // BOTÃO BUSCAR
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ElevatedButton.icon(
                                    onPressed: _isCnpjSearching ? null : _fetchCnpjData,
                                    icon: _isCnpjSearching
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.search, color: Colors.white),
                                    label: Text(_isCnpjSearching ? "Buscando..." : "Buscar CNPJ", style: const TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // FIM DO BLOCO CNPJ + BOTÃO

                          _input("Razão Social", razao),
                          _input("Nome Fantasia", fantasia),
                          _input("Inscrição Estadual", ie),

                          const Divider(height: 30),

                          // --- CONTATO E ENDEREÇO ---
                          _sectionTitle("Contato e Endereço"),
                          _input("Email", email, keyboardType: TextInputType.emailAddress),
                          _input("Telefone", telefone, keyboardType: TextInputType.phone),
                          _input("CEP", cep, keyboardType: TextInputType.number),
                          _input("Endereço", endereco),
                          Row(
                            children: [
                              Expanded(child: _input("Número", numero, keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _input("Bairro", bairro)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _input("Cidade", cidade)),
                              const SizedBox(width: 12),
                              Expanded(child: _input("UF", uf)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // COLUNA 2 (DIREITA): CADASTRO DE CONTATOS (30%)
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Adicionar Contato"),
                          _input("Nome", contatoNome, enabled: isEditing),
                          _input("Cargo", contatoCargo, enabled: isEditing),
                          _input("Telefone", contatoTelefone, enabled: isEditing, keyboardType: TextInputType.phone),
                          _input("Email", contatoEmail, enabled: isEditing, keyboardType: TextInputType.emailAddress),

                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: isEditing ? _addContact : null,
                            icon: const Icon(Icons.person_add),
                            label: const Text("Adicionar Contato"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          const Divider(height: 30),

                          // LISTA DE CONTATOS EXISTENTES
                          _sectionTitle("Contatos Existentes"),
                          if (!isEditing)
                            const Text("Salve o cliente para adicionar/ver contatos."),
                          if (isEditing)
                            _buildContactList(widget.docID!),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir a lista de contatos do cliente
  Widget _buildContactList(String clienteID) {
    return StreamBuilder<QuerySnapshot>(
      stream: contatosService.listarContatos(clienteID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Erro ao carregar contatos.");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contatos = snapshot.data!.docs;

        if (contatos.isEmpty) {
          return const Text("Nenhum contato cadastrado.");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contatos.map((c) {
            final contatoData = c.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(contatoData['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(contatoData['cargo'] ?? '-'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => contatosService.excluirContato(clienteID, c.id),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}