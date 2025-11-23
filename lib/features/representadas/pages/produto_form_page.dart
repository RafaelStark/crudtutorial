import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
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

  @override
  void initState() {
    super.initState();
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
        // O MaskedTextController espera o texto puro para aplicar a máscara, mas é mais fácil setar o texto
        // mascarado se ele bater com a máscara.
        // Porém, MaskedTextController é meio rígido. Vamos tentar apenas setar o texto formatado.
        String ipiStr = ipi.toStringAsFixed(2).replaceAll('.', ',');
        // Se o valor for menor que 10 (ex: 5,00), precisamos adicionar zero à esquerda (05,00) para bater com a máscara 00,00?
        // A máscara '00,00' obriga 2 dígitos antes da vírgula.
        if (ipi < 10) {
          ipiStr = '0$ipiStr';
        }
        _ipiController.text = ipiStr;
      }
      
      _multiploController.text = d['multiploVenda']?.toString() ?? '';
      _unidadeController.text = d['unidadeVenda'] ?? '';
      _categoriaController.text = d['categoria'] ?? '';
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _precoController.dispose();
    _ipiController.dispose();
    _multiploController.dispose();
    _unidadeController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Converter IPI de volta para double (00,00 -> 00.00)
    String ipiText = _ipiController.text.replaceAll(',', '.');
    double ipiValue = double.tryParse(ipiText) ?? 0.0;

    final data = {
      'codigo': _codigoController.text,
      'nome': _nomeController.text,
      'preco': _precoController.numberValue, // Pega o valor double
      'ipi': ipiValue,
      'multiploVenda': int.tryParse(_multiploController.text) ?? 1,
      'unidadeVenda': _unidadeController.text,
      'categoria': _categoriaController.text,
      'imagens': [], // TODO: Implementar upload de imagens
    };

    await _service.salvarProduto(
      widget.representadaId, 
      data, 
      produtoId: widget.produtoId
    );
    
    if (!mounted) return;
    Navigator.pop(context);
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
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _ipiController,
                decoration: const InputDecoration(labelText: 'IPI (%)'),
                keyboardType: TextInputType.number,
                // MaskedTextController já aplica a máscara, não precisa de inputFormatters extras conflitantes
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
              ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
