import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:image_picker/image_picker.dart';
import '../services/representadas_service.dart';

class ProdutoFormPage extends StatefulWidget {
  final String representadaId;
  final String? produtoId;
  final Map<String, dynamic>? data;

  const ProdutoFormPage({
    super.key, 
    required this.representadaId, 
    this.produtoId, 
    this.data
  });

  @override
  State<ProdutoFormPage> createState() => _ProdutoFormPageState();
}

class _ProdutoFormPageState extends State<ProdutoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = RepresentadasService();

  final _codigoController = TextEditingController();
  final _nomeController = TextEditingController();
  
  // Usando MoneyMaskedTextController para preço
  final _precoController = MoneyMaskedTextController(leftSymbol: 'R\$ ', decimalSeparator: ',', thousandSeparator: '.');
  
  // Usando MaskedTextController para IPI com 2 casas decimais
  final _ipiController = MaskedTextController(mask: '00,00');

  final _multiploController = TextEditingController();
  final _unidadeController = TextEditingController();
  final _categoriaController = TextEditingController();
  
  final _quantidadeCaixaController = TextEditingController();
  final _precoUnitarioController = TextEditingController(); // Read-only, calculado

  // Lista para armazenar imagens (URLs ou XFiles)
  List<dynamic> _imagens = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    
    // Listeners para recalcular preço unitário
    _precoController.addListener(_calcularPrecoUnitario);
    _quantidadeCaixaController.addListener(_calcularPrecoUnitario);

    if (widget.data != null) {
      final d = widget.data!;
      _codigoController.text = d['codigo'] ?? '';
      _nomeController.text = d['nome'] ?? '';
      
      // Convertendo o valor salvo (double) para o formato do controller (R$ X.XXX,XX)
      if (d['preco'] != null) {
        _precoController.updateValue(d['preco'].toDouble());
      }
      
      // Para o IPI, precisamos formatar o double para string com vírgula e zeros à esquerda se necessário
      if (d['ipi'] != null) {
        double ipi = d['ipi'].toDouble();
        String ipiStr = ipi.toStringAsFixed(2).replaceAll('.', ',');
        if (ipi < 10) {
          ipiStr = '0$ipiStr';
        }
        _ipiController.text = ipiStr;
      }
      
      _multiploController.text = d['multiploVenda']?.toString() ?? '';
      _unidadeController.text = d['unidadeVenda'] ?? '';
      _categoriaController.text = d['categoria'] ?? '';
      
      if (d['quantidadeCaixa'] != null) {
        _quantidadeCaixaController.text = d['quantidadeCaixa'].toString();
      }
      
      if (d['imagens'] != null && d['imagens'] is List) {
        _imagens = List.from(d['imagens']);
      }
      // O cálculo ocorrerá automaticamente pelo listener
    }
  }

  @override
  void dispose() {
    _precoController.removeListener(_calcularPrecoUnitario);
    _quantidadeCaixaController.removeListener(_calcularPrecoUnitario);

    _codigoController.dispose();
    _nomeController.dispose();
    _precoController.dispose();
    _ipiController.dispose();
    _multiploController.dispose();
    _unidadeController.dispose();
    _categoriaController.dispose();
    _quantidadeCaixaController.dispose();
    _precoUnitarioController.dispose();
    super.dispose();
  }

  void _calcularPrecoUnitario() {
    final preco = _precoController.numberValue;
    final qtdCaixa = int.tryParse(_quantidadeCaixaController.text) ?? 1;
    
    if (qtdCaixa > 0) {
      final precoUnitario = preco / qtdCaixa;
      // Formatação simples para exibição
      _precoUnitarioController.text = 'R\$ ${precoUnitario.toStringAsFixed(2).replaceAll('.', ',')}';
    } else {
      _precoUnitarioController.text = 'R\$ 0,00';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imagens.addAll(pickedFiles);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagens.removeAt(index);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    // Converter IPI de volta para double (00,00 -> 00.00)
    String ipiText = _ipiController.text.replaceAll(',', '.');
    double ipiValue = double.tryParse(ipiText) ?? 0.0;

    // Separar XFiles (novos) de Strings (URLs existentes)
    List<XFile> novosArquivos = _imagens.whereType<XFile>().toList();
    List<String> urlsExistentes = _imagens.whereType<String>().toList();

    final data = {
      'codigo': _codigoController.text,
      'nome': _nomeController.text,
      'preco': _precoController.numberValue, // Pega o valor double
      'ipi': ipiValue,
      'multiploVenda': int.tryParse(_multiploController.text) ?? 1,
      'unidadeVenda': _unidadeController.text,
      'categoria': _categoriaController.text,
      'quantidadeCaixa': int.tryParse(_quantidadeCaixaController.text) ?? 1,
      'imagens': urlsExistentes, // Manda as URLs que já existem
      if (novosArquivos.isNotEmpty) 'novasImagensFiles': novosArquivos, // Manda os novos arquivos para upload
    };

    try {
      await _service.salvarProduto(
        widget.representadaId, 
        data, 
        produtoId: widget.produtoId
      );
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar produto: $e')),
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
        title: Text(widget.produtoId == null ? 'Novo Produto' : 'Editar Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      decoration: const InputDecoration(labelText: 'Preço (Caixa)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantidadeCaixaController,
                      decoration: const InputDecoration(labelText: 'Qtd na Caixa'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _precoUnitarioController,
                decoration: const InputDecoration(
                  labelText: 'Preço Unitário (Calculado)',
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
                readOnly: true,
              ),
              TextFormField(
                controller: _ipiController,
                decoration: const InputDecoration(labelText: 'IPI (%)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _multiploController,
                decoration: const InputDecoration(labelText: 'Múltiplo de Venda (Padrão: 1)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              TextFormField(
                controller: _unidadeController,
                decoration: const InputDecoration(labelText: 'Unidade de Venda (Ex: UN, CX)'),
              ),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              
              const SizedBox(height: 20),
              
              // Seção de Imagens
              const Text('Imagens do Produto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagens.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagens.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        ),
                      );
                    }

                    final imagem = _imagens[index];
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImageWidget(imagem),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              _isUploading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _salvar,
                    child: const Text('Salvar'),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(dynamic imagem) {
    if (imagem is String) {
      return Image.network(
        imagem, 
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
      );
    } else if (imagem is XFile) {
      if (kIsWeb) {
        return Image.network(imagem.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(imagem.path), fit: BoxFit.cover);
      }
    }
    return const SizedBox();
  }
}
