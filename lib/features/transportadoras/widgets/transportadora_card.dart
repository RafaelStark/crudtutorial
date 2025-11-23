import 'package:flutter/material.dart';

class TransportadoraCard extends StatelessWidget {
  final String id;
  final String cnpj;
  final String razao;
  final String fantasia;
  final String cidade;
  final String estado;
  final VoidCallback onTap;
  final Widget? trailing; // Para os botões de editar/excluir

  const TransportadoraCard({
    super.key,
    required this.id,
    required this.cnpj,
    required this.razao,
    required this.fantasia,
    required this.cidade,
    required this.estado,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        onTap: onTap,
        title: Text(fantasia),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Razão: $razao'),
            Text('CNPJ: $cnpj'),
            Text('Cidade: $cidade - $estado'),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}
