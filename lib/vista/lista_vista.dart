import 'package:flutter/material.dart';
import 'package:cancionero/componentes/menu_drawer.dart';

class ListaVista extends StatefulWidget {
  const ListaVista({super.key});

  @override
  State<ListaVista> createState() => _ListaVistaState();
}

class _ListaVistaState extends State<ListaVista> {
  final List<String> elementos = [
    'Elemento 1',
    'Elemento 2',
    'Elemento 3',
    'Elemento 4',
    'Elemento 5',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Elementos'),
      ),
      drawer: const MenuDrawer(),
      body: ListView.builder(
        itemCount: elementos.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Icon(Icons.music_note),
              title: Text(elementos[index]),
              subtitle: Text('Descripción del ${elementos[index]}'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seleccionaste: ${elementos[index]}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
