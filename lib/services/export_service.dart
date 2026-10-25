// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/abastecimentos_dao.dart';
import '../data/database/daos/despesas_dao.dart';
import '../data/database/daos/lembretes_dao.dart';
import '../data/database/daos/manutencoes_dao.dart';
import '../data/providers.dart';
import 'export_labels.dart';

/// Formato de saída para exportação.
enum ExportFormat { xlsx, zip }

/// Serviço responsável por exportar os dados de um veículo.
///
/// Formatos suportados:
/// - **XLSX** — um arquivo `.xlsx` com 5 sheets (um por tabela).
/// - **ZIP** — um arquivo `.zip` com 5 CSVs.
///
/// Regras comuns a ambos os formatos:
/// - UTF-8 com BOM nos CSVs (para compatibilidade com Excel no Windows).
/// - Delimitador CSV: vírgula.
/// - Decimais com ponto.
/// - Datas no formato `yyyy-MM-dd`.
/// - Células CSV com vírgula, aspas ou quebra de linha são envoltas em aspas
///   duplas; aspas internas são escapadas como `""`.
/// - Enums → label PT-BR (via [export_labels.dart]).
/// - Booleanos → `Sim` / `Não`.
/// - Headers em PT-BR com acentos.
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

  // ── Nomes canônicos ──────────────────────────────────────────────────────────

  static const _sheetAbastecimentos = 'Abastecimentos';
  static const _sheetManutencoes = 'Manutenções';
  static const _sheetDespesas = 'Despesas';
  static const _sheetOcorrencias = 'Ocorrências';
  static const _sheetLembretes = 'Lembretes';

  static const _csvAbastecimentos = 'abastecimentos.csv';
  static const _csvManutencoes = 'manutencoes.csv';
  static const _csvDespesas = 'despesas.csv';
  static const _csvOcorrencias = 'ocorrencias.csv';
  static const _csvLembretes = 'lembretes.csv';

  // ── Headers PT-BR ────────────────────────────────────────────────────────────

  static const _headersAbastecimentos = [
    'Data',
    'Km',
    'Tipo de combustível',
    'Litros',
    'Preço por litro',
    'Valor total',
    'Posto',
    'Tanque cheio',
  ];

  static const _headersManutencoes = [
    'Data',
    'Tipo',
    'Descrição',
    'Km',
    'Valor',
    'Oficina',
    'Observações',
  ];

  static const _headersDespesas = [
    'Nome',
    'Categoria',
    'Valor',
    'Frequência',
    'Dia do mês',
    'Data de início',
    'Data de fim',
    'Ativa',
  ];

  static const _headersOcorrencias = [
    'Despesa',
    'Data de vencimento',
    'Valor',
    'Status',
    'Data de pagamento',
    'Valor pago',
  ];

  static const _headersLembretes = [
    'Tipo',
    'Descrição',
    'Data alvo',
    'Km alvo',
    'Status',
  ];

  // ── API pública ──────────────────────────────────────────────────────────────

  /// Exporta todos os dados do veículo identificado por [placa] no formato
  /// escolhido via [format], retornando um único [XFile].
  Future<XFile> exportarVeiculo(
    String placa, {
    ExportFormat format = ExportFormat.xlsx,
  }) async {
    return switch (format) {
      ExportFormat.xlsx => exportarVeiculoXlsx(placa),
      ExportFormat.zip => exportarVeiculoZip(placa),
    };
  }

  /// Gera um `.xlsx` com 5 sheets para o veículo identificado por [placa].
  Future<XFile> exportarVeiculoXlsx(String placa) async {
    final tmpDir = await _tempDirProvider();
    final date = _dateFmt.format(DateTime.now());
    final filename = 'carro-na-mao-$placa-$date.xlsx';
    final filePath = '${tmpDir.path}/$filename';

    final excel = Excel.createExcel();

    await _preencherSheetAbastecimentos(excel, placa);
    await _preencherSheetManutencoes(excel, placa);
    await _preencherSheetDespesas(excel, placa);
    await _preencherSheetOcorrencias(excel, placa);
    await _preencherSheetLembretes(excel, placa);

    // Remove a sheet padrão criada pelo Excel.createExcel() — precisa ser feito
    // depois de adicionar pelo menos uma outra sheet (delete exige length > 1).
    excel.delete('Sheet1');

    final bytes = excel.encode();
    if (bytes == null) throw StateError('Falha ao serializar o arquivo XLSX.');

    await File(filePath).writeAsBytes(bytes, flush: true);
    return XFile(
      filePath,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  /// Gera um `.zip` com 5 CSVs para o veículo identificado por [placa].
  Future<XFile> exportarVeiculoZip(String placa) async {
    final tmpDir = await _tempDirProvider();
    final date = _dateFmt.format(DateTime.now());
    final filename = 'carro-na-mao-$placa-$date.zip';
    final filePath = '${tmpDir.path}/$filename';

    final csvAbast = _buildCsvAbastecimentos(
      await _abastecimentosDao.listByVeiculo(placa),
    );
    final csvManut = _buildCsvManutencoes(
      await _manutencoesDao.listByVeiculo(placa),
    );
    final csvDesp = _buildCsvDespesas(await _despesasDao.listByVeiculo(placa));
    final csvOcorr = await _buildCsvOcorrencias(placa);
    final csvLemb = _buildCsvLembretes(
      await _lembretesDao.listByVeiculo(placa),
    );

    final archive = Archive()
      ..addFile(_archiveFile(_csvAbastecimentos, csvAbast))
      ..addFile(_archiveFile(_csvManutencoes, csvManut))
      ..addFile(_archiveFile(_csvDespesas, csvDesp))
      ..addFile(_archiveFile(_csvOcorrencias, csvOcorr))
      ..addFile(_archiveFile(_csvLembretes, csvLemb));

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Falha ao serializar o arquivo ZIP.');
    }

    await File(filePath).writeAsBytes(zipBytes, flush: true);
    return XFile(filePath, mimeType: 'application/zip');
  }

  // ── Sheets XLSX ──────────────────────────────────────────────────────────────

  Future<void> _preencherSheetAbastecimentos(Excel excel, String placa) async {
    final sheet = excel[_sheetAbastecimentos];
    sheet.appendRow(_headersAbastecimentos.map(TextCellValue.new).toList());
    for (final r in await _abastecimentosDao.listByVeiculo(placa)) {
      sheet.appendRow([
        TextCellValue(_date(r.data)),
        IntCellValue(r.km),
        TextCellValue(r.tipoCombustivel.labelPt),
        DoubleCellValue(r.litros),
        DoubleCellValue(r.precoLitro),
        DoubleCellValue(r.valorTotal),
        TextCellValue(r.posto ?? ''),
        TextCellValue(_bool(r.tanqueCheio)),
      ]);
    }
  }

  Future<void> _preencherSheetManutencoes(Excel excel, String placa) async {
    final sheet = excel[_sheetManutencoes];
    sheet.appendRow(_headersManutencoes.map(TextCellValue.new).toList());
    for (final r in await _manutencoesDao.listByVeiculo(placa)) {
      sheet.appendRow([
        TextCellValue(_date(r.data)),
        TextCellValue(r.tipo.labelPt),
        TextCellValue(r.nomeLivre ?? ''),
        IntCellValue(r.km),
        if (r.valor != null) DoubleCellValue(r.valor!) else TextCellValue(''),
        TextCellValue(r.oficina ?? ''),
        TextCellValue(r.observacoes ?? ''),
      ]);
    }
  }

  Future<void> _preencherSheetDespesas(Excel excel, String placa) async {
    final sheet = excel[_sheetDespesas];
    sheet.appendRow(_headersDespesas.map(TextCellValue.new).toList());
    for (final r in await _despesasDao.listByVeiculo(placa)) {
      sheet.appendRow([
        TextCellValue(r.nome),
        TextCellValue(r.categoria.labelPt),
        DoubleCellValue(r.valor),
        TextCellValue(r.frequencia.labelPt),
        TextCellValue(r.diaDoMes?.toString() ?? ''),
        TextCellValue(_date(r.dataInicio)),
        TextCellValue(r.dataFim != null ? _date(r.dataFim!) : ''),
        TextCellValue(_bool(r.ativa)),
      ]);
    }
  }

  Future<void> _preencherSheetOcorrencias(Excel excel, String placa) async {
    final sheet = excel[_sheetOcorrencias];
    sheet.appendRow(_headersOcorrencias.map(TextCellValue.new).toList());

    final despesas = await _despesasDao.listByVeiculo(placa);
    final despesaById = {for (final d in despesas) d.id: d};

    for (final despesa in despesas) {
      for (final o in await _ocorrenciasDao.listByDespesa(despesa.id)) {
        final nome = despesaById[o.despesaId]?.nome ?? '';
        sheet.appendRow([
          TextCellValue(nome),
          TextCellValue(_date(o.dataVencimento)),
          DoubleCellValue(despesa.valor),
          TextCellValue(o.status.labelPt),
          TextCellValue(o.dataPagamento != null ? _date(o.dataPagamento!) : ''),
          if (o.valorPago != null)
            DoubleCellValue(o.valorPago!)
          else
            TextCellValue(''),
        ]);
      }
    }
  }

  Future<void> _preencherSheetLembretes(Excel excel, String placa) async {
    final sheet = excel[_sheetLembretes];
    sheet.appendRow(_headersLembretes.map(TextCellValue.new).toList());
    for (final r in await _lembretesDao.listByVeiculo(placa)) {
      sheet.appendRow([
        TextCellValue(r.tipo),
        TextCellValue(r.descricao),
        TextCellValue(r.dataAlvo != null ? _date(r.dataAlvo!) : ''),
        TextCellValue(r.kmAlvo?.toString() ?? ''),
        TextCellValue(r.status.labelPt),
      ]);
    }
  }

  // ── Construtores CSV ─────────────────────────────────────────────────────────

  String _buildCsvAbastecimentos(List<Abastecimento> rows) {
    final lines = <String>[
      _row(_headersAbastecimentos),
      ...rows.map(
        (r) => _row([
          _date(r.data),
          r.km.toString(),
          r.tipoCombustivel.labelPt,
          _dec(r.litros),
          _dec(r.precoLitro),
          _dec(r.valorTotal),
          r.posto ?? '',
          _bool(r.tanqueCheio),
        ]),
      ),
    ];
    return '${lines.join('\n')}\n';
  }

  String _buildCsvManutencoes(List<Manutencao> rows) {
    final lines = <String>[
      _row(_headersManutencoes),
      ...rows.map(
        (r) => _row([
          _date(r.data),
          r.tipo.labelPt,
          r.nomeLivre ?? '',
          r.km.toString(),
          r.valor != null ? _dec(r.valor!) : '',
          r.oficina ?? '',
          r.observacoes ?? '',
        ]),
      ),
    ];
    return '${lines.join('\n')}\n';
  }

  String _buildCsvDespesas(List<DespesaRecorrente> rows) {
    final lines = <String>[
      _row(_headersDespesas),
      ...rows.map(
        (r) => _row([
          r.nome,
          r.categoria.labelPt,
          _dec(r.valor),
          r.frequencia.labelPt,
          r.diaDoMes?.toString() ?? '',
          _date(r.dataInicio),
          r.dataFim != null ? _date(r.dataFim!) : '',
          _bool(r.ativa),
        ]),
      ),
    ];
    return '${lines.join('\n')}\n';
  }

  Future<String> _buildCsvOcorrencias(String placa) async {
    final despesas = await _despesasDao.listByVeiculo(placa);
    final despesaById = {for (final d in despesas) d.id: d};

    final lines = <String>[_row(_headersOcorrencias)];

    for (final despesa in despesas) {
      for (final o in await _ocorrenciasDao.listByDespesa(despesa.id)) {
        final nome = despesaById[o.despesaId]?.nome ?? '';
        lines.add(
          _row([
            nome,
            _date(o.dataVencimento),
            _dec(despesa.valor),
            o.status.labelPt,
            o.dataPagamento != null ? _date(o.dataPagamento!) : '',
            o.valorPago != null ? _dec(o.valorPago!) : '',
          ]),
        );
      }
    }
    return '${lines.join('\n')}\n';
  }

  String _buildCsvLembretes(List<Lembrete> rows) {
    final lines = <String>[
      _row(_headersLembretes),
      ...rows.map(
        (r) => _row([
          r.tipo,
          r.descricao,
          r.dataAlvo != null ? _date(r.dataAlvo!) : '',
          r.kmAlvo?.toString() ?? '',
          r.status.labelPt,
        ]),
      ),
    ];
    return '${lines.join('\n')}\n';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Cria um [ArchiveFile] com conteúdo CSV UTF-8 com BOM.
  static ArchiveFile _archiveFile(String filename, String csvContent) {
    final bytes = _bom + utf8.encode(csvContent);
    return ArchiveFile(filename, bytes.length, bytes);
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

  /// Converte um booleano em label PT-BR.
  static String _bool(bool v) => v ? 'Sim' : 'Não';
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
