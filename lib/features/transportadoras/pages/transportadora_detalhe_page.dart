import 'package:flutter/material.dart';
import '../services/transportadora_service.dart';

class TransportadoraDetalhePage extends StatelessWidget {
  final String id;
  final VoidCallback onBack;

  const TransportadoraDetalhePage({super.key, required this.id, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final service = TransportadoraService();

    return StreamBuilder(
      stream: service.listarTransportadoras(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final doc = snapshot.data!.docs.firstWhere((d) => d.id == id);
        final data = doc.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(onPressed: onBack, child: const Text("Voltar")),
              const SizedBox(height: 10),
              Text("CNPJ: ${data['cnpj']}", style: const TextStyle(fontSize: 18)),
              Text("Razão Social: ${data['razao_social']}", style: const TextStyle(fontSize: 18)),
              Text("Nome Fantasia: ${data['nome_fantasia']}", style: const TextStyle(fontSize: 16)),
              Text("Cidade: ${data['cidade']} - ${data['estado']}", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text("Telefones: ${data['telefones'].join(', ')}"),
              const SizedBox(height: 20),
              const Text("Filiais:", style: TextStyle(fontSize: 18)),
              ...List.generate((data['filiais'] ?? []).length, (i) {
                final f = data['filiais'][i];
                return ListTile(
                  title: Text("${f['cidade']} - ${f['estado']}"),
                  subtitle: Text("Telefone: ${f['telefone']}"),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
