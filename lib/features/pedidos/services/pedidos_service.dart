import 'package:cloud_firestore/cloud_firestore.dart';

class PedidosService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Stream da lista de pedidos
  Stream<QuerySnapshot<Map<String, dynamic>>> getPedidosStream() {
    return firestore.collection('pedidos').orderBy('numeroPedido', descending: true).snapshots();
  }

  // Detalhe de um pedido
  Future<DocumentSnapshot<Map<String, dynamic>>> getPedido(String id) {
    return firestore.collection('pedidos').doc(id).get();
  }

  // Criar Pedido com Auto-Incremento
  Future<void> criarPedido(Map<String, dynamic> pedidoData) async {
    // Usamos uma transação para garantir a integridade do contador
    return firestore.runTransaction((transaction) async {
      // Referência para o documento contador global (singleton)
      DocumentReference contadorRef = firestore.collection('contadores').doc('pedidos');
      DocumentSnapshot contadorSnapshot = await transaction.get(contadorRef);

      int proximoNumero = 1;

      if (contadorSnapshot.exists) {
        // Se já existe, pega o atual e soma 1
        int atual = (contadorSnapshot.data() as Map<String, dynamic>)['atual'] ?? 0;
        proximoNumero = atual + 1;
        transaction.update(contadorRef, {'atual': proximoNumero});
      } else {
        // Se não existe, cria iniciando em 1
        transaction.set(contadorRef, {'atual': 1});
      }

      // Adiciona o número gerado aos dados do pedido
      pedidoData['numeroPedido'] = proximoNumero;
      pedidoData['dataCriacao'] = FieldValue.serverTimestamp(); // Data do sistema

      // Cria o documento do pedido
      DocumentReference novoPedidoRef = firestore.collection('pedidos').doc();
      transaction.set(novoPedidoRef, pedidoData);
    });
  }

  // Atualizar Pedido (apenas dados editáveis, não o número)
  Future<void> atualizarPedido(String id, Map<String, dynamic> dados) async {
    dados['dataAtualizacao'] = FieldValue.serverTimestamp();
    await firestore.collection('pedidos').doc(id).update(dados);
  }

  Future<void> excluirPedido(String id) async {
    await firestore.collection('pedidos').doc(id).delete();
  }

  // --- Helpers para buscar dados das outras coleções ---

  Stream<QuerySnapshot<Map<String, dynamic>>> getClientesStream() {
    return firestore.collection('clientes').orderBy('razaoSocial').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRepresentadasStream() {
    return firestore.collection('representadas').orderBy('nomeFantasia').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransportadorasStream() {
    return firestore.collection('transportadoras').orderBy('razaoSocial').snapshots();
  }

  // Busca subcoleções específicas (depende da seleção do pai)
  Future<QuerySnapshot<Map<String, dynamic>>> getProdutosDaRepresentada(String representadaId) {
    return firestore.collection('representadas').doc(representadaId).collection('produtos').get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPagamentosDaRepresentada(String representadaId) {
    return firestore.collection('representadas').doc(representadaId).collection('pagamentos').get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getContatosDoCliente(String clienteId) {
    return firestore.collection('clientes').doc(clienteId).collection('contatos').get();
  }
}
