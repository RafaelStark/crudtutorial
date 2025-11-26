import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar data e moeda
import '../services/pedidos_service.dart';

class PedidoFormPage extends StatefulWidget {
  final String? pedidoId; // Se null, é novo pedido
  final Map<String, dynamic>? data; // Dados para edição

  const PedidoFormPage({super.key, this.pedidoId, this.data});

  @override
  State<PedidoFormPage> createState() => _PedidoFormPageState();
}

class _PedidoFormPageState extends State<PedidoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = PedidosService();

  // Controladores e Estados
  String? _selectedClienteId;
  Map<String, dynamic>? _selectedClienteData;
  
  String? _selectedContatoId; // Contato do cliente
  
  String? _selectedRepresentadaId;
  Map<String, dynamic>? _selectedRepresentadaData;
  
  String? _selectedPagamentoId; // Pagamento da representada
  
  String? _selectedTransportadoraId;
  Map<String, dynamic>? _selectedTransportadoraData;

  // Listas carregadas dinamicamente
  List<QueryDocumentSnapshot> _contatosList = [];
  List<QueryDocumentSnapshot> _produtosDisponiveis = [];
  List<QueryDocumentSnapshot> _pagamentosList = [];

  // Carrinho de produtos do pedido
  // Estrutura: { 'produtoId': '...', 'nome': '...', 'qtd': 1, 'precoUnit': 10.0, 'total': 10.0, ... }
  List<Map<String, dynamic>> _itensPedido = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _carregarDadosExistentes();
    }
  }

  void _carregarDadosExistentes() {
    final d = widget.data!;
    _selectedClienteId = d['clienteId'];
    _selectedClienteData = d['cliente']; // Armazenamos snap resumido no obj
    _selectedContatoId = d['contatoId'];
    
    _selectedRepresentadaId = d['representadaId'];
    _selectedRepresentadaData = d['representada'];
    _selectedPagamentoId = d['pagamentoId'];
    
    _selectedTransportadoraId = d['transportadoraId'];
    
    if (d['itens'] != null) {
      _itensPedido = List<Map<String, dynamic>>.from(d['itens']);
    }

    // Carregar dependências (contatos, pagamentos, produtos)
    if (_selectedClienteId != null) _carregarContatos(_selectedClienteId!);
    if (_selectedRepresentadaId != null) {
      _carregarDadosRepresentada(_selectedRepresentadaId!);
    }
  }

  // --- Carregamentos ---

  Future<void> _carregarContatos(String clienteId) async {
    final snap = await _service.getContatosDoCliente(clienteId);
    setState(() {
      _contatosList = snap.docs;
    });
  }

  Future<void> _carregarDadosRepresentada(String repId) async {
    // Carrega produtos e pagamentos em paralelo
    final futures = await Future.wait([
      _service.getProdutosDaRepresentada(repId),
      _service.getPagamentosDaRepresentada(repId),
    ]);

    setState(() {
      _produtosDisponiveis = futures[0].docs;
      _pagamentosList = futures[1].docs;
    });
  }

  // --- Ações ---

  void _onClienteChanged(String? novoId, Map<String, dynamic> data) {
    if (novoId == _selectedClienteId) return;
    setState(() {
      _selectedClienteId = novoId;
      _selectedClienteData = data;
      _selectedContatoId = null; // Reseta contato
      _contatosList = [];
    });
    if (novoId != null) _carregarContatos(novoId);
  }

  void _onRepresentadaChanged(String? novoId, Map<String, dynamic> data) {
    if (novoId == _selectedRepresentadaId) return;
    setState(() {
      _selectedRepresentadaId = novoId;
      _selectedRepresentadaData = data;
      _selectedPagamentoId = null; // Reseta pagamento
      _itensPedido = []; // Limpa carrinho pois mudou a representada
      _produtosDisponiveis = [];
      _pagamentosList = [];
    });
    if (novoId != null) _carregarDadosRepresentada(novoId);
  }

  void _adicionarProdutoNoCarrinho(Map<String, dynamic> produtoData, String produtoId) {
    // Verifica se já existe
    final index = _itensPedido.indexWhere((item) => item['produtoId'] == produtoId);
    if (index >= 0) {
      // Já existe, avisa ou incrementa (vamos apenas avisar por simplicidade)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto já adicionado. Edite a quantidade na lista.')),
      );
      return;
    }

    // Calcula preço inicial
    double preco = (produtoData['preco'] ?? 0.0).toDouble();
    int qtdCaixa = (produtoData['quantidadeCaixa'] ?? 1).toInt();
    double precoUnit = qtdCaixa > 0 ? preco / qtdCaixa : 0.0;

    setState(() {
      _itensPedido.add({
        'produtoId': produtoId,
        'codigo': produtoData['codigo'],
        'nome': produtoData['nome'],
        'quantidade': 1, // Default
        'precoTabela': preco, // Preço da caixa cheio
        'precoUnitario': precoUnit,
        'total': preco, // 1 * preco
        'unidade': produtoData['unidadeVenda'] ?? 'UN',
        'imagem': produtoData['imagem'],
      });
    });
  }

  void _atualizarQtdItem(int index, int novaQtd) {
    if (novaQtd < 1) return;
    setState(() {
      final item = _itensPedido[index];
      item['quantidade'] = novaQtd;
      item['total'] = item['precoTabela'] * novaQtd;
    });
  }

  void _removerItem(int index) {
    setState(() {
      _itensPedido.removeAt(index);
    });
  }

  double get _valorTotalPedido {
    return _itensPedido.fold(0.0, (sum, item) => sum + (item['total'] as double));
  }

  Future<void> _salvarPedido() async {
    if (!_formKey.currentState!.validate()) return;
    if (_itensPedido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um produto.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Monta objeto para salvar
      // Denormalizamos alguns dados (salvamos nome do cliente/representada) para facilitar listagem
      final pedidoData = {
        'clienteId': _selectedClienteId,
        'cliente': {
          'razaoSocial': _selectedClienteData?['razaoSocial'],
          'nomeFantasia': _selectedClienteData?['nomeFantasia'],
          'cnpj': _selectedClienteData?['cnpj'],
          'cidade': _selectedClienteData?['cidade'],
        },
        'contatoId': _selectedContatoId,
        
        'representadaId': _selectedRepresentadaId,
        'representada': {
          'nomeFantasia': _selectedRepresentadaData?['nomeFantasia'],
          'razaoSocial': _selectedRepresentadaData?['razaoSocial'],
        },
        'pagamentoId': _selectedPagamentoId,
        
        'transportadoraId': _selectedTransportadoraId,
        'transportadora': _selectedTransportadoraData, // Pode ser null se não selecionou
        
        'itens': _itensPedido,
        'valorTotal': _valorTotalPedido,
        'quantidadeItens': _itensPedido.length,
        
        // Se for edição, mantém a data original, se novo, o service põe
        if (widget.data != null) 'dataCriacao': widget.data!['dataCriacao'],
      };

      if (widget.pedidoId == null) {
        await _service.criarPedido(pedidoData);
      } else {
        await _service.atualizarPedido(widget.pedidoId!, pedidoData);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido salvo com sucesso!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final date = widget.data != null 
        ? (widget.data!['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now() 
        : DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pedidoId == null ? 'Novo Pedido' : 'Pedido #${widget.data?['numeroPedido']}'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total do Pedido', style: TextStyle(color: Colors.grey)),
                Text(formatter.format(_valorTotalPedido), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _salvarPedido,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Finalizar Pedido'),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cabeçalho com Data e Status (simulado)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Chip(label: Text('Data: $dateStr')),
              ],
            ),
            const SizedBox(height: 10),

            // 1. Seleção de CLIENTE com PESQUISA
            const Text('Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.getClientesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final clientes = snapshot.data!.docs;
                    
                    // Usando Autocomplete para permitir pesquisa
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<QueryDocumentSnapshot<Map<String, dynamic>>>(
                          initialValue: _selectedClienteData != null 
                              ? TextEditingValue(text: '${_selectedClienteData!['razaoSocial']} (${_selectedClienteData!['cidade'] ?? '-'})')
                              : TextEditingValue.empty,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return clientes;
                            }
                            return clientes.where((doc) {
                              final d = doc.data();
                              final s = textEditingValue.text.toLowerCase();
                              return (d['razaoSocial'] ?? '').toString().toLowerCase().contains(s) ||
                                     (d['nomeFantasia'] ?? '').toString().toLowerCase().contains(s);
                            });
                          },
                          displayStringForOption: (QueryDocumentSnapshot<Map<String, dynamic>> option) {
                            final d = option.data();
                            return '${d['razaoSocial']} (${d['cidade'] ?? '-'})';
                          },
                          onSelected: (QueryDocumentSnapshot<Map<String, dynamic>> selection) {
                            _onClienteChanged(selection.id, selection.data());
                          },
                          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                            // Se já temos um cliente selecionado e o texto está vazio (usuário apagou),
                            // podemos querer limpar a seleção. Mas o Autocomplete é meio chato com isso.
                            // Vamos manter simples: ele seleciona da lista.
                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Pesquisar Cliente...',
                                suffixIcon: Icon(Icons.search),
                              ),
                              validator: (v) => _selectedClienteId == null ? 'Selecione um cliente' : null,
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: SizedBox(
                                  width: constraints.maxWidth, // Usa a largura do layout pai
                                  height: 200.0,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      final d = option.data();
                                      return ListTile(
                                        title: Text(d['razaoSocial'] ?? ''),
                                        subtitle: Text('${d['nomeFantasia'] ?? ''} - ${d['cidade'] ?? ''}'),
                                        onTap: () {
                                          onSelected(option);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                    );
                  },
                ),
              ),
            ),

            // 1.1 Contato do Cliente
            if (_contatosList.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedContatoId,
                decoration: const InputDecoration(
                  labelText: 'Contato do Cliente',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _contatosList.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('${d['nome']} - ${d['cargo'] ?? ''}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedContatoId = val),
              ),
            ],

            const SizedBox(height: 20),

            // 2. Seleção de REPRESENTADA
            const Text('Representada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _service.getRepresentadasStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final repres = snapshot.data!.docs;
                    
                    return DropdownButtonFormField<String>(
                      value: _selectedRepresentadaId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Selecione a Representada'),
                      items: repres.map((doc) {
                        final d = doc.data();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(d['nomeFantasia'] ?? d['razaoSocial'] ?? 'Sem Nome'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final doc = repres.firstWhere((c) => c.id == val);
                        _onRepresentadaChanged(val, doc.data());
                      },
                      validator: (v) => v == null ? 'Selecione uma representada' : null,
                    );
                  },
                ),
              ),
            ),

            // 2.1 Pagamento da Representada
            if (_pagamentosList.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPagamentoId,
                decoration: const InputDecoration(
                  labelText: 'Condição de Pagamento',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _pagamentosList.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('${d['descricao']} ${d['prazo'] != null ? '(${d['prazo']})' : ''}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPagamentoId = val),
                validator: (v) => v == null ? 'Selecione o pagamento' : null,
              ),
            ],

            const SizedBox(height: 20),

            // 3. Transportadora
            const Text('Transportadora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getTransportadorasStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final transps = snapshot.data!.docs;
                
                return DropdownButtonFormField<String>(
                  value: _selectedTransportadoraId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecione a Transportadora (Opcional)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: transps.map((doc) {
                    final d = doc.data();
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(d['razaoSocial'] ?? 'Sem Nome'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    final doc = transps.firstWhere((c) => c.id == val);
                    setState(() {
                      _selectedTransportadoraId = val;
                      _selectedTransportadoraData = doc.data();
                    });
                  },
                );
              },
            ),

            const Divider(height: 40, thickness: 2),

            // 4. ITENS DO PEDIDO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Produtos do Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_selectedRepresentadaId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Produto'),
                    onPressed: () {
                      _mostrarModalProdutos(context);
                    },
                  ),
              ],
            ),
            if (_selectedRepresentadaId == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Selecione uma representada para adicionar produtos.', style: TextStyle(color: Colors.grey)),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _itensPedido.length,
              itemBuilder: (context, index) {
                final item = _itensPedido[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('${item['codigo']} - ${item['nome']}'),
                    subtitle: Text(
                      '${formatter.format(item['precoTabela'])} x ${item['quantidade']} = ${formatter.format(item['total'])}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _atualizarQtdItem(index, (item['quantidade'] as int) - 1),
                        ),
                        Text('${item['quantidade']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _atualizarQtdItem(index, (item['quantidade'] as int) + 1),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removerItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Modal para selecionar produtos com PESQUISA
  void _mostrarModalProdutos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return _ModalProdutos(
              produtos: _produtosDisponiveis,
              onSelect: (produto, docId) {
                _adicionarProdutoNoCarrinho(produto, docId);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}

// Widget separado para o modal de produtos para gerenciar estado da busca local
class _ModalProdutos extends StatefulWidget {
  final List<QueryDocumentSnapshot> produtos;
  final Function(Map<String, dynamic>, String) onSelect;

  const _ModalProdutos({required this.produtos, required this.onSelect});

  @override
  State<_ModalProdutos> createState() => _ModalProdutosState();
}

class _ModalProdutosState extends State<_ModalProdutos> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.produtos.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final nome = (d['nome'] ?? '').toString().toLowerCase();
      final codigo = (d['codigo'] ?? '').toString().toLowerCase();
      final s = _searchQuery.toLowerCase();
      return nome.contains(s) || codigo.contains(s);
    }).toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Selecione um Produto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Pesquisar por nome ou código...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Nenhum produto encontrado.'))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');

                    return ListTile(
                      title: Text('${d['codigo']} - ${d['nome']}'),
                      subtitle: Text(formatter.format(d['preco'] ?? 0)),
                      onTap: () => widget.onSelect(d, doc.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
