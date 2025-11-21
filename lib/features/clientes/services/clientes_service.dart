import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreClientes {
  // Referência para a coleção "clientes"
  final CollectionReference clientes =
  FirebaseFirestore.instance.collection('clientes');

  // ======================================================
  // CREATE – Adicionar novo cliente
  // ======================================================
  Future<void> addCliente({
    required String cnpj,
    required String razaoSocial,
    required String nomeFantasia,
    required String email,
    required String telefone,
    required String endereco,
    required String numero,
    required String bairro,
    required String cidade,
    required String uf,
    required String cep,
  }) {
    return clientes.add({
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
      'cep': cep,
      'timestamp': Timestamp.now(),
    });
  }

  // ======================================================
  // READ – Ler todos os clientes
  // ======================================================
  Stream<QuerySnapshot> getClientesStream() {
    return clientes.orderBy('timestamp', descending: true).snapshots();
  }

  // ======================================================
  // UPDATE – Atualizar cliente
  // ======================================================
  Future<void> updateCliente(
      String docID, {
        required String cnpj,
        required String razaoSocial,
        required String nomeFantasia,
        required String email,
        required String telefone,
        required String endereco,
        required String numero,
        required String bairro,
        required String cidade,
        required String uf,
        required String cep,
      }) {
    return clientes.doc(docID).update({
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'email': email,
      'telefone': telefone,
      'endereco': endereco,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
      'cep': cep,
      'timestamp': Timestamp.now(),
    });
  }

  // ======================================================
  // DELETE – Excluir cliente
  // ======================================================
  Future<void> deleteCliente(String docID) {
    return clientes.doc(docID).delete();
  }
}
