// lib/features/contatos/services/contatos_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ContatosService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Retorna stream dos contatos de um cliente
  Stream<QuerySnapshot<Map<String, dynamic>>> listarContatos(String clienteId) {
    return firestore
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos')
        .orderBy('nome')
        .snapshots();
  }

  /// Pega um contato específico (opcional)
  Future<DocumentSnapshot<Map<String, dynamic>>> pegarContato(String clienteId, String contatoId) {
    return firestore
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos')
        .doc(contatoId)
        .get();
  }

  /// Salva (cria ou atualiza) um contato.
  /// Se contatoId for null cria novo doc, caso contrário atualiza.
  Future<void> salvarContato(String clienteId, Map<String, dynamic> data, {String? contatoId}) async {
    final ref = firestore.collection('clientes').doc(clienteId).collection('contatos');
    final payload = {
      ...data,
      if (!data.containsKey('createdAt')) 'updatedAt': FieldValue.serverTimestamp(),
    };

    if (contatoId == null) {
      await ref.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.doc(contatoId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Excluir contato
  Future<void> excluirContato(String clienteId, String contatoId) async {
    await firestore
        .collection('clientes')
        .doc(clienteId)
        .collection('contatos')
        .doc(contatoId)
        .delete();
  }
}
