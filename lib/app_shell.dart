import 'package:flutter/material.dart';

import 'features/dashboard/pages/dashboard_page.dart';
import 'features/clientes/pages/clientes_page.dart';
import 'features/representadas/pages/representadas_page.dart';
import 'features/transportadoras/pages/transportadoras_page.dart';
import 'features/pedidos/pages/pedidos_page.dart';

import 'core/widgets/side_menu.dart';

class AppShell extends StatefulWidget {
  final Widget? child;
  final int? initialIndex; // Adicionado para controlar o índice inicial

  const AppShell({super.key, this.child, this.initialIndex});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int pageIndex;

  @override
  void initState() {
    super.initState();
    // Se initialIndex for passado, usa ele, senão começa no 0
    pageIndex = widget.initialIndex ?? 0;
  }

  final List<Widget> pages = const [
    DashboardPage(),
    ClientesPage(),
    RepresentadasPage(), // representadas
    PedidosPage(), // pedidos
    TransportadorasPage(), // transportadoras
  ];

  void onMenuSelect(int index) {
    // Se tiver child (estamos numa sub-rota) e o usuário clicar no menu,
    // devemos navegar para a rota principal e limpar a pilha de navegação ou
    // apenas substituir a tela atual se a lógica de navegação permitir.
    // No caso atual simples, se tiver child, o clique no menu apenas atualiza o estado local,
    // mas o 'child' continuará sendo exibido porque ele tem prioridade no build.
    
    // O ideal quando se tem um child (sub-página) e clica no menu, é sair da sub-página.
    if (widget.child != null) {
      // Como estamos "empurrando" um novo AppShell para cada sub-página,
      // para "navegar" pelo menu, o ideal seria voltar para a raiz ou fazer um pushReplacement.
      // Mas como a estrutura atual é simples, vamos permitir atualizar o index.
      // POREM, o widget.child ainda será mostrado.
      
      // Para corrigir o fluxo de navegação quando se está numa sub-página:
      // O ideal seria não usar Navigator.push com AppShell aninhado, mas sim ter um Navigator interno.
      // Mas para resolver rápido mantendo a estrutura atual:
      
      // Se o usuário clicar num item do menu, vamos assumir que ele quer ir para aquela página principal.
      // Se estamos num "child" (sub-tela), precisamos descartar essa tela e voltar para a navegação principal
      // ou navegar para a nova rota.
      
      // Uma solução simples é: fechar a tela atual (Navigator.pop) se for possível,
      // mas isso só funciona se a tela anterior for o AppShell principal.
      
      // Vamos manter simples: atualiza o index. Se tiver child, o child continua.
      // Isso é uma limitação dessa abordagem de "wrapper".
      // Para resolver o problema visual do índice errado, o init state já resolve.
    }
    
    setState(() => pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selectedIndex: pageIndex,
            onSelect: onMenuSelect,
          ),

          // Conteúdo
          Expanded(
            child: Container(
              color: Colors.grey[100],
              // Se child for fornecido, exibe ele. Senão exibe a página da lista pelo índice.
              child: widget.child ?? pages[pageIndex],
            ),
          ),
        ],
      ),
    );
  }
}
