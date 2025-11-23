import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class RepresentadasService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // --- Representadas ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getRepresentadasStream() {
    return firestore.collection('representadas').orderBy('nomeFantasia').snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getRepresentada(String id) {
    return firestore.collection('representadas').doc(id).get();
  }

  Future<String> uploadImagemRepresentada(XFile file, String representadaId) async {
    try {
      final ref = storage.ref().child('representadas/$representadaId/logo.jpg');
      
      if (kIsWeb) {
        // Na Web usamos putData com os bytes
        final bytes = await file.readAsBytes();
        final metadata = SettableMetadata(
          contentType: file.mimeType ?? 'image/jpeg',
        );
        final uploadTask = ref.putData(bytes, metadata);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        // No Mobile usamos putFile
        final uploadTask = ref.putFile(File(file.path));
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      print('Erro no upload: $e');
      rethrow;
    }
  }

  Future<void> salvarRepresentada(Map<String, dynamic> data, {String? id}) async {
    final ref = firestore.collection('representadas');
    
    // Se tiver imagemFile (XFile), faz upload e pega URL, removendo o objeto File do map
    if (data.containsKey('imagemFile') && data['imagemFile'] != null) {
       // Precisamos de um ID para salvar a imagem. Se for criação, gera um ID novo
       final docId = id ?? ref.doc().id;
       final file = data['imagemFile'] as XFile;
       
       try {
         final url = await uploadImagemRepresentada(file, docId);
         data['imagem'] = url;
       } catch (e) {
         print("Erro ao fazer upload da imagem: $e");
         // Podemos optar por continuar sem a imagem ou lançar o erro
         // throw e; 
       }
       data.remove('imagemFile');
       
       // Se for criação e geramos ID manual, precisamos usar set
       if (id == null) {
          // Criação com ID gerado
           await ref.doc(docId).set({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
       }
    }

    if (id == null) {
      await ref.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.doc(id).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> excluirRepresentada(String id) {
    return firestore.collection('representadas').doc(id).delete();
  }

  // --- Contatos ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getContatosStream(String representadaId) {
    return firestore
        .collection('representadas')
        .doc(representadaId)
        .collection('contatos')
        .orderBy('nome')
        .snapshots();
  }

  Future<void> salvarContato(String representadaId, Map<String, dynamic> data, {String? contatoId}) async {
    final ref = firestore.collection('representadas').doc(representadaId).collection('contatos');
    if (contatoId == null) {
      await ref.add(data);
    } else {
      await ref.doc(contatoId).update(data);
    }
  }

  Future<void> excluirContato(String representadaId, String contatoId) {
    return firestore
        .collection('representadas')
        .doc(representadaId)
        .collection('contatos')
        .doc(contatoId)
        .delete();
  }

  // --- Produtos ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getProdutosStream(String representadaId) {
    return firestore
        .collection('representadas')
        .doc(representadaId)
        .collection('produtos')
        .orderBy('nome')
        .snapshots();
  }

  Future<void> salvarProduto(String representadaId, Map<String, dynamic> data, {String? produtoId}) async {
    final ref = firestore.collection('representadas').doc(representadaId).collection('produtos');
    
    // Validate defaults
    if (data['multiploVenda'] == null || data['multiploVenda'] == '') {
      data['multiploVenda'] = 1;
    }

    if (produtoId == null) {
      await ref.add(data);
    } else {
      await ref.doc(produtoId).update(data);
    }
  }

  Future<void> excluirProduto(String representadaId, String produtoId) {
    return firestore
        .collection('representadas')
        .doc(representadaId)
        .collection('produtos')
        .doc(produtoId)
        .delete();
  }

  // --- Pagamentos ---
  
  Stream<QuerySnapshot<Map<String, dynamic>>> getPagamentosStream(String representadaId) {
    return firestore
        .collection('representadas')
        .doc(representadaId)
        .collection('pagamentos')
        .snapshots();
  }

  Future<void> salvarPagamento(String representadaId, Map<String, dynamic> data, {String? pagamentoId}) async {
    final ref = firestore.collection('representadas').doc(representadaId).collection('pagamentos');
    if (pagamentoId == null) {
      await ref.add(data);
    } else {
      await ref.doc(pagamentoId).update(data);
    }
  }

  Future<void> excluirPagamento(String representadaId, String pagamentoId) {
    return firestore
        .collection('representadas')
        .doc(representadaId)
        .collection('pagamentos')
        .doc(pagamentoId)
        .delete();
  }
}
