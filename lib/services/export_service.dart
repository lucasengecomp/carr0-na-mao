// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/daos/abastecimentos_dao.dart';
import '../data/database/daos/despesas_dao.dart';
import '../data/database/daos/lembretes_dao.dart';
import '../data/database/daos/manutencoes_dao.dart';
import '../data/providers.dart';

/// Serviço responsável por exportar os dados de um veículo em 5 arquivos CSV.
///
/// Formato:
/// - UTF-8 com BOM (para compatibilidade com Excel no Windows).
/// - Delimitador: vírgula.
/// - Decimais com ponto.
/// - Datas no formato `yyyy-MM-dd`.
/// - Células com vírgula, aspas ou quebra de linha são envoltas em aspas duplas;
///   aspas internas são escapadas como `""`.
class ExportService {
  ExportService({
    required AbastecimentosDao abastecimentosDao,
    required ManutencoesDao manutencoesDao,
    required DespesasRecorrentesDao despesasDao,
    required OcorrenciasDespesaDao ocorrenciasDao,
    required LembretesDao lembretesDao,

    /// Provedor de diretório temporário; substitua em testes para evitar
    /// dependência da plataforma.
    Future<Directory> Function()? tempDirProvider,
  }) : _abastecimentosDao = abastecimentosDao,
       _manutencoesDao = manutencoesDao,
       _despesasDao = despesasDao,
       _ocorrenciasDao = ocorrenciasDao,
       _lembretesDao = lembretesDao,
       _tempDirProvider = tempDirProvider ?? getTemporaryDirectory;

  final AbastecimentosDao _abastecimentosDao;
  final ManutencoesDao _manutencoesDao;
  final DespesasRecorrentesDao _despesasDao;
  final OcorrenciasDespesaDao _ocorrenciasDao;
  final LembretesDao _lembretesDao;
  final Future<Directory> Function() _tempDirProvider;

  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  // UTF-8 BOM bytes
  static final List<int> _bom = [0xEF, 0xBB, 0xBF];

  /// Exporta todos os dados do veículo identificado por [placa] e retorna
  /// uma lista de [XFile] prontos para compartilhamento via `SharePlus`.
  ///
  /// Os arquivos são gravados em um diretório temporário exclusivo para esta
  /// exportação: `<tmpDir>/export_<placa>_<timestamp>/`.
  Future<List<XFile>> exportarVeiculo(String placa) async {
    final tmpDir = await _tempDirProvider();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final exportDir = Directory('${tmpDir.path}/export_${placa}_$ts');
    await exportDir.create(recursive: true);

    final files = await Future.wait([
      _gerarAbastecimentos(placa, exportDir),
      _gerarManutencoes(placa, exportDir),
      _gerarDespesas(placa, exportDir),
      _gerarOcorrencias(placa, exportDir),
      _gerarLembretes(placa, exportDir),
    ]);

    return files.map((f) => XFile(f.path, mimeType: 'text/csv')).toList();
  }

  // ── Abastecimentos ──────────────────────────────────────────────────────────

  Future<File> _gerarAbastecimentos(String placa, Directory dir) async {
    final rows = await _abastecimentosDao.listByVeiculo(placa);
    final lines = <String>[
      'data,km,tipo_combustivel,litros,preco,valor,posto,tanque_cheio,observacoes',
      ...rows.map(
        (r) => _row([
          _date(r.data),
          r.km.toString(),
          r.tipoCombustivel.name,
          _dec(r.litros),
          _dec(r.precoLitro),
          _dec(r.valorTotal),
          r.posto ?? '',
          r.tanqueCheio ? 'true' : 'false',
          '', // Abastecimentos não têm coluna observacoes na tabela
        ]),
      ),
    ];
    return _write(dir, 'abastecimentos.csv', lines);
  }

  // ── Manutenções ─────────────────────────────────────────────────────────────

