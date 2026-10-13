import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/providers.dart';

final veiculosAtivosProvider = StreamProvider<List<Veiculo>>(
  (ref) => ref.watch(veiculosDaoProvider).watchAtivos(),
);

final veiculosArquivadosProvider = StreamProvider<List<Veiculo>>(
  (ref) => ref.watch(veiculosDaoProvider).watchArquivados(),
);
