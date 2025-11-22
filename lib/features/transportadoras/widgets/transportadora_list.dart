import 'package:flutter/material.dart';
import '../services/transportadora_service.dart';
import 'transportadora_card.dart';

class TransportadoraList extends StatelessWidget {
  final Function(String) onTap;
  const TransportadoraList({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final service = TransportadoraService();

    return StreamBuilder(
      stream: service.listarTransportadoras(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Nenhuma transportadora"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i];
            return TransportadoraCard(
              id: data.id,
              cnpj: data['cnpj'],
              razao: data['razao_social'],
              fantasia: data['nome_fantasia'],
              cidade: data['cidade'],
              estado: data['estado'],
              onTap: () => onTap(data.id),
            );
          },
        );
      },
    );
  }
}
