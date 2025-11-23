import 'package:flutter/material.dart';
import '../services/transportadora_service.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class TransportadoraFormPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic>? editData; // dados da transportadora para edição
  final String? editId;

  const TransportadoraFormPage({super.key, required this.onBack, this.editData, this.editId});

  @override
  State<TransportadoraFormPage> createState() => _TransportadoraFormPageState();
}

class _TransportadoraFormPageState extends State<TransportadoraFormPage> {
  final _formKey = GlobalKey<FormState>();
  final service = TransportadoraService();

  late MaskedTextController cnpjController;
  final razaoController = TextEditingController();
  final fantasiaController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();
  final telController = MaskedTextController(mask: '(00) 00000-0000');

  List<String> telefones = [];
  List<Map<String, String>> filiais = [];

  @override
  void initState() {
    super.initState();
    cnpjController = MaskedTextController(mask: '00.000.000/0000-00');

    if (widget.editData != null) {
      _loadData(widget.editData!);
    }
  }

  void _loadData(Map<String, dynamic> data) {
    cnpjController.text = data['cnpj'] ?? '';
    razaoController.text = data['razao_social'] ?? '';
    fantasiaController.text = data['nome_fantasia'] ?? '';
    cidadeController.text = data['cidade'] ?? '';
    estadoController.text = data['estado'] ?? '';
    telefones = List<String>.from(data['telefones'] ?? []);

    // Corrige LinkedMap para Map<String, String>
    filiais = (data['filiais'] as List<dynamic>?)
        ?.map((f) => Map<String, String>.from(f as Map))
        .toList() ??
        [];

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: cnpjController,
              decoration: const InputDecoration(labelText: "CNPJ"),
              validator: (v) => v!.isEmpty ? "Preencha o CNPJ" : null,
            ),
            TextFormField(
              controller: razaoController,
              decoration: const InputDecoration(labelText: "Razão Social"),
              validator: (v) => v!.isEmpty ? "Preencha a razão social" : null,
            ),
            TextFormField(
              controller: fantasiaController,
              decoration: const InputDecoration(labelText: "Nome Fantasia"),
              validator: (v) => v!.isEmpty ? "Preencha o nome fantasia" : null,
            ),
            TextFormField(
              controller: cidadeController,
              decoration: const InputDecoration(labelText: "Cidade"),
              validator: (v) => v!.isEmpty ? "Preencha a cidade" : null,
            ),
            TextFormField(
              controller: estadoController,
              decoration: const InputDecoration(labelText: "Estado"),
              validator: (v) => v!.isEmpty ? "Preencha o estado" : null,
            ),
            const SizedBox(height: 20),
            const Text("Telefones", style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: telController,
                    decoration: const InputDecoration(labelText: "Telefone"),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (telController.text.isNotEmpty) {
                      setState(() {
                        telefones.add(telController.text);
                        telController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            Wrap(
              spacing: 8,
              children: telefones.map((t) => Chip(label: Text(t))).toList(),
            ),
            const Divider(height: 40),
            const Text("Filiais", style: TextStyle(fontSize: 18)),
            ElevatedButton.icon(
              onPressed: _addFilialDialog,
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Filial"),
            ),
            Column(
              children: filiais
                  .map((f) => ListTile(
                title: Text("${f['cidade']} - ${f['estado']}"),
                subtitle: Text("Telefone: ${f['telefone']}"),
              ))
                  .toList(),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _salvar,
                  child: const Text("Salvar"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: widget.onBack,
                  child: const Text("Voltar"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> dados = {
        "cnpj": cnpjController.text,
        "razao_social": razaoController.text,
        "nome_fantasia": fantasiaController.text,
        "cidade": cidadeController.text,
        "estado": estadoController.text,
        "telefones": telefones,
      };

      if (widget.editId != null) {
        await service.updateTransportadora(widget.editId!, dados);
      } else {
        String id = await service.addTransportadora(dados);
        for (var f in filiais) {
          await service.addFilial(id, f);
        }
      }

      widget.onBack();
    }
  }

  void _addFilialDialog() {
    String a = "";
    String c = "";
    String e = "";
    String t = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adicionar Filial"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                decoration: const InputDecoration(labelText: "CNPJ"),
                onChanged: (v) => a = v),
            TextField(
                decoration: const InputDecoration(labelText: "Cidade"),
                onChanged: (v) => c = v),
            TextField(
                decoration: const InputDecoration(labelText: "Estado"),
                onChanged: (v) => e = v),
            TextField(
                decoration: const InputDecoration(labelText: "Telefone"),
                onChanged: (v) => t = v),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (c.isNotEmpty && e.isNotEmpty && t.isNotEmpty) {
                setState(
                        () => filiais.add({"cnpj": a, "cidade": c, "estado": e, "telefone": t}));
                Navigator.pop(context);
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }
}
