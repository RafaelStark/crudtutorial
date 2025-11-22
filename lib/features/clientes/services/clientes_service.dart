// lib/features/clientes/services/clientes_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreClientes {
  final CollectionReference<Map<String, dynamic>> clientes =
  FirebaseFirestore.instance.collection('clientes').withConverter<Map<String,dynamic>>(
    fromFirestore: (snap, _) => snap.data() ?? <String,dynamic>{},
    toFirestore: (map, _) => map,
  );

  /// Adicionar novo cliente. Retorna DocumentReference para pegar ID.
  Future<DocumentReference<Map<String, dynamic>>> addCliente({
    required String cnpj,
    required String ie,
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
      'ie': ie,
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

  /// Stream de clientes
  Stream<QuerySnapshot<Map<String, dynamic>>> getClientesStream() {
    return clientes.orderBy('timestamp', descending: true).snapshots();
  }

  /// Atualiza cliente existente
  Future<void> updateCliente(
      String docID, {
        required String cnpj,
        required String ie,
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
      'ie': ie,
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

  /// Deleta cliente
  Future<void> deleteCliente(String docID) {
    return clientes.doc(docID).delete();
  }
}
