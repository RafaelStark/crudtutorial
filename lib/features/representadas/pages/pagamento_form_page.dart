import 'package:flutter/material.dart';
import '../services/representadas_service.dart';

class PagamentoFormPage extends StatefulWidget {
  final String representadaId;
  final String? pagamentoId;
  final Map<String, dynamic>? data;

  const PagamentoFormPage({
    super.key, 
    required this.representadaId, 
    this.pagamentoId, 
    this.data
  });

  @override
  State<PagamentoFormPage> createState() => _PagamentoFormPageState();
}

class _PagamentoFormPageState extends State<PagamentoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = RepresentadasService();

  final _descricaoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _prazoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _descricaoController.text = widget.data!['descricao'] ?? '';
      _codigoController.text = widget.data!['codigo'] ?? '';
      _prazoController.text = widget.data!['prazo'] ?? '';
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _codigoController.dispose();
    _prazoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'descricao': _descricaoController.text,
      'codigo': _codigoController.text,
      'prazo': _prazoController.text,
    };

    await _service.salvarPagamento(
      widget.representadaId, 
      data, 
      pagamentoId: widget.pagamentoId
    );
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pagamentoId == null ? 'Novo Pagamento' : 'Editar Pagamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição (Ex: 30/60/90 dias)'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(labelText: 'Código (Opcional)'),
              ),
              TextFormField(
                controller: _prazoController,
                decoration: const InputDecoration(labelText: 'Prazo Médio (Opcional)'),
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
