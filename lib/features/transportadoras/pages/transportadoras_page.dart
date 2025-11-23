import 'package:crudtutorial/core/widgets/custom_add_button.dart';
import 'package:flutter/material.dart';
import '../widgets/transportadora_list.dart';
import 'transportadora_form_page.dart';
import 'transportadora_detalhe_page.dart';

enum TransportadorasView { list, form, detalhe }

class TransportadorasPage extends StatefulWidget {
  const TransportadorasPage({super.key});

  @override
  State<TransportadorasPage> createState() => _TransportadorasPageState();
}

class _TransportadorasPageState extends State<TransportadorasPage> {
  TransportadorasView _currentView = TransportadorasView.list;
  String? _selectedId;

  void _openForm() {
    setState(() {
      _currentView = TransportadorasView.form;
      _selectedId = null;
    });
  }

  void _openDetalhe(String id) {
    setState(() {
      _currentView = TransportadorasView.detalhe;
      _selectedId = id;
    });
  }

  void _backToList() {
    setState(() {
      _currentView = TransportadorasView.list;
      _selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentView) {
      case TransportadorasView.form:
        return TransportadoraFormPage(onBack: _backToList, editId: _selectedId);
      case TransportadorasView.detalhe:
        return TransportadoraDetalhePage(id: _selectedId!, onBack: _backToList);
      case TransportadorasView.list:
      default:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Transportadoras",
                      style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  CustomAddButton(
                    onPressed: _openForm,
                    icon: Icons.add,
                    label: "Nova Transportadora",
                  ),
                ],
              ),
            ),
            Expanded(child: TransportadoraList(onTap: _openDetalhe)),
          ],
        );
    }
  }
}
