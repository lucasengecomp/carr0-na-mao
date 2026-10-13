import 'package:flutter/material.dart';

/// Scaffold padrão para seções ainda não implementadas. Vai sendo trocado
/// por telas reais à medida que cada issue de UI é fechada.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.titulo,
    required this.descricao,
    super.key,
  });

  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            descricao,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
