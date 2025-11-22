import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Certifique-se de que os imports abaixo estão corretos
import '../services/clientes_service.dart';
// Este import não é mais usado diretamente no build, mas pode ser útil
import '../widgets/cliente_form_page.dart';
// NOVO: Importa o serviço de contatos (Mantendo o caminho que você forneceu)
import 'package:crudtutorial/features/contatos/services/contatos_service.dart';

// ==============================================================================
// FUNÇÕES AUXILIARES (DEVE ESTAR FORA DA CLASSE ClienteDashboard)
// ==============================================================================

// Função auxiliar para Títulos de Seção
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

// Função auxiliar para Linhas de Informação
Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100, // Ajuste para caber na coluna da esquerda
          child: Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

// ==============================================================================
// WIDGET PRINCIPAL: DASHBOARD DE CLIENTES (AGORA É APENAS O BODY)
// ==============================================================================
class ClienteDashboard extends StatelessWidget {
  final DocumentSnapshot data;
  final String docID;
  final VoidCallback onBack;
  final VoidCallback onEdit; // NOVO: Callback para notificar o pai sobre a edição

  const ClienteDashboard({
    super.key,
    required this.data,
    required this.docID,
    required this.onBack,
    required this.onEdit, // Requerido
  });

  @override
  Widget build(BuildContext context) {
    final service = FirestoreClientes();
    // Instância do novo serviço de contatos
    final contatosService = ContatosService();
    final razaoSocial = data['razaoSocial'] ?? 'Detalhes do Cliente';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO DA TELA DE DETALHES COM BOTÕES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // BOTÃO DE VOLTAR E TÍTULO
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                    tooltip: 'Voltar para a Lista',
                  ),
                  Text(
                    razaoSocial,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // BOTÕES DE AÇÃO (EDITAR/EXCLUIR)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    // CORREÇÃO: Chama o callback onEdit para trocar o estado na ClientesPage
                    onPressed: onEdit,
                    tooltip: 'Editar Cliente',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmação'),
                          content: const Text('Deseja realmente excluir este cliente?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await service.deleteCliente(docID);
                        onBack(); // Volta para a lista após a exclusão
                      }
                    },
                    tooltip: 'Excluir Cliente',
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // CONTEÚDO PRINCIPAL (3 COLUNAS)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // COLUNA 1 (ESQUERDA): INFORMAÇÕES DO CLIENTE
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DADOS GERAIS
                            _sectionTitle("Dados Gerais"),
                            _infoRow("Razão Social", data['razaoSocial'] ?? '-'),
                            _infoRow("Nome Fantasia", data['nomeFantasia'] ?? '-'),
                            _infoRow("CNPJ", data['cnpj'] ?? '-'),
                            _infoRow("IE", data['ie'] ?? '-'),

                            const SizedBox(height: 20),

                            // CONTATO
                            _sectionTitle("Contato"),
                            _infoRow("Email", data['email'] ?? '-'),
                            _infoRow("Telefone", data['telefone'] ?? '-'),

                            const SizedBox(height: 20),

                            // ENDEREÇO
                            _sectionTitle("Endereço"),
                            _infoRow("Logradouro", "${data['endereco'] ?? '-'}, ${data['numero'] ?? '-'}"),
                            _infoRow("Bairro", data['bairro'] ?? '-'),
                            _infoRow("Cidade/UF", "${data['cidade'] ?? '-'} - ${data['uf'] ?? '-'}"),
                            _infoRow("CEP", data['cep'] ?? '-'),

                            const SizedBox(height: 30),

                            // NOVO: LISTA DE CONTATOS DA EMPRESA
                            _sectionTitle("Contatos da Empresa"),
                            StreamBuilder<QuerySnapshot>(
                              stream: contatosService.listarContatos(docID),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text("Erro ao carregar contatos.");
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final contatos = snapshot.data!.docs;

                                if (contatos.isEmpty) {
                                  return const Text("Nenhum contato registrado.");
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: contatos.map((c) {
                                    final contatoData = c.data() as Map<String, dynamic>;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Contato: ${contatoData['nome']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text("Cargo: ${contatoData['cargo'] ?? '-'}"),
                                          Text("Telefone: ${contatoData['telefone'] ?? '-'}"),
                                          Text("Email: ${contatoData['email'] ?? '-'}"),
                                          const Divider(height: 10, thickness: 0.5),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // COLUNA 2 (MEIO): PEDIDOS (A Implementar)
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "Pedidos do Cliente (A Implementar)",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // COLUNA 3 (DIREITA): TAREFAS/CONVERSAS (A Implementar)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        "Tarefas / Conversas (A Implementar)",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
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
}