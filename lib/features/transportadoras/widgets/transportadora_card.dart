import 'package:flutter/material.dart';

class TransportadoraCard extends StatelessWidget {
  final String id;
  final String cnpj;
  final String razao;
  final String fantasia;
  final String cidade;
  final String estado;
  final VoidCallback onTap;

  const TransportadoraCard({
    super.key,
    required this.id,
    required this.cnpj,
    required this.razao,
    required this.fantasia,
    required this.cidade,
    required this.estado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(fantasia),
        subtitle: Text("$razao\n$cidade - $estado"),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
