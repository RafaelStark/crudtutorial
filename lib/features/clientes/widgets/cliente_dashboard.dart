// lib/features/clientes/pages/cliente_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/clientes_service.dart';
import 'package:crudtutorial/features/contatos/services/contatos_service.dart';

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: Colors.blue[800],
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(value.isEmpty ? '-' : value),
        ),
      ],
    ),
  );
}

class ClienteDashboard extends StatelessWidget {
  final DocumentSnapshot data;
  final String docID;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const ClienteDashboard({
    super.key,
    required this.data,
    required this.docID,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreClientes();
    final contatosService = ContatosService();
    final razao = data['razaoSocial'] ?? '-';

    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
                Text(razao, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Confirmar'),
                        content: const Text('Deseja excluir este cliente?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await service.deleteCliente(docID);
                      onBack();
                    }
                  },
                ),
              ])
            ],
          ),

          const Divider(height: 20),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD DA ESQUERDA
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionTitle('Dados Gerais'),
                          _infoRow('Razão Social', data['razaoSocial'] ?? '-'),
                          _infoRow('Nome Fantasia', data['nomeFantasia'] ?? '-'),
                          _infoRow('CNPJ', data['cnpj'] ?? '-'),
                          _infoRow('IE', data['ie'] ?? '-'),

                          const SizedBox(height: 12),

                          _sectionTitle('Contato'),
                          _infoRow('E-mail', data['email'] ?? '-'),
                          _infoRow('Telefone', data['telefone'] ?? '-'),

                          const SizedBox(height: 12),

                          _sectionTitle('Endereço'),
                          _infoRow('Logradouro', '${data['endereco'] ?? '-'}, ${data['numero'] ?? '-'}'),
                          _infoRow('Bairro', data['bairro'] ?? '-'),
                          _infoRow('Cidade/UF', '${data['cidade'] ?? '-'} - ${data['uf'] ?? '-'}'),
                          _infoRow('CEP', data['cep'] ?? '-'),

                          const SizedBox(height: 20),

                          _sectionTitle('Contatos da Empresa'),
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: contatosService.listarContatos(docID),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Erro ao carregar contatos.');
                              }
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final contatos = snapshot.data!.docs;

                              if (contatos.isEmpty) {
                                return const Text('Nenhum contato registrado.');
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: contatos.map((c) {
                                  final d = c.data();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Contato: ${d['nome'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Cargo: ${d['cargo'] ?? '-'}'),
                                        Text('Telefone: ${d['telefone'] ?? '-'}'),
                                        Text('Email: ${d['email'] ?? '-'}'),
                                        const Divider(height: 8),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // CARD CENTRAL
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                      child: Text(
                        'Pedidos do Cliente (A Implementar)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // CARD DA DIREITA
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                      child: Text(
                        'Tarefas / Conversas (A Implementar)',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
