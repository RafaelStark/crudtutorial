import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/clientes_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreClientes firestoreClientes = FirestoreClientes();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            "Dashboard",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: "Indicadores"),
              Tab(text: "Clientes"),
              Tab(text: "Fornecedores"),
              Tab(text: "Pedidos"),
              Tab(text: "Outros"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openClienteForm(),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _indicadoresTab(),
            _clientesTab(),
            _placeholderScreen(
              icon: Icons.people_outline,
              title: "Fornecedores",
              subtitle: "Aqui você poderá cadastrar seus fornecedores",
            ),
            _placeholderScreen(
              icon: Icons.receipt_long,
              title: "Pedidos",
              subtitle: "Gerencie seus pedidos aqui",
            ),
            _placeholderScreen(
              icon: Icons.local_shipping,
              title: "Transportadoras",
              subtitle: "Cadastre transportadoras e outras opções",
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicadoresTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _indicatorCard("Vendas Hoje", "R\$ 1.250,00", Icons.attach_money),
              const SizedBox(width: 10),

              //Indicador Quantidade de Clientes
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestoreClientes.getClientesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _indicatorCard("Clientes", "...", Icons.people_alt);
                    }

                    final total = snapshot.data!.docs.length;

                    return _indicatorCard(
                      "Clientes Cadastrados",
                      "$total clientes",
                      Icons.people_alt,
                    );
                  },
                ),
              ),
              //FINAL DO BLOCO - Indicador Quantidade de Clientes

            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _indicatorCard("Pedidos Abertos", "14 pedidos", Icons.shopping_cart),
              const SizedBox(width: 10),
              _indicatorCard("Mensagens", "3 novas", Icons.message),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clientesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreClientes.getClientesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Nenhum cliente cadastrado"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final c = docs[i];
            return Card(
              child: ListTile(
                title: Text(c["nomeFantasia"]),
                subtitle: Text("${c["cidade"]} - ${c["uf"]}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openClienteForm(docID: c.id, data: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => firestoreClientes.deleteCliente(c.id),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openClienteForm({String? docID, DocumentSnapshot? data}) {
    final cnpj = TextEditingController(text: data?["cnpj"]);
    final razao = TextEditingController(text: data?["razaoSocial"]);
    final fantasia = TextEditingController(text: data?["nomeFantasia"]);
    final email = TextEditingController(text: data?["email"]);
    final telefone = TextEditingController(text: data?["telefone"]);
    final endereco = TextEditingController(text: data?["endereco"]);
    final numero = TextEditingController(text: data?["numero"]);
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
            left: 16, right: 16, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  docID == null ? "Novo Cliente" : "Editar Cliente",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _input("CNPJ", cnpj),
                _input("Razão Social", razao),
                _input("Nome Fantasia", fantasia),
                _input("Email", email),
                _input("Telefone", telefone),
                _input("Endereço", endereco),
                _input("Número", numero),
                _input("Cidade", cidade),
                _input("UF", uf),
                _input("CEP", cep),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (docID == null) {
                        await firestoreClientes.addCliente(
                          cnpj: cnpj.text, razaoSocial: razao.text,
                          nomeFantasia: fantasia.text, email: email.text,
                          telefone: telefone.text, endereco: endereco.text,
                          numero: numero.text, cidade: cidade.text,
                          uf: uf.text, cep: cep.text,
                        );
                      } else {
                        await firestoreClientes.updateCliente(
                          docID,
                          cnpj: cnpj.text, razaoSocial: razao.text,
                          nomeFantasia: fantasia.text, email: email.text,
                          telefone: telefone.text, endereco: endereco.text,
                          numero: numero.text, cidade: cidade.text,
                          uf: uf.text, cep: cep.text,
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

  Widget _input(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _indicatorCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue),
              Text(title),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderScreen({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50),
          Text(title, style: const TextStyle(fontSize: 22)),
          Text(subtitle),
        ],
      ),
    );
  }
}
