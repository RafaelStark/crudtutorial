import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/clientes_service.dart';

// =============================================================
// FUNÇÃO PRINCIPAL QUE ABRE O FORMULÁRIO
// Pode ser chamada de qualquer lugar:
// showClienteForm(context)
// showClienteForm(context, docID: id, data: snapshot)
// =============================================================
void showClienteForm(
    BuildContext context, {
      String? docID,
      DocumentSnapshot? data,
    }) {
  final service = FirestoreClientes();

  // Controllers
  final cnpj = TextEditingController(text: data?["cnpj"]);
  final razao = TextEditingController(text: data?["razaoSocial"]);
  final fantasia = TextEditingController(text: data?["nomeFantasia"]);
  final email = TextEditingController(text: data?["email"]);
  final telefone = TextEditingController(text: data?["telefone"]);
  final endereco = TextEditingController(text: data?["endereco"]);
  final numero = TextEditingController(text: data?["numero"]);
  final bairro = TextEditingController(text: data?["bairro"]);
  final cidade = TextEditingController(text: data?["cidade"]);
  final uf = TextEditingController(text: data?["uf"]);
  final cep = TextEditingController(text: data?["cep"]);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  docID == null ? "Novo Cliente" : "Editar Cliente",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _input("CNPJ", cnpj),
              _input("Razão Social", razao),
              _input("Nome Fantasia", fantasia),
              _input("Email", email),
              _input("Telefone", telefone),
              _input("Endereço", endereco),
              _input("Número", numero),
              _input("Bairro", bairro),
              _input("Cidade", cidade),
              _input("UF", uf),
              _input("CEP", cep),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (docID == null) {
                      // CREATE
                      await service.addCliente(
                        cnpj: cnpj.text,
                        razaoSocial: razao.text,
                        nomeFantasia: fantasia.text,
                        email: email.text,
                        telefone: telefone.text,
                        endereco: endereco.text,
                        numero: numero.text,
                        bairro: bairro.text,
                        cidade: cidade.text,
                        uf: uf.text,
                        cep: cep.text,
                      );
                    } else {
                      // UPDATE
                      await service.updateCliente(
                        docID,
                        cnpj: cnpj.text,
                        razaoSocial: razao.text,
                        nomeFantasia: fantasia.text,
                        email: email.text,
                        telefone: telefone.text,
                        endereco: endereco.text,
                        numero: numero.text,
                        bairro: bairro.text,
                        cidade: cidade.text,
                        uf: uf.text,
                        cep: cep.text,
                      );
                    }

                    Navigator.pop(context);
                  },
                  child: Text(docID == null ? "Salvar" : "Atualizar"),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}

// =============================================================
// WIDGET REUTILIZÁVEL PARA INPUTS
// =============================================================
Widget _input(String label, TextEditingController ctrl) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
