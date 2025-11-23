import 'package:flutter/material.dart';
import '../services/transportadora_service.dart';
import 'transportadora_card.dart';
import '../pages/transportadora_form_page.dart';

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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      final Map<String, dynamic> transportadoraData =
                      data.data()! as Map<String, dynamic>;

                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: SizedBox(
                            width: 600,
                            child: TransportadoraFormPage(
                              editId: data.id,
                              editData: transportadoraData,
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmar exclusão'),
                          content: const Text('Deseja realmente excluir esta transportadora?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Excluir')),
                          ],
                        ),
                      );

                      if (confirm) {
                        await service.deleteTransportadora(data.id);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
