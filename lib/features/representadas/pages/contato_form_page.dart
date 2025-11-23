import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import '../services/representadas_service.dart';

class ContatoFormPage extends StatefulWidget {
  final String representadaId;
  final String? contatoId;
  final Map<String, dynamic>? data;

  const ContatoFormPage({
    super.key, 
    required this.representadaId, 
    this.contatoId, 
    this.data
  });

  @override
  State<ContatoFormPage> createState() => _ContatoFormPageState();
}

class _ContatoFormPageState extends State<ContatoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = RepresentadasService();

  final _nomeController = TextEditingController();
  final _cargoController = TextEditingController();
  // Usando MaskedTextController para telefone
  final _telefoneController = MaskedTextController(mask: '(00) 00000-0000');
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _nomeController.text = widget.data!['nome'] ?? '';
      _cargoController.text = widget.data!['cargo'] ?? '';
      _telefoneController.text = widget.data!['telefone'] ?? '';
      _emailController.text = widget.data!['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cargoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nome': _nomeController.text,
      'cargo': _cargoController.text,
      'telefone': _telefoneController.text,
      'email': _emailController.text,
    };

    await _service.salvarContato(
      widget.representadaId, 
      data, 
      contatoId: widget.contatoId
    );
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contatoId == null ? 'Novo Contato' : 'Editar Contato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
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
