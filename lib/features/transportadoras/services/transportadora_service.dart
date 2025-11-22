import 'package:cloud_firestore/cloud_firestore.dart';

class TransportadoraService {
  final CollectionReference _colecao =
  FirebaseFirestore.instance.collection('transportadoras');

  // Retorna stream para listar transportadoras
  Stream<QuerySnapshot> listarTransportadoras() {
    return _colecao.snapshots();
  }

  // Adicionar transportadora
  Future<String> addTransportadora(Map<String, dynamic> data) async {
    final doc = await _colecao.add({
      ...data,
      'filiais': [], // inicializa vazio
    });
    return doc.id;
  }

  // Adicionar filial à transportadora
  Future<void> addFilial(String transportadoraId, Map<String, String> filial) async {
    final docRef = _colecao.doc(transportadoraId);
    await docRef.update({
      'filiais': FieldValue.arrayUnion([filial])
    });
  }

  // Buscar transportadora por ID
  Future<Map<String, dynamic>> getTransportadoraById(String id) async {
    final doc = await _colecao.doc(id).get();
    if (!doc.exists) throw Exception("Transportadora não encontrada");
    return doc.data() as Map<String, dynamic>;
  }

  // Atualizar transportadora
  Future<void> updateTransportadora(String id, Map<String, dynamic> data) async {
    await _colecao.doc(id).update(data);
  }

  // Deletar transportadora
  Future<void> deleteTransportadora(String id) async {
    await _colecao.doc(id).delete();
  }
}
