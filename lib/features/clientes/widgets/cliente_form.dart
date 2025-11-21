import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/clientes_service.dart';

// Widget auxiliar para criar os campos de input de forma padronizada
Widget _input(String label, TextEditingController ctrl) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl,
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

void showClienteForm(
    BuildContext context, {
      String? docID,
      DocumentSnapshot? data,
    }) {
  final service = FirestoreClientes();

  final cnpj = MaskedTextController(
      mask: '00.000.000/0000-00', text: data?["cnpj"]);
  final ie = TextEditingController(text: data?["ie"]);
  final razao = TextEditingController(text: data?["razaoSocial"]);
  final fantasia = TextEditingController(text: data?["nomeFantasia"]);
  final email = TextEditingController(text: data?["email"]);
  final telefone = MaskedTextController(
      mask: '(00) 00000-0000', text: data?["telefone"]);
  final endereco = TextEditingController(text: data?["endereco"]);
  final numero = TextEditingController(text: data?["numero"]);
  final bairro = TextEditingController(text: data?["bairro"]);
  final cidade = TextEditingController(text: data?["cidade"]);
  final uf = TextEditingController(text: data?["uf"] ?? 'ES');
  final cep = MaskedTextController(
      mask: '00000-000', text: data?["cep"]);

  bool validarCNPJ(String cnpjRaw) {
    String c = cnpjRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (c.length != 14) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(c)) return false;
    int calc(int t) {
      int soma = 0, peso = t - 7;
      for (int i = 0; i < t; i++) {
        soma += int.parse(c[i]) * peso;
        peso = peso == 2 ? 9 : peso - 1;
      }
      int d = 11 - (soma % 11);
      return d > 9 ? 0 : d;
    }

    return calc(12) == int.parse(c[12]) && calc(13) == int.parse(c[13]);
  }

  bool validarEmail(String email) {
    if (email.isEmpty) return true;
    final regex = RegExp(r'^[\w-.]+@([\w-]+.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<void> buscarCNPJ(String cnpjValue) async {
    if (!validarCNPJ(cnpjValue)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CNPJ inválido')));
      return;
    }
    final cnpjLimpo = cnpjValue.replaceAll(RegExp(r'[^0-9]'), '');
    // URL da BrasilAPI. Atenção: Removi os colchetes e parênteses que estavam na URL
    final url = Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$cnpjLimpo');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dataApi = jsonDecode(response.body);
        razao.text = dataApi['razao_social'] ?? '';
        fantasia.text = dataApi['nome_fantasia'] ?? '';
        endereco.text = dataApi['logradouro'] ?? '';
        numero.text = dataApi['numero'] ?? '';
        bairro.text = dataApi['bairro'] ?? '';
        cidade.text = dataApi['municipio'] ?? '';
        uf.text = dataApi['uf'] ?? '';
        cep.text = dataApi['cep'] ?? '';
        ie.text = dataApi['inscricao_estadual'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CNPJ não encontrado')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÍTULO E BOTÃO FECHAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      docID == null ? "Novo Cliente" : "Detalhes do Cliente",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),

                // CAMPO CNPJ E BOTÃO BUSCAR
                Row(
                  children: [
                    Expanded(child: _input("CNPJ", cnpj)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (cnpj.text.isNotEmpty) {
                          buscarCNPJ(cnpj.text);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Digite um CNPJ')),
                          );
                        }
                      },
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),

                // OUTROS CAMPOS
                _input("IE", ie),
                _input("Razão Social", razao),
                _input("Nome Fantasia", fantasia),
                _input("Email", email),
                _input("Telefone", telefone),
                _input("Endereço", endereco),
                _input("Número", numero),
                _input("Bairro", bairro),
                _input("Cidade", cidade),
                _input("UF", uf),
                _input("CEP", cep),
                const SizedBox(height: 20),

                // --- BOTÕES DE AÇÃO ---
                if (docID != null)
                // BOTÕES EDITAR E EXCLUIR (Se docID existir)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Editar
                            if (email.text.isNotEmpty && !validarEmail(email.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'E-mail inválido. Verifique se contém @ e o domínio.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            await service.updateCliente(
                              docID,
                              cnpj: cnpj.text,
                              ie: ie.text,
                              razaoSocial: razao.text,
                              nomeFantasia: fantasia.text,
                              email: email.text,
                              telefone: telefone.text,
                              endereco: endereco.text,
                              numero: numero.text,
                              bairro: bairro.text,
                              cidade: cidade.text,
                              uf: uf.text,
                              cep: cep.text,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text("Editar"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () async {
                            // Confirmação antes de excluir
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
                              await service.deleteCliente(docID);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Excluir"),
                        ),
                      ),
                    ],
                  )
                else
                // BOTÃO SALVAR (Se docID for nulo, ou seja, Novo Cliente)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (email.text.isNotEmpty && !validarEmail(email.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'E-mail inválido. Verifique se contém @ e o domínio.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (cnpj.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('O CNPJ é obrigatório.')),
                          );
                          return;
                        }
                        await service.addCliente(
                          cnpj: cnpj.text,
                          ie: ie.text,
                          razaoSocial: razao.text,
                          nomeFantasia: fantasia.text,
                          email: email.text,
                          telefone: telefone.text,
                          endereco: endereco.text,
                          numero: numero.text,
                          bairro: bairro.text,
                          cidade: cidade.text,
                          uf: uf.text,
                          cep: cep.text,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("Salvar"),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}