import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/app_shell.dart';
import 'package:crudtutorial/core/widgets/custom_add_button.dart';
import 'package:crudtutorial/features/representadas/pages/contato_form_page.dart';
import 'package:crudtutorial/features/representadas/pages/produto_form_page.dart';
import 'package:crudtutorial/features/representadas/pages/representada_form_page.dart';
import 'package:flutter/material.dart';
import '../services/representadas_service.dart';

class RepresentadaDetalhePage extends StatefulWidget {
  final String representadaId;
  final Map<String, dynamic> dadosRepresentada;

  const RepresentadaDetalhePage({
    super.key,
    required this.representadaId,
    required this.dadosRepresentada,
  });

  @override
  State<RepresentadaDetalhePage> createState() => _RepresentadaDetalhePageState();
}

class _RepresentadaDetalhePageState extends State<RepresentadaDetalhePage> {
  final _service = RepresentadasService();
  String _produtoSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dadosRepresentada['nomeFantasia'] ?? 'Detalhes da Representada'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Dados da Empresa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppShell(
                    initialIndex: 2,
                    child: RepresentadaFormPage(
                      representadaId: widget.representadaId,
                      data: widget.dadosRepresentada,
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- COLUNA ESQUERDA: Dados e Contatos ---
          Expanded(
            flex: 2, // 2/5 da tela
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEmpresaInfoCard(),
                  const SizedBox(height: 24),
                  _buildHeaderSecao('Contatos', () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppShell(
                          initialIndex: 2,
                          child: ContatoFormPage(representadaId: widget.representadaId),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildListaContatos(),
                ],
              ),
            ),
          ),

          // --- COLUNA DIREITA: Produtos ---
          Expanded(
            flex: 3, // 3/5 da tela
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Pesquisar produtos...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _produtoSearchQuery = val.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      CustomAddButton(
                        label: 'Novo Produto',
                        icon: Icons.add,
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppShell(
                                initialIndex: 2,
                                child: ProdutoFormPage(representadaId: widget.representadaId),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildListaProdutos()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets da Esquerda ---

  Widget _buildEmpresaInfoCard() {
    final d = widget.dadosRepresentada;
    final imagemUrl = d['imagem'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imagemUrl != null && imagemUrl.toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imagemUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.business, size: 50, color: Colors.grey),
              ),
            ),
            _buildInfoRow('Razão Social:', d['razaoSocial']),
            _buildInfoRow('Nome Fantasia:', d['nomeFantasia']),
            _buildInfoRow('CNPJ:', d['cnpj']),
            _buildInfoRow('IE:', d['ie']),
            _buildInfoRow('Comissão:', '${d['comissao'] ?? 0}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildHeaderSecao(String titulo, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          tooltip: 'Adicionar $titulo',
        )
      ],
    );
  }

  Widget _buildListaContatos() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getContatosStream(widget.representadaId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Nenhum contato cadastrado.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(data['nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['cargo'] != null) Text(data['cargo']),
                  if (data['telefone'] != null) 
                    Row(children: [const Icon(Icons.phone, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(data['telefone'])]),
                  if (data['email'] != null) 
                    Row(children: [const Icon(Icons.email, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(data['email'])]),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Excluir', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppShell(
                          initialIndex: 2,
                          child: ContatoFormPage(
                            representadaId: widget.representadaId,
                            contatoId: doc.id,
                            data: data,
                          ),
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _service.excluirContato(widget.representadaId, doc.id);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- Widgets da Direita ---

  Widget _buildListaProdutos() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getProdutosStream(widget.representadaId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Erro ao carregar produtos');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data?.docs ?? [];
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data();
          final nome = (data['nome'] ?? '').toString().toLowerCase();
          final codigo = (data['codigo'] ?? '').toString().toLowerCase();
          return nome.contains(_produtoSearchQuery) || codigo.contains(_produtoSearchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data();
            
            final preco = data['preco']?.toDouble() ?? 0.0;
            final qtdCaixa = data['quantidadeCaixa']?.toInt() ?? 1;
            final precoUnitario = qtdCaixa > 0 ? preco / qtdCaixa : 0.0;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Container(
                  width: 48, 
                  height: 48,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2, color: Colors.blue),
                ),
                title: Text('${data['codigo'] ?? ''} - ${data['nome'] ?? ''}'),
                subtitle: Text(
                  'Preço: R\$ ${preco.toStringAsFixed(2)} - Unitário: R\$ ${precoUnitario.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppShell(
                              initialIndex: 2,
                              child: ProdutoFormPage(
                                representadaId: widget.representadaId,
                                produtoId: doc.id,
                                data: data,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _service.excluirProduto(widget.representadaId, doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
