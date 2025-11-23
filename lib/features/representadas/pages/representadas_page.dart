import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/app_shell.dart';
import 'package:crudtutorial/core/widgets/custom_add_button.dart';
import 'package:crudtutorial/features/representadas/pages/representada_form_page.dart';
import 'package:flutter/material.dart';

import '../services/representadas_service.dart';

class RepresentadasPage extends StatefulWidget {
  const RepresentadasPage({super.key});

  @override
  State<RepresentadasPage> createState() => _RepresentadasPageState();
}

class _RepresentadasPageState extends State<RepresentadasPage> {
  final service = RepresentadasService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Representadas'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Barra de pesquisa e botão adicionar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Pesquisar representadas...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CustomAddButton(
                  label: "Adicionar Representada",
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppShell(
                          initialIndex: 2, // Índice de Representadas
                          child: RepresentadaFormPage(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.getRepresentadasStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar representadas'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                // Filtro local
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data();
                  final nome = (data['nomeFantasia'] ?? data['razaoSocial'] ?? '').toString().toLowerCase();
                  final cnpj = (data['cnpj'] ?? '').toString().toLowerCase();
                  
                  return nome.contains(_searchQuery) || cnpj.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Nenhuma representada encontrada'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final id = doc.id;
                    final nome = data['nomeFantasia'] ?? data['razaoSocial'] ?? 'Sem nome';
                    final imagemUrl = data['imagem'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: imagemUrl != null && imagemUrl.toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imagemUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        title: Text(nome),
                        subtitle: Text(data['cnpj'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AppShell(
                                      initialIndex: 2, // Índice de Representadas
                                      child: RepresentadaFormPage(representadaId: id, data: data),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir Representada'),
                                    content: const Text('Tem certeza que deseja excluir esta representada?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          service.excluirRepresentada(id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
