import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void showClienteDetails(BuildContext context, DocumentSnapshot data) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // CABEÇALHO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detalhes do Cliente",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                // DADOS GERAIS
                _sectionTitle("Dados Gerais"),
                _infoRow("Razão Social", data['razaoSocial']),
                _infoRow("Nome Fantasia", data['nomeFantasia']),
                _infoRow("CNPJ", data['cnpj']),
                _infoRow("Inscrição Estadual", data['ie']),

                const SizedBox(height: 20),

                // CONTATO
                _sectionTitle("Contato"),
                _infoRow("Email", data['email']),
                _infoRow("Telefone", data['telefone']),

                const SizedBox(height: 20),

                // ENDEREÇO
                _sectionTitle("Endereço"),
                _infoRow("Logradouro", "${data['endereco']}, ${data['numero']}"),
                _infoRow("Bairro", data['bairro']),
                _infoRow("Cidade/UF", "${data['cidade']} - ${data['uf']}"),
                _infoRow("CEP", data['cep']),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Widget auxiliar para Títulos de Seção
Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        color: Colors.blue[800],
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// Widget auxiliar para Linhas de Informação
Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}