import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudtutorial/app_shell.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import '../services/representadas_service.dart';
import 'contato_form_page.dart';
import 'produto_form_page.dart';
import 'pagamento_form_page.dart';

class RepresentadaFormPage extends StatefulWidget {
  final String? representadaId;
  final Map<String, dynamic>? data;

  const RepresentadaFormPage({super.key, this.representadaId, this.data});

  @override
  State<RepresentadaFormPage> createState() => _RepresentadaFormPageState();
}

class _RepresentadaFormPageState extends State<RepresentadaFormPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = RepresentadasService();
  late TabController _tabController;

  // Controllers
  final _cnpjController = MaskedTextController(mask: '00.000.000/0000-00');
  final _ieController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _comissaoController = TextEditingController();
  
  String? _imagemUrl;
  XFile? _imagemFile; // Alterado de File para XFile para compatibilidade Web

  bool get isEditing => widget.representadaId != null;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (isEditing && widget.data != null) {
      final d = widget.data!;
      _cnpjController.text = d['cnpj'] ?? '';
      _ieController.text = d['ie'] ?? '';
      _razaoSocialController.text = d['razaoSocial'] ?? '';
      _nomeFantasiaController.text = d['nomeFantasia'] ?? '';
      _comissaoController.text = d['comissao']?.toString() ?? '';
      _imagemUrl = d['imagem'];
    }
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    _ieController.dispose();
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _comissaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagemFile = pickedFile;
      });
    }
  }

  Future<void> _salvarDadosBasicos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    final data = {
      'cnpj': _cnpjController.text,
      'ie': _ieController.text,
      'razaoSocial': _razaoSocialController.text,
      'nomeFantasia': _nomeFantasiaController.text,
      'comissao': double.tryParse(_comissaoController.text) ?? 0.0,
      if (_imagemFile != null) 'imagemFile': _imagemFile,
      if (_imagemUrl != null && _imagemFile == null) 'imagem': _imagemUrl,
    };

    try {
      await _service.salvarRepresentada(data, id: widget.representadaId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados salvos com sucesso!')),
      );
      
      if (!isEditing) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Representada' : 'Nova Representada'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: isEditing
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Dados Básicos'),
                  Tab(text: 'Contatos'),
                  Tab(text: 'Produtos'),
                  Tab(text: 'Pagamentos'),
                ],
              )
            : null,
      ),
      body: isEditing
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildDadosBasicosForm(),
                _buildContatosTab(),
                _buildProdutosTab(),
                _buildPagamentosTab(),
              ],
            )
          : _buildDadosBasicosForm(),
    );
  }

  Widget _buildDadosBasicosForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Campo de Imagem (Seleção de Arquivo)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 16, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logotipo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Selecionar Imagem'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            TextFormField(
              controller: _cnpjController,
              decoration: const InputDecoration(labelText: 'CNPJ'),
              validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _ieController,
              decoration: const InputDecoration(labelText: 'Inscrição Estadual'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            TextFormField(
              controller: _razaoSocialController,
              decoration: const InputDecoration(labelText: 'Razão Social'),
              validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
            ),
            TextFormField(
              controller: _nomeFantasiaController,
              decoration: const InputDecoration(labelText: 'Nome Fantasia'),
            ),
            TextFormField(
              controller: _comissaoController,
              decoration: const InputDecoration(labelText: 'Comissão (%)'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
            const SizedBox(height: 20),
            _isUploading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _salvarDadosBasicos,
                  child: const Text('Salvar Dados Básicos'),
                ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePreview() {
    if (_imagemFile != null) {
      if (kIsWeb) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _imagemFile!.path,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_imagemFile!.path),
            fit: BoxFit.cover,
          ),
        );
      }
    } else if (_imagemUrl != null && _imagemUrl!.isNotEmpty) {
       return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _imagemUrl!,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
          ),
        );
    } else {
      return const Icon(Icons.add_a_photo, color: Colors.grey, size: 40);
    }
  }

  // --- Abas ---

  Widget _buildContatosTab() {
    if (!isEditing) return const Center(child: Text('Salve a representada primeiro'));
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppShell(
                initialIndex: 2, // Índice de Representadas
                child: ContatoFormPage(representadaId: widget.representadaId!),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getContatosStream(widget.representadaId!),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
           final docs = snapshot.data!.docs;
           if (docs.isEmpty) return const Center(child: Text('Nenhum contato'));

           return ListView.builder(
             itemCount: docs.length,
             itemBuilder: (context, index) {
               final doc = docs[index];
               final d = doc.data();
               return ListTile(
                 title: Text(d['nome'] ?? ''),
                 subtitle: Text('${d['cargo'] ?? ''} - ${d['telefone'] ?? ''}'),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppShell(
                                initialIndex: 2, // Índice de Representadas
                                child: ContatoFormPage(
                                  representadaId: widget.representadaId!,
                                  contatoId: doc.id,
                                  data: d,
                                ),
                              ),
                            ),
                          );
                        }
                     ),
                     IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () => _service.excluirContato(widget.representadaId!, doc.id),
                     ),
                   ],
                 ),
               );
             },
           );
        },
      ),
    );
  }

  Widget _buildProdutosTab() {
    if (!isEditing) return const Center(child: Text('Salve a representada primeiro'));
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppShell(
                initialIndex: 2, // Índice de Representadas
                child: ProdutoFormPage(representadaId: widget.representadaId!),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getProdutosStream(widget.representadaId!),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
           final docs = snapshot.data!.docs;
           if (docs.isEmpty) return const Center(child: Text('Nenhum produto'));

           return ListView.builder(
             itemCount: docs.length,
             itemBuilder: (context, index) {
               final doc = docs[index];
               final d = doc.data();
               return ListTile(
                 leading: const Icon(Icons.image), // Placeholder para imagem
                 title: Text(d['nome'] ?? ''),
                 subtitle: Text('Cod: ${d['codigo'] ?? ''} - R\$ ${d['preco'] ?? ''}'),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppShell(
                                initialIndex: 2, // Índice de Representadas
                                child: ProdutoFormPage(
                                  representadaId: widget.representadaId!,
                                  produtoId: doc.id,
                                  data: d,
                                ),
                              ),
                            ),
                          );
                        }
                     ),
                     IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () => _service.excluirProduto(widget.representadaId!, doc.id),
                     ),
                   ],
                 ),
               );
             },
           );
        },
      ),
    );
  }

  Widget _buildPagamentosTab() {
    if (!isEditing) return const Center(child: Text('Salve a representada primeiro'));
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppShell(
                initialIndex: 2, // Índice de Representadas
                child: PagamentoFormPage(representadaId: widget.representadaId!),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getPagamentosStream(widget.representadaId!),
        builder: (context, snapshot) {
           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
           final docs = snapshot.data!.docs;
           if (docs.isEmpty) return const Center(child: Text('Nenhum pagamento configurado'));

           return ListView.builder(
             itemCount: docs.length,
             itemBuilder: (context, index) {
               final doc = docs[index];
               final d = doc.data();
               return ListTile(
                 title: Text(d['descricao'] ?? 'Pagamento'),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppShell(
                                initialIndex: 2, // Índice de Representadas
                                child: PagamentoFormPage(
                                  representadaId: widget.representadaId!,
                                  pagamentoId: doc.id,
                                  data: d,
                                ),
                              ),
                            ),
                          );
                        }
                     ),
                     IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () => _service.excluirPagamento(widget.representadaId!, doc.id),
                     ),
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
