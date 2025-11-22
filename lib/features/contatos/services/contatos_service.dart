// lib/contatos/services/contatos_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ContatosService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Lista contatos (stream) de um cliente
  Stream<QuerySnapshot<Map<String, dynamic>>> listarContatos(String clienteId) {
    return firestore
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos')
        .orderBy('nome')
        .snapshots();
  }

  /// Pega um contato (opcional)
  Future<DocumentSnapshot<Map<String, dynamic>>> pegarContato(
      String clienteId, String contatoId) {
    return firestore
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos')
        .doc(contatoId)
        .get();
  }

  /// Salvar (criar ou atualizar) contato
  Future<void> salvarContato(String clienteId, Map<String, dynamic> data,
      {String? contatoId}) {
    final ref = firestore
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos');

    if (contatoId == null) {
      return ref.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      return ref.doc(contatoId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Excluir contato
  Future<void> excluirContato(String clienteId, String contatoId) async {
    await FirebaseFirestore.instance
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos')
        .doc(contatoId)
        .delete();
  }
}