  Future<File> _gerarManutencoes(String placa, Directory dir) async {
    final rows = await _manutencoesDao.listByVeiculo(placa);
    final lines = <String>[
      'data,tipo,nome_livre,km,valor,oficina,observacoes',
      ...rows.map(
        (r) => _row([
          _date(r.data),
          r.tipo.name,
          r.nomeLivre ?? '',
          r.km.toString(),
          r.valor != null ? _dec(r.valor!) : '',
          r.oficina ?? '',
          r.observacoes ?? '',
        ]),
      ),
    ];
    return _write(dir, 'manutencoes.csv', lines);
  }

  // ── Despesas recorrentes ─────────────────────────────────────────────────────

  Future<File> _gerarDespesas(String placa, Directory dir) async {
    final rows = await _despesasDao.listByVeiculo(placa);
    final lines = <String>[
      'nome,categoria,valor,frequencia,dia_do_mes,data_inicio,data_fim,ativa',
      ...rows.map(
        (r) => _row([
          r.nome,
          r.categoria.name,
          _dec(r.valor),
          r.frequencia.name,
          r.diaDoMes?.toString() ?? '',
          _date(r.dataInicio),
          r.dataFim != null ? _date(r.dataFim!) : '',
          r.ativa ? 'true' : 'false',
        ]),
      ),
    ];
    return _write(dir, 'despesas.csv', lines);
  }

  // ── Ocorrências de despesa ───────────────────────────────────────────────────

  Future<File> _gerarOcorrencias(String placa, Directory dir) async {
    // Busca despesas do veículo para obter nomes e ids.
    final despesas = await _despesasDao.listByVeiculo(placa);
    final despesaById = {for (final d in despesas) d.id: d};

    final lines = <String>[
      'despesa_nome,data_vencimento,valor,status,data_pagamento,valor_pago',
    ];

    for (final despesa in despesas) {
      final ocorrencias = await _ocorrenciasDao.listByDespesa(despesa.id);
      for (final o in ocorrencias) {
        final nome = despesaById[o.despesaId]?.nome ?? '';
        lines.add(
          _row([
            nome,
            _date(o.dataVencimento),
            _dec(despesa.valor),
            o.status.name,
            o.dataPagamento != null ? _date(o.dataPagamento!) : '',
            o.valorPago != null ? _dec(o.valorPago!) : '',
          ]),
        );
      }
    }

    return _write(dir, 'ocorrencias.csv', lines);
  }

  // ── Lembretes ────────────────────────────────────────────────────────────────

  Future<File> _gerarLembretes(String placa, Directory dir) async {
    final rows = await _lembretesDao.listByVeiculo(placa);
    final lines = <String>[
      'tipo,descricao,data_alvo,km_alvo,status',
      ...rows.map(
        (r) => _row([
          r.tipo,
          r.descricao,
          r.dataAlvo != null ? _date(r.dataAlvo!) : '',
          r.kmAlvo?.toString() ?? '',
          r.status.name,
        ]),
      ),
    ];
    return _write(dir, 'lembretes.csv', lines);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Escreve [lines] como CSV UTF-8 com BOM em [dir]/[filename].
  Future<File> _write(Directory dir, String filename, List<String> lines) {
    final content = '${lines.join('\n')}\n';
    final bytes = _bom + utf8.encode(content);
    return File('${dir.path}/$filename').writeAsBytes(bytes, flush: true);
  }

  /// Formata uma célula CSV: envolve em aspas duplas se contém `,`, `"` ou
  /// `\n`; escapa aspas internas como `""`.
  static String _cell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Constrói uma linha CSV a partir de uma lista de valores.
  static String _row(List<String> values) => values.map(_cell).join(',');

  /// Formata um [DateTime] como `yyyy-MM-dd`.
  static String _date(DateTime d) => _dateFmt.format(d);

  /// Formata um número decimal usando ponto como separador.
  static String _dec(double v) => v.toStringAsFixed(2);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    abastecimentosDao: ref.watch(abastecimentosDaoProvider),
    manutencoesDao: ref.watch(manutencoesDaoProvider),
    despesasDao: ref.watch(despesasRecorrentesDaoProvider),
    ocorrenciasDao: ref.watch(ocorrenciasDespesaDaoProvider),
    lembretesDao: ref.watch(lembretesDaoProvider),
  );
});
