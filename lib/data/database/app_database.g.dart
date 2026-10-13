// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VeiculosTable extends Veiculos with TableInfo<$VeiculosTable, Veiculo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VeiculosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _placaMeta = const VerificationMeta('placa');
  @override
  late final GeneratedColumn<String> placa = GeneratedColumn<String>(
    'placa',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 7,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apelidoMeta = const VerificationMeta(
    'apelido',
  );
  @override
  late final GeneratedColumn<String> apelido = GeneratedColumn<String>(
    'apelido',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marcaMeta = const VerificationMeta('marca');
  @override
  late final GeneratedColumn<String> marca = GeneratedColumn<String>(
    'marca',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeloMeta = const VerificationMeta('modelo');
  @override
  late final GeneratedColumn<String> modelo = GeneratedColumn<String>(
    'modelo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anoMeta = const VerificationMeta('ano');
  @override
  late final GeneratedColumn<int> ano = GeneratedColumn<int>(
    'ano',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoVeiculo, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoVeiculo>($VeiculosTable.$convertertipo);
  @override
  late final GeneratedColumnWithTypeConverter<TipoCombustivelVeiculo, String>
  combustivel = GeneratedColumn<String>(
    'combustivel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TipoCombustivelVeiculo>($VeiculosTable.$convertercombustivel);
  static const VerificationMeta _kmInicialMeta = const VerificationMeta(
    'kmInicial',
  );
  @override
  late final GeneratedColumn<int> kmInicial = GeneratedColumn<int>(
    'km_inicial',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arquivadoMeta = const VerificationMeta(
    'arquivado',
  );
  @override
  late final GeneratedColumn<bool> arquivado = GeneratedColumn<bool>(
    'arquivado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("arquivado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    placa,
    apelido,
    marca,
    modelo,
    ano,
    tipo,
    combustivel,
    kmInicial,
    arquivado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'veiculos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Veiculo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('placa')) {
      context.handle(
        _placaMeta,
        placa.isAcceptableOrUnknown(data['placa']!, _placaMeta),
      );
    } else if (isInserting) {
      context.missing(_placaMeta);
    }
    if (data.containsKey('apelido')) {
      context.handle(
        _apelidoMeta,
        apelido.isAcceptableOrUnknown(data['apelido']!, _apelidoMeta),
      );
    }
    if (data.containsKey('marca')) {
      context.handle(
        _marcaMeta,
        marca.isAcceptableOrUnknown(data['marca']!, _marcaMeta),
      );
    } else if (isInserting) {
      context.missing(_marcaMeta);
    }
    if (data.containsKey('modelo')) {
      context.handle(
        _modeloMeta,
        modelo.isAcceptableOrUnknown(data['modelo']!, _modeloMeta),
      );
    } else if (isInserting) {
      context.missing(_modeloMeta);
    }
    if (data.containsKey('ano')) {
      context.handle(
        _anoMeta,
        ano.isAcceptableOrUnknown(data['ano']!, _anoMeta),
      );
    } else if (isInserting) {
      context.missing(_anoMeta);
    }
    if (data.containsKey('km_inicial')) {
      context.handle(
        _kmInicialMeta,
        kmInicial.isAcceptableOrUnknown(data['km_inicial']!, _kmInicialMeta),
      );
    } else if (isInserting) {
      context.missing(_kmInicialMeta);
    }
    if (data.containsKey('arquivado')) {
      context.handle(
        _arquivadoMeta,
        arquivado.isAcceptableOrUnknown(data['arquivado']!, _arquivadoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {placa};
  @override
  Veiculo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Veiculo(
      placa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}placa'],
      )!,
      apelido: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apelido'],
      ),
      marca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marca'],
      )!,
      modelo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modelo'],
      )!,
      ano: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ano'],
      )!,
      tipo: $VeiculosTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      combustivel: $VeiculosTable.$convertercombustivel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}combustivel'],
        )!,
      ),
      kmInicial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km_inicial'],
      )!,
      arquivado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}arquivado'],
      )!,
    );
  }

  @override
  $VeiculosTable createAlias(String alias) {
    return $VeiculosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoVeiculo, String, String> $convertertipo =
      const EnumNameConverter<TipoVeiculo>(TipoVeiculo.values);
  static JsonTypeConverter2<TipoCombustivelVeiculo, String, String>
  $convertercombustivel = const EnumNameConverter<TipoCombustivelVeiculo>(
    TipoCombustivelVeiculo.values,
  );
}

class Veiculo extends DataClass implements Insertable<Veiculo> {
  final String placa;
  final String? apelido;
  final String marca;
  final String modelo;
  final int ano;
  final TipoVeiculo tipo;
  final TipoCombustivelVeiculo combustivel;
  final int kmInicial;
  final bool arquivado;
  const Veiculo({
    required this.placa,
    this.apelido,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.tipo,
    required this.combustivel,
    required this.kmInicial,
    required this.arquivado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['placa'] = Variable<String>(placa);
    if (!nullToAbsent || apelido != null) {
      map['apelido'] = Variable<String>(apelido);
    }
    map['marca'] = Variable<String>(marca);
    map['modelo'] = Variable<String>(modelo);
    map['ano'] = Variable<int>(ano);
    {
      map['tipo'] = Variable<String>($VeiculosTable.$convertertipo.toSql(tipo));
    }
    {
      map['combustivel'] = Variable<String>(
        $VeiculosTable.$convertercombustivel.toSql(combustivel),
      );
    }
    map['km_inicial'] = Variable<int>(kmInicial);
    map['arquivado'] = Variable<bool>(arquivado);
    return map;
  }

  VeiculosCompanion toCompanion(bool nullToAbsent) {
    return VeiculosCompanion(
      placa: Value(placa),
      apelido: apelido == null && nullToAbsent
          ? const Value.absent()
          : Value(apelido),
      marca: Value(marca),
      modelo: Value(modelo),
      ano: Value(ano),
      tipo: Value(tipo),
      combustivel: Value(combustivel),
      kmInicial: Value(kmInicial),
      arquivado: Value(arquivado),
    );
  }

  factory Veiculo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Veiculo(
      placa: serializer.fromJson<String>(json['placa']),
      apelido: serializer.fromJson<String?>(json['apelido']),
      marca: serializer.fromJson<String>(json['marca']),
      modelo: serializer.fromJson<String>(json['modelo']),
      ano: serializer.fromJson<int>(json['ano']),
      tipo: $VeiculosTable.$convertertipo.fromJson(
        serializer.fromJson<String>(json['tipo']),
      ),
      combustivel: $VeiculosTable.$convertercombustivel.fromJson(
        serializer.fromJson<String>(json['combustivel']),
      ),
      kmInicial: serializer.fromJson<int>(json['kmInicial']),
      arquivado: serializer.fromJson<bool>(json['arquivado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'placa': serializer.toJson<String>(placa),
      'apelido': serializer.toJson<String?>(apelido),
      'marca': serializer.toJson<String>(marca),
      'modelo': serializer.toJson<String>(modelo),
      'ano': serializer.toJson<int>(ano),
      'tipo': serializer.toJson<String>(
        $VeiculosTable.$convertertipo.toJson(tipo),
      ),
      'combustivel': serializer.toJson<String>(
        $VeiculosTable.$convertercombustivel.toJson(combustivel),
      ),
      'kmInicial': serializer.toJson<int>(kmInicial),
      'arquivado': serializer.toJson<bool>(arquivado),
    };
  }

  Veiculo copyWith({
    String? placa,
    Value<String?> apelido = const Value.absent(),
    String? marca,
    String? modelo,
    int? ano,
    TipoVeiculo? tipo,
    TipoCombustivelVeiculo? combustivel,
    int? kmInicial,
    bool? arquivado,
  }) => Veiculo(
    placa: placa ?? this.placa,
    apelido: apelido.present ? apelido.value : this.apelido,
    marca: marca ?? this.marca,
    modelo: modelo ?? this.modelo,
    ano: ano ?? this.ano,
    tipo: tipo ?? this.tipo,
    combustivel: combustivel ?? this.combustivel,
    kmInicial: kmInicial ?? this.kmInicial,
    arquivado: arquivado ?? this.arquivado,
  );
  Veiculo copyWithCompanion(VeiculosCompanion data) {
    return Veiculo(
      placa: data.placa.present ? data.placa.value : this.placa,
      apelido: data.apelido.present ? data.apelido.value : this.apelido,
      marca: data.marca.present ? data.marca.value : this.marca,
      modelo: data.modelo.present ? data.modelo.value : this.modelo,
      ano: data.ano.present ? data.ano.value : this.ano,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      combustivel: data.combustivel.present
          ? data.combustivel.value
          : this.combustivel,
      kmInicial: data.kmInicial.present ? data.kmInicial.value : this.kmInicial,
      arquivado: data.arquivado.present ? data.arquivado.value : this.arquivado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Veiculo(')
          ..write('placa: $placa, ')
          ..write('apelido: $apelido, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('ano: $ano, ')
          ..write('tipo: $tipo, ')
          ..write('combustivel: $combustivel, ')
          ..write('kmInicial: $kmInicial, ')
          ..write('arquivado: $arquivado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    placa,
    apelido,
    marca,
    modelo,
    ano,
    tipo,
    combustivel,
    kmInicial,
    arquivado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Veiculo &&
          other.placa == this.placa &&
          other.apelido == this.apelido &&
          other.marca == this.marca &&
          other.modelo == this.modelo &&
          other.ano == this.ano &&
          other.tipo == this.tipo &&
          other.combustivel == this.combustivel &&
          other.kmInicial == this.kmInicial &&
          other.arquivado == this.arquivado);
}

class VeiculosCompanion extends UpdateCompanion<Veiculo> {
  final Value<String> placa;
  final Value<String?> apelido;
  final Value<String> marca;
  final Value<String> modelo;
  final Value<int> ano;
  final Value<TipoVeiculo> tipo;
  final Value<TipoCombustivelVeiculo> combustivel;
  final Value<int> kmInicial;
  final Value<bool> arquivado;
  final Value<int> rowid;
  const VeiculosCompanion({
    this.placa = const Value.absent(),
    this.apelido = const Value.absent(),
    this.marca = const Value.absent(),
    this.modelo = const Value.absent(),
    this.ano = const Value.absent(),
    this.tipo = const Value.absent(),
    this.combustivel = const Value.absent(),
    this.kmInicial = const Value.absent(),
    this.arquivado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VeiculosCompanion.insert({
    required String placa,
    this.apelido = const Value.absent(),
    required String marca,
    required String modelo,
    required int ano,
    required TipoVeiculo tipo,
    required TipoCombustivelVeiculo combustivel,
    required int kmInicial,
    this.arquivado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : placa = Value(placa),
       marca = Value(marca),
       modelo = Value(modelo),
       ano = Value(ano),
       tipo = Value(tipo),
       combustivel = Value(combustivel),
       kmInicial = Value(kmInicial);
  static Insertable<Veiculo> custom({
    Expression<String>? placa,
    Expression<String>? apelido,
    Expression<String>? marca,
    Expression<String>? modelo,
    Expression<int>? ano,
    Expression<String>? tipo,
    Expression<String>? combustivel,
    Expression<int>? kmInicial,
    Expression<bool>? arquivado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (placa != null) 'placa': placa,
      if (apelido != null) 'apelido': apelido,
      if (marca != null) 'marca': marca,
      if (modelo != null) 'modelo': modelo,
      if (ano != null) 'ano': ano,
      if (tipo != null) 'tipo': tipo,
      if (combustivel != null) 'combustivel': combustivel,
      if (kmInicial != null) 'km_inicial': kmInicial,
      if (arquivado != null) 'arquivado': arquivado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VeiculosCompanion copyWith({
    Value<String>? placa,
    Value<String?>? apelido,
    Value<String>? marca,
    Value<String>? modelo,
    Value<int>? ano,
    Value<TipoVeiculo>? tipo,
    Value<TipoCombustivelVeiculo>? combustivel,
    Value<int>? kmInicial,
    Value<bool>? arquivado,
    Value<int>? rowid,
  }) {
    return VeiculosCompanion(
      placa: placa ?? this.placa,
      apelido: apelido ?? this.apelido,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      tipo: tipo ?? this.tipo,
      combustivel: combustivel ?? this.combustivel,
      kmInicial: kmInicial ?? this.kmInicial,
      arquivado: arquivado ?? this.arquivado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (placa.present) {
      map['placa'] = Variable<String>(placa.value);
    }
    if (apelido.present) {
      map['apelido'] = Variable<String>(apelido.value);
    }
    if (marca.present) {
      map['marca'] = Variable<String>(marca.value);
    }
    if (modelo.present) {
      map['modelo'] = Variable<String>(modelo.value);
    }
    if (ano.present) {
      map['ano'] = Variable<int>(ano.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $VeiculosTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (combustivel.present) {
      map['combustivel'] = Variable<String>(
        $VeiculosTable.$convertercombustivel.toSql(combustivel.value),
      );
    }
    if (kmInicial.present) {
      map['km_inicial'] = Variable<int>(kmInicial.value);
    }
    if (arquivado.present) {
      map['arquivado'] = Variable<bool>(arquivado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VeiculosCompanion(')
          ..write('placa: $placa, ')
          ..write('apelido: $apelido, ')
          ..write('marca: $marca, ')
          ..write('modelo: $modelo, ')
          ..write('ano: $ano, ')
          ..write('tipo: $tipo, ')
          ..write('combustivel: $combustivel, ')
          ..write('kmInicial: $kmInicial, ')
          ..write('arquivado: $arquivado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AbastecimentosTable extends Abastecimentos
    with TableInfo<$AbastecimentosTable, Abastecimento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbastecimentosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _veiculoPlacaMeta = const VerificationMeta(
    'veiculoPlaca',
  );
  @override
  late final GeneratedColumn<String> veiculoPlaca = GeneratedColumn<String>(
    'veiculo_placa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES veiculos (placa) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmMeta = const VerificationMeta('km');
  @override
  late final GeneratedColumn<int> km = GeneratedColumn<int>(
    'km',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    TipoCombustivelAbastecimento,
    String
  >
  tipoCombustivel =
      GeneratedColumn<String>(
        'tipo_combustivel',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoCombustivelAbastecimento>(
        $AbastecimentosTable.$convertertipoCombustivel,
      );
  static const VerificationMeta _precoLitroMeta = const VerificationMeta(
    'precoLitro',
  );
  @override
  late final GeneratedColumn<double> precoLitro = GeneratedColumn<double>(
    'preco_litro',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorTotalMeta = const VerificationMeta(
    'valorTotal',
  );
  @override
  late final GeneratedColumn<double> valorTotal = GeneratedColumn<double>(
    'valor_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _litrosMeta = const VerificationMeta('litros');
  @override
  late final GeneratedColumn<double> litros = GeneratedColumn<double>(
    'litros',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postoMeta = const VerificationMeta('posto');
  @override
  late final GeneratedColumn<String> posto = GeneratedColumn<String>(
    'posto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tanqueCheioMeta = const VerificationMeta(
    'tanqueCheio',
  );
  @override
  late final GeneratedColumn<bool> tanqueCheio = GeneratedColumn<bool>(
    'tanque_cheio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tanque_cheio" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    veiculoPlaca,
    data,
    km,
    tipoCombustivel,
    precoLitro,
    valorTotal,
    litros,
    posto,
    tanqueCheio,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'abastecimentos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Abastecimento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('veiculo_placa')) {
      context.handle(
        _veiculoPlacaMeta,
        veiculoPlaca.isAcceptableOrUnknown(
          data['veiculo_placa']!,
          _veiculoPlacaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_veiculoPlacaMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('km')) {
      context.handle(_kmMeta, km.isAcceptableOrUnknown(data['km']!, _kmMeta));
    } else if (isInserting) {
      context.missing(_kmMeta);
    }
    if (data.containsKey('preco_litro')) {
      context.handle(
        _precoLitroMeta,
        precoLitro.isAcceptableOrUnknown(data['preco_litro']!, _precoLitroMeta),
      );
    } else if (isInserting) {
      context.missing(_precoLitroMeta);
    }
    if (data.containsKey('valor_total')) {
      context.handle(
        _valorTotalMeta,
        valorTotal.isAcceptableOrUnknown(data['valor_total']!, _valorTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_valorTotalMeta);
    }
    if (data.containsKey('litros')) {
      context.handle(
        _litrosMeta,
        litros.isAcceptableOrUnknown(data['litros']!, _litrosMeta),
      );
    } else if (isInserting) {
      context.missing(_litrosMeta);
    }
    if (data.containsKey('posto')) {
      context.handle(
        _postoMeta,
        posto.isAcceptableOrUnknown(data['posto']!, _postoMeta),
      );
    }
    if (data.containsKey('tanque_cheio')) {
      context.handle(
        _tanqueCheioMeta,
        tanqueCheio.isAcceptableOrUnknown(
          data['tanque_cheio']!,
          _tanqueCheioMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Abastecimento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Abastecimento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      veiculoPlaca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}veiculo_placa'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      km: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km'],
      )!,
      tipoCombustivel: $AbastecimentosTable.$convertertipoCombustivel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo_combustivel'],
        )!,
      ),
      precoLitro: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}preco_litro'],
      )!,
      valorTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor_total'],
      )!,
      litros: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}litros'],
      )!,
      posto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}posto'],
      ),
      tanqueCheio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tanque_cheio'],
      )!,
    );
  }

  @override
  $AbastecimentosTable createAlias(String alias) {
    return $AbastecimentosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoCombustivelAbastecimento, String, String>
  $convertertipoCombustivel =
      const EnumNameConverter<TipoCombustivelAbastecimento>(
        TipoCombustivelAbastecimento.values,
      );
}

class Abastecimento extends DataClass implements Insertable<Abastecimento> {
  final int id;
  final String veiculoPlaca;
  final DateTime data;
  final int km;
  final TipoCombustivelAbastecimento tipoCombustivel;
  final double precoLitro;
  final double valorTotal;
  final double litros;
  final String? posto;
  final bool tanqueCheio;
  const Abastecimento({
    required this.id,
    required this.veiculoPlaca,
    required this.data,
    required this.km,
    required this.tipoCombustivel,
    required this.precoLitro,
    required this.valorTotal,
    required this.litros,
    this.posto,
    required this.tanqueCheio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['veiculo_placa'] = Variable<String>(veiculoPlaca);
    map['data'] = Variable<DateTime>(data);
    map['km'] = Variable<int>(km);
    {
      map['tipo_combustivel'] = Variable<String>(
        $AbastecimentosTable.$convertertipoCombustivel.toSql(tipoCombustivel),
      );
    }
    map['preco_litro'] = Variable<double>(precoLitro);
    map['valor_total'] = Variable<double>(valorTotal);
    map['litros'] = Variable<double>(litros);
    if (!nullToAbsent || posto != null) {
      map['posto'] = Variable<String>(posto);
    }
    map['tanque_cheio'] = Variable<bool>(tanqueCheio);
    return map;
  }

  AbastecimentosCompanion toCompanion(bool nullToAbsent) {
    return AbastecimentosCompanion(
      id: Value(id),
      veiculoPlaca: Value(veiculoPlaca),
      data: Value(data),
      km: Value(km),
      tipoCombustivel: Value(tipoCombustivel),
      precoLitro: Value(precoLitro),
      valorTotal: Value(valorTotal),
      litros: Value(litros),
      posto: posto == null && nullToAbsent
          ? const Value.absent()
          : Value(posto),
      tanqueCheio: Value(tanqueCheio),
    );
  }

  factory Abastecimento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Abastecimento(
      id: serializer.fromJson<int>(json['id']),
      veiculoPlaca: serializer.fromJson<String>(json['veiculoPlaca']),
      data: serializer.fromJson<DateTime>(json['data']),
      km: serializer.fromJson<int>(json['km']),
      tipoCombustivel: $AbastecimentosTable.$convertertipoCombustivel.fromJson(
        serializer.fromJson<String>(json['tipoCombustivel']),
      ),
      precoLitro: serializer.fromJson<double>(json['precoLitro']),
      valorTotal: serializer.fromJson<double>(json['valorTotal']),
      litros: serializer.fromJson<double>(json['litros']),
      posto: serializer.fromJson<String?>(json['posto']),
      tanqueCheio: serializer.fromJson<bool>(json['tanqueCheio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'veiculoPlaca': serializer.toJson<String>(veiculoPlaca),
      'data': serializer.toJson<DateTime>(data),
      'km': serializer.toJson<int>(km),
      'tipoCombustivel': serializer.toJson<String>(
        $AbastecimentosTable.$convertertipoCombustivel.toJson(tipoCombustivel),
      ),
      'precoLitro': serializer.toJson<double>(precoLitro),
      'valorTotal': serializer.toJson<double>(valorTotal),
      'litros': serializer.toJson<double>(litros),
      'posto': serializer.toJson<String?>(posto),
      'tanqueCheio': serializer.toJson<bool>(tanqueCheio),
    };
  }

  Abastecimento copyWith({
    int? id,
    String? veiculoPlaca,
    DateTime? data,
    int? km,
    TipoCombustivelAbastecimento? tipoCombustivel,
    double? precoLitro,
    double? valorTotal,
    double? litros,
    Value<String?> posto = const Value.absent(),
    bool? tanqueCheio,
  }) => Abastecimento(
    id: id ?? this.id,
    veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
    data: data ?? this.data,
    km: km ?? this.km,
    tipoCombustivel: tipoCombustivel ?? this.tipoCombustivel,
    precoLitro: precoLitro ?? this.precoLitro,
    valorTotal: valorTotal ?? this.valorTotal,
    litros: litros ?? this.litros,
    posto: posto.present ? posto.value : this.posto,
    tanqueCheio: tanqueCheio ?? this.tanqueCheio,
  );
  Abastecimento copyWithCompanion(AbastecimentosCompanion data) {
    return Abastecimento(
      id: data.id.present ? data.id.value : this.id,
      veiculoPlaca: data.veiculoPlaca.present
          ? data.veiculoPlaca.value
          : this.veiculoPlaca,
      data: data.data.present ? data.data.value : this.data,
      km: data.km.present ? data.km.value : this.km,
      tipoCombustivel: data.tipoCombustivel.present
          ? data.tipoCombustivel.value
          : this.tipoCombustivel,
      precoLitro: data.precoLitro.present
          ? data.precoLitro.value
          : this.precoLitro,
      valorTotal: data.valorTotal.present
          ? data.valorTotal.value
          : this.valorTotal,
      litros: data.litros.present ? data.litros.value : this.litros,
      posto: data.posto.present ? data.posto.value : this.posto,
      tanqueCheio: data.tanqueCheio.present
          ? data.tanqueCheio.value
          : this.tanqueCheio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Abastecimento(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('data: $data, ')
          ..write('km: $km, ')
          ..write('tipoCombustivel: $tipoCombustivel, ')
          ..write('precoLitro: $precoLitro, ')
          ..write('valorTotal: $valorTotal, ')
          ..write('litros: $litros, ')
          ..write('posto: $posto, ')
          ..write('tanqueCheio: $tanqueCheio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    veiculoPlaca,
    data,
    km,
    tipoCombustivel,
    precoLitro,
    valorTotal,
    litros,
    posto,
    tanqueCheio,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Abastecimento &&
          other.id == this.id &&
          other.veiculoPlaca == this.veiculoPlaca &&
          other.data == this.data &&
          other.km == this.km &&
          other.tipoCombustivel == this.tipoCombustivel &&
          other.precoLitro == this.precoLitro &&
          other.valorTotal == this.valorTotal &&
          other.litros == this.litros &&
          other.posto == this.posto &&
          other.tanqueCheio == this.tanqueCheio);
}

class AbastecimentosCompanion extends UpdateCompanion<Abastecimento> {
  final Value<int> id;
  final Value<String> veiculoPlaca;
  final Value<DateTime> data;
  final Value<int> km;
  final Value<TipoCombustivelAbastecimento> tipoCombustivel;
  final Value<double> precoLitro;
  final Value<double> valorTotal;
  final Value<double> litros;
  final Value<String?> posto;
  final Value<bool> tanqueCheio;
  const AbastecimentosCompanion({
    this.id = const Value.absent(),
    this.veiculoPlaca = const Value.absent(),
    this.data = const Value.absent(),
    this.km = const Value.absent(),
    this.tipoCombustivel = const Value.absent(),
    this.precoLitro = const Value.absent(),
    this.valorTotal = const Value.absent(),
    this.litros = const Value.absent(),
    this.posto = const Value.absent(),
    this.tanqueCheio = const Value.absent(),
  });
  AbastecimentosCompanion.insert({
    this.id = const Value.absent(),
    required String veiculoPlaca,
    required DateTime data,
    required int km,
    required TipoCombustivelAbastecimento tipoCombustivel,
    required double precoLitro,
    required double valorTotal,
    required double litros,
    this.posto = const Value.absent(),
    this.tanqueCheio = const Value.absent(),
  }) : veiculoPlaca = Value(veiculoPlaca),
       data = Value(data),
       km = Value(km),
       tipoCombustivel = Value(tipoCombustivel),
       precoLitro = Value(precoLitro),
       valorTotal = Value(valorTotal),
       litros = Value(litros);
  static Insertable<Abastecimento> custom({
    Expression<int>? id,
    Expression<String>? veiculoPlaca,
    Expression<DateTime>? data,
    Expression<int>? km,
    Expression<String>? tipoCombustivel,
    Expression<double>? precoLitro,
    Expression<double>? valorTotal,
    Expression<double>? litros,
    Expression<String>? posto,
    Expression<bool>? tanqueCheio,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (veiculoPlaca != null) 'veiculo_placa': veiculoPlaca,
      if (data != null) 'data': data,
      if (km != null) 'km': km,
      if (tipoCombustivel != null) 'tipo_combustivel': tipoCombustivel,
      if (precoLitro != null) 'preco_litro': precoLitro,
      if (valorTotal != null) 'valor_total': valorTotal,
      if (litros != null) 'litros': litros,
      if (posto != null) 'posto': posto,
      if (tanqueCheio != null) 'tanque_cheio': tanqueCheio,
    });
  }

  AbastecimentosCompanion copyWith({
    Value<int>? id,
    Value<String>? veiculoPlaca,
    Value<DateTime>? data,
    Value<int>? km,
    Value<TipoCombustivelAbastecimento>? tipoCombustivel,
    Value<double>? precoLitro,
    Value<double>? valorTotal,
    Value<double>? litros,
    Value<String?>? posto,
    Value<bool>? tanqueCheio,
  }) {
    return AbastecimentosCompanion(
      id: id ?? this.id,
      veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
      data: data ?? this.data,
      km: km ?? this.km,
      tipoCombustivel: tipoCombustivel ?? this.tipoCombustivel,
      precoLitro: precoLitro ?? this.precoLitro,
      valorTotal: valorTotal ?? this.valorTotal,
      litros: litros ?? this.litros,
      posto: posto ?? this.posto,
      tanqueCheio: tanqueCheio ?? this.tanqueCheio,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (veiculoPlaca.present) {
      map['veiculo_placa'] = Variable<String>(veiculoPlaca.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (km.present) {
      map['km'] = Variable<int>(km.value);
    }
    if (tipoCombustivel.present) {
      map['tipo_combustivel'] = Variable<String>(
        $AbastecimentosTable.$convertertipoCombustivel.toSql(
          tipoCombustivel.value,
        ),
      );
    }
    if (precoLitro.present) {
      map['preco_litro'] = Variable<double>(precoLitro.value);
    }
    if (valorTotal.present) {
      map['valor_total'] = Variable<double>(valorTotal.value);
    }
    if (litros.present) {
      map['litros'] = Variable<double>(litros.value);
    }
    if (posto.present) {
      map['posto'] = Variable<String>(posto.value);
    }
    if (tanqueCheio.present) {
      map['tanque_cheio'] = Variable<bool>(tanqueCheio.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbastecimentosCompanion(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('data: $data, ')
          ..write('km: $km, ')
          ..write('tipoCombustivel: $tipoCombustivel, ')
          ..write('precoLitro: $precoLitro, ')
          ..write('valorTotal: $valorTotal, ')
          ..write('litros: $litros, ')
          ..write('posto: $posto, ')
          ..write('tanqueCheio: $tanqueCheio')
          ..write(')'))
        .toString();
  }
}

class $ManutencoesTable extends Manutencoes
    with TableInfo<$ManutencoesTable, Manutencao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManutencoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _veiculoPlacaMeta = const VerificationMeta(
    'veiculoPlaca',
  );
  @override
  late final GeneratedColumn<String> veiculoPlaca = GeneratedColumn<String>(
    'veiculo_placa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES veiculos (placa) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TipoManutencao, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoManutencao>($ManutencoesTable.$convertertipo);
  static const VerificationMeta _nomeLivreMeta = const VerificationMeta(
    'nomeLivre',
  );
  @override
  late final GeneratedColumn<String> nomeLivre = GeneratedColumn<String>(
    'nome_livre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<DateTime> data = GeneratedColumn<DateTime>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kmMeta = const VerificationMeta('km');
  @override
  late final GeneratedColumn<int> km = GeneratedColumn<int>(
    'km',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
    'valor',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oficinaMeta = const VerificationMeta(
    'oficina',
  );
  @override
  late final GeneratedColumn<String> oficina = GeneratedColumn<String>(
    'oficina',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacoesMeta = const VerificationMeta(
    'observacoes',
  );
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
    'observacoes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    veiculoPlaca,
    tipo,
    nomeLivre,
    data,
    km,
    valor,
    oficina,
    observacoes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manutencoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Manutencao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('veiculo_placa')) {
      context.handle(
        _veiculoPlacaMeta,
        veiculoPlaca.isAcceptableOrUnknown(
          data['veiculo_placa']!,
          _veiculoPlacaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_veiculoPlacaMeta);
    }
    if (data.containsKey('nome_livre')) {
      context.handle(
        _nomeLivreMeta,
        nomeLivre.isAcceptableOrUnknown(data['nome_livre']!, _nomeLivreMeta),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('km')) {
      context.handle(_kmMeta, km.isAcceptableOrUnknown(data['km']!, _kmMeta));
    } else if (isInserting) {
      context.missing(_kmMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    }
    if (data.containsKey('oficina')) {
      context.handle(
        _oficinaMeta,
        oficina.isAcceptableOrUnknown(data['oficina']!, _oficinaMeta),
      );
    }
    if (data.containsKey('observacoes')) {
      context.handle(
        _observacoesMeta,
        observacoes.isAcceptableOrUnknown(
          data['observacoes']!,
          _observacoesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Manutencao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Manutencao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      veiculoPlaca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}veiculo_placa'],
      )!,
      tipo: $ManutencoesTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      nomeLivre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome_livre'],
      ),
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data'],
      )!,
      km: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor'],
      ),
      oficina: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oficina'],
      ),
      observacoes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacoes'],
      ),
    );
  }

  @override
  $ManutencoesTable createAlias(String alias) {
    return $ManutencoesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoManutencao, String, String> $convertertipo =
      const EnumNameConverter<TipoManutencao>(TipoManutencao.values);
}

class Manutencao extends DataClass implements Insertable<Manutencao> {
  final int id;
  final String veiculoPlaca;
  final TipoManutencao tipo;
  final String? nomeLivre;
  final DateTime data;
  final int km;
  final double? valor;
  final String? oficina;
  final String? observacoes;
  const Manutencao({
    required this.id,
    required this.veiculoPlaca,
    required this.tipo,
    this.nomeLivre,
    required this.data,
    required this.km,
    this.valor,
    this.oficina,
    this.observacoes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['veiculo_placa'] = Variable<String>(veiculoPlaca);
    {
      map['tipo'] = Variable<String>(
        $ManutencoesTable.$convertertipo.toSql(tipo),
      );
    }
    if (!nullToAbsent || nomeLivre != null) {
      map['nome_livre'] = Variable<String>(nomeLivre);
    }
    map['data'] = Variable<DateTime>(data);
    map['km'] = Variable<int>(km);
    if (!nullToAbsent || valor != null) {
      map['valor'] = Variable<double>(valor);
    }
    if (!nullToAbsent || oficina != null) {
      map['oficina'] = Variable<String>(oficina);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    return map;
  }

  ManutencoesCompanion toCompanion(bool nullToAbsent) {
    return ManutencoesCompanion(
      id: Value(id),
      veiculoPlaca: Value(veiculoPlaca),
      tipo: Value(tipo),
      nomeLivre: nomeLivre == null && nullToAbsent
          ? const Value.absent()
          : Value(nomeLivre),
      data: Value(data),
      km: Value(km),
      valor: valor == null && nullToAbsent
          ? const Value.absent()
          : Value(valor),
      oficina: oficina == null && nullToAbsent
          ? const Value.absent()
          : Value(oficina),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
    );
  }

  factory Manutencao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Manutencao(
      id: serializer.fromJson<int>(json['id']),
      veiculoPlaca: serializer.fromJson<String>(json['veiculoPlaca']),
      tipo: $ManutencoesTable.$convertertipo.fromJson(
        serializer.fromJson<String>(json['tipo']),
      ),
      nomeLivre: serializer.fromJson<String?>(json['nomeLivre']),
      data: serializer.fromJson<DateTime>(json['data']),
      km: serializer.fromJson<int>(json['km']),
      valor: serializer.fromJson<double?>(json['valor']),
      oficina: serializer.fromJson<String?>(json['oficina']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'veiculoPlaca': serializer.toJson<String>(veiculoPlaca),
      'tipo': serializer.toJson<String>(
        $ManutencoesTable.$convertertipo.toJson(tipo),
      ),
      'nomeLivre': serializer.toJson<String?>(nomeLivre),
      'data': serializer.toJson<DateTime>(data),
      'km': serializer.toJson<int>(km),
      'valor': serializer.toJson<double?>(valor),
      'oficina': serializer.toJson<String?>(oficina),
      'observacoes': serializer.toJson<String?>(observacoes),
    };
  }

  Manutencao copyWith({
    int? id,
    String? veiculoPlaca,
    TipoManutencao? tipo,
    Value<String?> nomeLivre = const Value.absent(),
    DateTime? data,
    int? km,
    Value<double?> valor = const Value.absent(),
    Value<String?> oficina = const Value.absent(),
    Value<String?> observacoes = const Value.absent(),
  }) => Manutencao(
    id: id ?? this.id,
    veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
    tipo: tipo ?? this.tipo,
    nomeLivre: nomeLivre.present ? nomeLivre.value : this.nomeLivre,
    data: data ?? this.data,
    km: km ?? this.km,
    valor: valor.present ? valor.value : this.valor,
    oficina: oficina.present ? oficina.value : this.oficina,
    observacoes: observacoes.present ? observacoes.value : this.observacoes,
  );
  Manutencao copyWithCompanion(ManutencoesCompanion data) {
    return Manutencao(
      id: data.id.present ? data.id.value : this.id,
      veiculoPlaca: data.veiculoPlaca.present
          ? data.veiculoPlaca.value
          : this.veiculoPlaca,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      nomeLivre: data.nomeLivre.present ? data.nomeLivre.value : this.nomeLivre,
      data: data.data.present ? data.data.value : this.data,
      km: data.km.present ? data.km.value : this.km,
      valor: data.valor.present ? data.valor.value : this.valor,
      oficina: data.oficina.present ? data.oficina.value : this.oficina,
      observacoes: data.observacoes.present
          ? data.observacoes.value
          : this.observacoes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Manutencao(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('tipo: $tipo, ')
          ..write('nomeLivre: $nomeLivre, ')
          ..write('data: $data, ')
          ..write('km: $km, ')
          ..write('valor: $valor, ')
          ..write('oficina: $oficina, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    veiculoPlaca,
    tipo,
    nomeLivre,
    data,
    km,
    valor,
    oficina,
    observacoes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Manutencao &&
          other.id == this.id &&
          other.veiculoPlaca == this.veiculoPlaca &&
          other.tipo == this.tipo &&
          other.nomeLivre == this.nomeLivre &&
          other.data == this.data &&
          other.km == this.km &&
          other.valor == this.valor &&
          other.oficina == this.oficina &&
          other.observacoes == this.observacoes);
}

class ManutencoesCompanion extends UpdateCompanion<Manutencao> {
  final Value<int> id;
  final Value<String> veiculoPlaca;
  final Value<TipoManutencao> tipo;
  final Value<String?> nomeLivre;
  final Value<DateTime> data;
  final Value<int> km;
  final Value<double?> valor;
  final Value<String?> oficina;
  final Value<String?> observacoes;
  const ManutencoesCompanion({
    this.id = const Value.absent(),
    this.veiculoPlaca = const Value.absent(),
    this.tipo = const Value.absent(),
    this.nomeLivre = const Value.absent(),
    this.data = const Value.absent(),
    this.km = const Value.absent(),
    this.valor = const Value.absent(),
    this.oficina = const Value.absent(),
    this.observacoes = const Value.absent(),
  });
  ManutencoesCompanion.insert({
    this.id = const Value.absent(),
    required String veiculoPlaca,
    required TipoManutencao tipo,
    this.nomeLivre = const Value.absent(),
    required DateTime data,
    required int km,
    this.valor = const Value.absent(),
    this.oficina = const Value.absent(),
    this.observacoes = const Value.absent(),
  }) : veiculoPlaca = Value(veiculoPlaca),
       tipo = Value(tipo),
       data = Value(data),
       km = Value(km);
  static Insertable<Manutencao> custom({
    Expression<int>? id,
    Expression<String>? veiculoPlaca,
    Expression<String>? tipo,
    Expression<String>? nomeLivre,
    Expression<DateTime>? data,
    Expression<int>? km,
    Expression<double>? valor,
    Expression<String>? oficina,
    Expression<String>? observacoes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (veiculoPlaca != null) 'veiculo_placa': veiculoPlaca,
      if (tipo != null) 'tipo': tipo,
      if (nomeLivre != null) 'nome_livre': nomeLivre,
      if (data != null) 'data': data,
      if (km != null) 'km': km,
      if (valor != null) 'valor': valor,
      if (oficina != null) 'oficina': oficina,
      if (observacoes != null) 'observacoes': observacoes,
    });
  }

  ManutencoesCompanion copyWith({
    Value<int>? id,
    Value<String>? veiculoPlaca,
    Value<TipoManutencao>? tipo,
    Value<String?>? nomeLivre,
    Value<DateTime>? data,
    Value<int>? km,
    Value<double?>? valor,
    Value<String?>? oficina,
    Value<String?>? observacoes,
  }) {
    return ManutencoesCompanion(
      id: id ?? this.id,
      veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
      tipo: tipo ?? this.tipo,
      nomeLivre: nomeLivre ?? this.nomeLivre,
      data: data ?? this.data,
      km: km ?? this.km,
      valor: valor ?? this.valor,
      oficina: oficina ?? this.oficina,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (veiculoPlaca.present) {
      map['veiculo_placa'] = Variable<String>(veiculoPlaca.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $ManutencoesTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (nomeLivre.present) {
      map['nome_livre'] = Variable<String>(nomeLivre.value);
    }
    if (data.present) {
      map['data'] = Variable<DateTime>(data.value);
    }
    if (km.present) {
      map['km'] = Variable<int>(km.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (oficina.present) {
      map['oficina'] = Variable<String>(oficina.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManutencoesCompanion(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('tipo: $tipo, ')
          ..write('nomeLivre: $nomeLivre, ')
          ..write('data: $data, ')
          ..write('km: $km, ')
          ..write('valor: $valor, ')
          ..write('oficina: $oficina, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }
}

class $DespesasRecorrentesTable extends DespesasRecorrentes
    with TableInfo<$DespesasRecorrentesTable, DespesaRecorrente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DespesasRecorrentesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _veiculoPlacaMeta = const VerificationMeta(
    'veiculoPlaca',
  );
  @override
  late final GeneratedColumn<String> veiculoPlaca = GeneratedColumn<String>(
    'veiculo_placa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES veiculos (placa) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoriaDespesa, String>
  categoria =
      GeneratedColumn<String>(
        'categoria',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoriaDespesa>(
        $DespesasRecorrentesTable.$convertercategoria,
      );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FrequenciaDespesa, String>
  frequencia =
      GeneratedColumn<String>(
        'frequencia',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FrequenciaDespesa>(
        $DespesasRecorrentesTable.$converterfrequencia,
      );
  static const VerificationMeta _dataInicioMeta = const VerificationMeta(
    'dataInicio',
  );
  @override
  late final GeneratedColumn<DateTime> dataInicio = GeneratedColumn<DateTime>(
    'data_inicio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataFimMeta = const VerificationMeta(
    'dataFim',
  );
  @override
  late final GeneratedColumn<DateTime> dataFim = GeneratedColumn<DateTime>(
    'data_fim',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    veiculoPlaca,
    nome,
    categoria,
    valor,
    frequencia,
    dataInicio,
    dataFim,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'despesas_recorrentes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DespesaRecorrente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('veiculo_placa')) {
      context.handle(
        _veiculoPlacaMeta,
        veiculoPlaca.isAcceptableOrUnknown(
          data['veiculo_placa']!,
          _veiculoPlacaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_veiculoPlacaMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('data_inicio')) {
      context.handle(
        _dataInicioMeta,
        dataInicio.isAcceptableOrUnknown(data['data_inicio']!, _dataInicioMeta),
      );
    } else if (isInserting) {
      context.missing(_dataInicioMeta);
    }
    if (data.containsKey('data_fim')) {
      context.handle(
        _dataFimMeta,
        dataFim.isAcceptableOrUnknown(data['data_fim']!, _dataFimMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DespesaRecorrente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DespesaRecorrente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      veiculoPlaca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}veiculo_placa'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      categoria: $DespesasRecorrentesTable.$convertercategoria.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}categoria'],
        )!,
      ),
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor'],
      )!,
      frequencia: $DespesasRecorrentesTable.$converterfrequencia.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}frequencia'],
        )!,
      ),
      dataInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_inicio'],
      )!,
      dataFim: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_fim'],
      ),
    );
  }

  @override
  $DespesasRecorrentesTable createAlias(String alias) {
    return $DespesasRecorrentesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoriaDespesa, String, String>
  $convertercategoria = const EnumNameConverter<CategoriaDespesa>(
    CategoriaDespesa.values,
  );
  static JsonTypeConverter2<FrequenciaDespesa, String, String>
  $converterfrequencia = const EnumNameConverter<FrequenciaDespesa>(
    FrequenciaDespesa.values,
  );
}

class DespesaRecorrente extends DataClass
    implements Insertable<DespesaRecorrente> {
  final int id;
  final String veiculoPlaca;
  final String nome;
  final CategoriaDespesa categoria;
  final double valor;
  final FrequenciaDespesa frequencia;
  final DateTime dataInicio;
  final DateTime? dataFim;
  const DespesaRecorrente({
    required this.id,
    required this.veiculoPlaca,
    required this.nome,
    required this.categoria,
    required this.valor,
    required this.frequencia,
    required this.dataInicio,
    this.dataFim,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['veiculo_placa'] = Variable<String>(veiculoPlaca);
    map['nome'] = Variable<String>(nome);
    {
      map['categoria'] = Variable<String>(
        $DespesasRecorrentesTable.$convertercategoria.toSql(categoria),
      );
    }
    map['valor'] = Variable<double>(valor);
    {
      map['frequencia'] = Variable<String>(
        $DespesasRecorrentesTable.$converterfrequencia.toSql(frequencia),
      );
    }
    map['data_inicio'] = Variable<DateTime>(dataInicio);
    if (!nullToAbsent || dataFim != null) {
      map['data_fim'] = Variable<DateTime>(dataFim);
    }
    return map;
  }

  DespesasRecorrentesCompanion toCompanion(bool nullToAbsent) {
    return DespesasRecorrentesCompanion(
      id: Value(id),
      veiculoPlaca: Value(veiculoPlaca),
      nome: Value(nome),
      categoria: Value(categoria),
      valor: Value(valor),
      frequencia: Value(frequencia),
      dataInicio: Value(dataInicio),
      dataFim: dataFim == null && nullToAbsent
          ? const Value.absent()
          : Value(dataFim),
    );
  }

  factory DespesaRecorrente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DespesaRecorrente(
      id: serializer.fromJson<int>(json['id']),
      veiculoPlaca: serializer.fromJson<String>(json['veiculoPlaca']),
      nome: serializer.fromJson<String>(json['nome']),
      categoria: $DespesasRecorrentesTable.$convertercategoria.fromJson(
        serializer.fromJson<String>(json['categoria']),
      ),
      valor: serializer.fromJson<double>(json['valor']),
      frequencia: $DespesasRecorrentesTable.$converterfrequencia.fromJson(
        serializer.fromJson<String>(json['frequencia']),
      ),
      dataInicio: serializer.fromJson<DateTime>(json['dataInicio']),
      dataFim: serializer.fromJson<DateTime?>(json['dataFim']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'veiculoPlaca': serializer.toJson<String>(veiculoPlaca),
      'nome': serializer.toJson<String>(nome),
      'categoria': serializer.toJson<String>(
        $DespesasRecorrentesTable.$convertercategoria.toJson(categoria),
      ),
      'valor': serializer.toJson<double>(valor),
      'frequencia': serializer.toJson<String>(
        $DespesasRecorrentesTable.$converterfrequencia.toJson(frequencia),
      ),
      'dataInicio': serializer.toJson<DateTime>(dataInicio),
      'dataFim': serializer.toJson<DateTime?>(dataFim),
    };
  }

  DespesaRecorrente copyWith({
    int? id,
    String? veiculoPlaca,
    String? nome,
    CategoriaDespesa? categoria,
    double? valor,
    FrequenciaDespesa? frequencia,
    DateTime? dataInicio,
    Value<DateTime?> dataFim = const Value.absent(),
  }) => DespesaRecorrente(
    id: id ?? this.id,
    veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
    nome: nome ?? this.nome,
    categoria: categoria ?? this.categoria,
    valor: valor ?? this.valor,
    frequencia: frequencia ?? this.frequencia,
    dataInicio: dataInicio ?? this.dataInicio,
    dataFim: dataFim.present ? dataFim.value : this.dataFim,
  );
  DespesaRecorrente copyWithCompanion(DespesasRecorrentesCompanion data) {
    return DespesaRecorrente(
      id: data.id.present ? data.id.value : this.id,
      veiculoPlaca: data.veiculoPlaca.present
          ? data.veiculoPlaca.value
          : this.veiculoPlaca,
      nome: data.nome.present ? data.nome.value : this.nome,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      valor: data.valor.present ? data.valor.value : this.valor,
      frequencia: data.frequencia.present
          ? data.frequencia.value
          : this.frequencia,
      dataInicio: data.dataInicio.present
          ? data.dataInicio.value
          : this.dataInicio,
      dataFim: data.dataFim.present ? data.dataFim.value : this.dataFim,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DespesaRecorrente(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('nome: $nome, ')
          ..write('categoria: $categoria, ')
          ..write('valor: $valor, ')
          ..write('frequencia: $frequencia, ')
          ..write('dataInicio: $dataInicio, ')
          ..write('dataFim: $dataFim')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    veiculoPlaca,
    nome,
    categoria,
    valor,
    frequencia,
    dataInicio,
    dataFim,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DespesaRecorrente &&
          other.id == this.id &&
          other.veiculoPlaca == this.veiculoPlaca &&
          other.nome == this.nome &&
          other.categoria == this.categoria &&
          other.valor == this.valor &&
          other.frequencia == this.frequencia &&
          other.dataInicio == this.dataInicio &&
          other.dataFim == this.dataFim);
}

class DespesasRecorrentesCompanion extends UpdateCompanion<DespesaRecorrente> {
  final Value<int> id;
  final Value<String> veiculoPlaca;
  final Value<String> nome;
  final Value<CategoriaDespesa> categoria;
  final Value<double> valor;
  final Value<FrequenciaDespesa> frequencia;
  final Value<DateTime> dataInicio;
  final Value<DateTime?> dataFim;
  const DespesasRecorrentesCompanion({
    this.id = const Value.absent(),
    this.veiculoPlaca = const Value.absent(),
    this.nome = const Value.absent(),
    this.categoria = const Value.absent(),
    this.valor = const Value.absent(),
    this.frequencia = const Value.absent(),
    this.dataInicio = const Value.absent(),
    this.dataFim = const Value.absent(),
  });
  DespesasRecorrentesCompanion.insert({
    this.id = const Value.absent(),
    required String veiculoPlaca,
    required String nome,
    required CategoriaDespesa categoria,
    required double valor,
    required FrequenciaDespesa frequencia,
    required DateTime dataInicio,
    this.dataFim = const Value.absent(),
  }) : veiculoPlaca = Value(veiculoPlaca),
       nome = Value(nome),
       categoria = Value(categoria),
       valor = Value(valor),
       frequencia = Value(frequencia),
       dataInicio = Value(dataInicio);
  static Insertable<DespesaRecorrente> custom({
    Expression<int>? id,
    Expression<String>? veiculoPlaca,
    Expression<String>? nome,
    Expression<String>? categoria,
    Expression<double>? valor,
    Expression<String>? frequencia,
    Expression<DateTime>? dataInicio,
    Expression<DateTime>? dataFim,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (veiculoPlaca != null) 'veiculo_placa': veiculoPlaca,
      if (nome != null) 'nome': nome,
      if (categoria != null) 'categoria': categoria,
      if (valor != null) 'valor': valor,
      if (frequencia != null) 'frequencia': frequencia,
      if (dataInicio != null) 'data_inicio': dataInicio,
      if (dataFim != null) 'data_fim': dataFim,
    });
  }

  DespesasRecorrentesCompanion copyWith({
    Value<int>? id,
    Value<String>? veiculoPlaca,
    Value<String>? nome,
    Value<CategoriaDespesa>? categoria,
    Value<double>? valor,
    Value<FrequenciaDespesa>? frequencia,
    Value<DateTime>? dataInicio,
    Value<DateTime?>? dataFim,
  }) {
    return DespesasRecorrentesCompanion(
      id: id ?? this.id,
      veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      valor: valor ?? this.valor,
      frequencia: frequencia ?? this.frequencia,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (veiculoPlaca.present) {
      map['veiculo_placa'] = Variable<String>(veiculoPlaca.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(
        $DespesasRecorrentesTable.$convertercategoria.toSql(categoria.value),
      );
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (frequencia.present) {
      map['frequencia'] = Variable<String>(
        $DespesasRecorrentesTable.$converterfrequencia.toSql(frequencia.value),
      );
    }
    if (dataInicio.present) {
      map['data_inicio'] = Variable<DateTime>(dataInicio.value);
    }
    if (dataFim.present) {
      map['data_fim'] = Variable<DateTime>(dataFim.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DespesasRecorrentesCompanion(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('nome: $nome, ')
          ..write('categoria: $categoria, ')
          ..write('valor: $valor, ')
          ..write('frequencia: $frequencia, ')
          ..write('dataInicio: $dataInicio, ')
          ..write('dataFim: $dataFim')
          ..write(')'))
        .toString();
  }
}

class $OcorrenciasDespesaTable extends OcorrenciasDespesa
    with TableInfo<$OcorrenciasDespesaTable, OcorrenciaDespesa> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcorrenciasDespesaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _despesaIdMeta = const VerificationMeta(
    'despesaId',
  );
  @override
  late final GeneratedColumn<int> despesaId = GeneratedColumn<int>(
    'despesa_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES despesas_recorrentes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dataVencimentoMeta = const VerificationMeta(
    'dataVencimento',
  );
  @override
  late final GeneratedColumn<DateTime> dataVencimento =
      GeneratedColumn<DateTime>(
        'data_vencimento',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dataPagamentoMeta = const VerificationMeta(
    'dataPagamento',
  );
  @override
  late final GeneratedColumn<DateTime> dataPagamento =
      GeneratedColumn<DateTime>(
        'data_pagamento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _valorPagoMeta = const VerificationMeta(
    'valorPago',
  );
  @override
  late final GeneratedColumn<double> valorPago = GeneratedColumn<double>(
    'valor_pago',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StatusOcorrencia, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StatusOcorrencia>(
        $OcorrenciasDespesaTable.$converterstatus,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    despesaId,
    dataVencimento,
    dataPagamento,
    valorPago,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocorrencias_despesa';
  @override
  VerificationContext validateIntegrity(
    Insertable<OcorrenciaDespesa> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('despesa_id')) {
      context.handle(
        _despesaIdMeta,
        despesaId.isAcceptableOrUnknown(data['despesa_id']!, _despesaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_despesaIdMeta);
    }
    if (data.containsKey('data_vencimento')) {
      context.handle(
        _dataVencimentoMeta,
        dataVencimento.isAcceptableOrUnknown(
          data['data_vencimento']!,
          _dataVencimentoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataVencimentoMeta);
    }
    if (data.containsKey('data_pagamento')) {
      context.handle(
        _dataPagamentoMeta,
        dataPagamento.isAcceptableOrUnknown(
          data['data_pagamento']!,
          _dataPagamentoMeta,
        ),
      );
    }
    if (data.containsKey('valor_pago')) {
      context.handle(
        _valorPagoMeta,
        valorPago.isAcceptableOrUnknown(data['valor_pago']!, _valorPagoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OcorrenciaDespesa map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcorrenciaDespesa(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      despesaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}despesa_id'],
      )!,
      dataVencimento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_vencimento'],
      )!,
      dataPagamento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_pagamento'],
      ),
      valorPago: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor_pago'],
      ),
      status: $OcorrenciasDespesaTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $OcorrenciasDespesaTable createAlias(String alias) {
    return $OcorrenciasDespesaTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StatusOcorrencia, String, String> $converterstatus =
      const EnumNameConverter<StatusOcorrencia>(StatusOcorrencia.values);
}

class OcorrenciaDespesa extends DataClass
    implements Insertable<OcorrenciaDespesa> {
  final int id;
  final int despesaId;
  final DateTime dataVencimento;
  final DateTime? dataPagamento;
  final double? valorPago;
  final StatusOcorrencia status;
  const OcorrenciaDespesa({
    required this.id,
    required this.despesaId,
    required this.dataVencimento,
    this.dataPagamento,
    this.valorPago,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['despesa_id'] = Variable<int>(despesaId);
    map['data_vencimento'] = Variable<DateTime>(dataVencimento);
    if (!nullToAbsent || dataPagamento != null) {
      map['data_pagamento'] = Variable<DateTime>(dataPagamento);
    }
    if (!nullToAbsent || valorPago != null) {
      map['valor_pago'] = Variable<double>(valorPago);
    }
    {
      map['status'] = Variable<String>(
        $OcorrenciasDespesaTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  OcorrenciasDespesaCompanion toCompanion(bool nullToAbsent) {
    return OcorrenciasDespesaCompanion(
      id: Value(id),
      despesaId: Value(despesaId),
      dataVencimento: Value(dataVencimento),
      dataPagamento: dataPagamento == null && nullToAbsent
          ? const Value.absent()
          : Value(dataPagamento),
      valorPago: valorPago == null && nullToAbsent
          ? const Value.absent()
          : Value(valorPago),
      status: Value(status),
    );
  }

  factory OcorrenciaDespesa.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcorrenciaDespesa(
      id: serializer.fromJson<int>(json['id']),
      despesaId: serializer.fromJson<int>(json['despesaId']),
      dataVencimento: serializer.fromJson<DateTime>(json['dataVencimento']),
      dataPagamento: serializer.fromJson<DateTime?>(json['dataPagamento']),
      valorPago: serializer.fromJson<double?>(json['valorPago']),
      status: $OcorrenciasDespesaTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'despesaId': serializer.toJson<int>(despesaId),
      'dataVencimento': serializer.toJson<DateTime>(dataVencimento),
      'dataPagamento': serializer.toJson<DateTime?>(dataPagamento),
      'valorPago': serializer.toJson<double?>(valorPago),
      'status': serializer.toJson<String>(
        $OcorrenciasDespesaTable.$converterstatus.toJson(status),
      ),
    };
  }

  OcorrenciaDespesa copyWith({
    int? id,
    int? despesaId,
    DateTime? dataVencimento,
    Value<DateTime?> dataPagamento = const Value.absent(),
    Value<double?> valorPago = const Value.absent(),
    StatusOcorrencia? status,
  }) => OcorrenciaDespesa(
    id: id ?? this.id,
    despesaId: despesaId ?? this.despesaId,
    dataVencimento: dataVencimento ?? this.dataVencimento,
    dataPagamento: dataPagamento.present
        ? dataPagamento.value
        : this.dataPagamento,
    valorPago: valorPago.present ? valorPago.value : this.valorPago,
    status: status ?? this.status,
  );
  OcorrenciaDespesa copyWithCompanion(OcorrenciasDespesaCompanion data) {
    return OcorrenciaDespesa(
      id: data.id.present ? data.id.value : this.id,
      despesaId: data.despesaId.present ? data.despesaId.value : this.despesaId,
      dataVencimento: data.dataVencimento.present
          ? data.dataVencimento.value
          : this.dataVencimento,
      dataPagamento: data.dataPagamento.present
          ? data.dataPagamento.value
          : this.dataPagamento,
      valorPago: data.valorPago.present ? data.valorPago.value : this.valorPago,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcorrenciaDespesa(')
          ..write('id: $id, ')
          ..write('despesaId: $despesaId, ')
          ..write('dataVencimento: $dataVencimento, ')
          ..write('dataPagamento: $dataPagamento, ')
          ..write('valorPago: $valorPago, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    despesaId,
    dataVencimento,
    dataPagamento,
    valorPago,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcorrenciaDespesa &&
          other.id == this.id &&
          other.despesaId == this.despesaId &&
          other.dataVencimento == this.dataVencimento &&
          other.dataPagamento == this.dataPagamento &&
          other.valorPago == this.valorPago &&
          other.status == this.status);
}

class OcorrenciasDespesaCompanion extends UpdateCompanion<OcorrenciaDespesa> {
  final Value<int> id;
  final Value<int> despesaId;
  final Value<DateTime> dataVencimento;
  final Value<DateTime?> dataPagamento;
  final Value<double?> valorPago;
  final Value<StatusOcorrencia> status;
  const OcorrenciasDespesaCompanion({
    this.id = const Value.absent(),
    this.despesaId = const Value.absent(),
    this.dataVencimento = const Value.absent(),
    this.dataPagamento = const Value.absent(),
    this.valorPago = const Value.absent(),
    this.status = const Value.absent(),
  });
  OcorrenciasDespesaCompanion.insert({
    this.id = const Value.absent(),
    required int despesaId,
    required DateTime dataVencimento,
    this.dataPagamento = const Value.absent(),
    this.valorPago = const Value.absent(),
    required StatusOcorrencia status,
  }) : despesaId = Value(despesaId),
       dataVencimento = Value(dataVencimento),
       status = Value(status);
  static Insertable<OcorrenciaDespesa> custom({
    Expression<int>? id,
    Expression<int>? despesaId,
    Expression<DateTime>? dataVencimento,
    Expression<DateTime>? dataPagamento,
    Expression<double>? valorPago,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (despesaId != null) 'despesa_id': despesaId,
      if (dataVencimento != null) 'data_vencimento': dataVencimento,
      if (dataPagamento != null) 'data_pagamento': dataPagamento,
      if (valorPago != null) 'valor_pago': valorPago,
      if (status != null) 'status': status,
    });
  }

  OcorrenciasDespesaCompanion copyWith({
    Value<int>? id,
    Value<int>? despesaId,
    Value<DateTime>? dataVencimento,
    Value<DateTime?>? dataPagamento,
    Value<double?>? valorPago,
    Value<StatusOcorrencia>? status,
  }) {
    return OcorrenciasDespesaCompanion(
      id: id ?? this.id,
      despesaId: despesaId ?? this.despesaId,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      valorPago: valorPago ?? this.valorPago,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (despesaId.present) {
      map['despesa_id'] = Variable<int>(despesaId.value);
    }
    if (dataVencimento.present) {
      map['data_vencimento'] = Variable<DateTime>(dataVencimento.value);
    }
    if (dataPagamento.present) {
      map['data_pagamento'] = Variable<DateTime>(dataPagamento.value);
    }
    if (valorPago.present) {
      map['valor_pago'] = Variable<double>(valorPago.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $OcorrenciasDespesaTable.$converterstatus.toSql(status.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcorrenciasDespesaCompanion(')
          ..write('id: $id, ')
          ..write('despesaId: $despesaId, ')
          ..write('dataVencimento: $dataVencimento, ')
          ..write('dataPagamento: $dataPagamento, ')
          ..write('valorPago: $valorPago, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $LembretesTable extends Lembretes
    with TableInfo<$LembretesTable, Lembrete> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LembretesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _veiculoPlacaMeta = const VerificationMeta(
    'veiculoPlaca',
  );
  @override
  late final GeneratedColumn<String> veiculoPlaca = GeneratedColumn<String>(
    'veiculo_placa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES veiculos (placa) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _manutencaoIdMeta = const VerificationMeta(
    'manutencaoId',
  );
  @override
  late final GeneratedColumn<int> manutencaoId = GeneratedColumn<int>(
    'manutencao_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES manutencoes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataAlvoMeta = const VerificationMeta(
    'dataAlvo',
  );
  @override
  late final GeneratedColumn<DateTime> dataAlvo = GeneratedColumn<DateTime>(
    'data_alvo',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kmAlvoMeta = const VerificationMeta('kmAlvo');
  @override
  late final GeneratedColumn<int> kmAlvo = GeneratedColumn<int>(
    'km_alvo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StatusLembrete, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StatusLembrete>($LembretesTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    veiculoPlaca,
    manutencaoId,
    tipo,
    descricao,
    dataAlvo,
    kmAlvo,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lembretes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lembrete> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('veiculo_placa')) {
      context.handle(
        _veiculoPlacaMeta,
        veiculoPlaca.isAcceptableOrUnknown(
          data['veiculo_placa']!,
          _veiculoPlacaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_veiculoPlacaMeta);
    }
    if (data.containsKey('manutencao_id')) {
      context.handle(
        _manutencaoIdMeta,
        manutencaoId.isAcceptableOrUnknown(
          data['manutencao_id']!,
          _manutencaoIdMeta,
        ),
      );
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('data_alvo')) {
      context.handle(
        _dataAlvoMeta,
        dataAlvo.isAcceptableOrUnknown(data['data_alvo']!, _dataAlvoMeta),
      );
    }
    if (data.containsKey('km_alvo')) {
      context.handle(
        _kmAlvoMeta,
        kmAlvo.isAcceptableOrUnknown(data['km_alvo']!, _kmAlvoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lembrete map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lembrete(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      veiculoPlaca: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}veiculo_placa'],
      )!,
      manutencaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manutencao_id'],
      ),
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      dataAlvo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_alvo'],
      ),
      kmAlvo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km_alvo'],
      ),
      status: $LembretesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $LembretesTable createAlias(String alias) {
    return $LembretesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StatusLembrete, String, String> $converterstatus =
      const EnumNameConverter<StatusLembrete>(StatusLembrete.values);
}

class Lembrete extends DataClass implements Insertable<Lembrete> {
  final int id;
  final String veiculoPlaca;
  final int? manutencaoId;
  final String tipo;
  final String descricao;
  final DateTime? dataAlvo;
  final int? kmAlvo;
  final StatusLembrete status;
  const Lembrete({
    required this.id,
    required this.veiculoPlaca,
    this.manutencaoId,
    required this.tipo,
    required this.descricao,
    this.dataAlvo,
    this.kmAlvo,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['veiculo_placa'] = Variable<String>(veiculoPlaca);
    if (!nullToAbsent || manutencaoId != null) {
      map['manutencao_id'] = Variable<int>(manutencaoId);
    }
    map['tipo'] = Variable<String>(tipo);
    map['descricao'] = Variable<String>(descricao);
    if (!nullToAbsent || dataAlvo != null) {
      map['data_alvo'] = Variable<DateTime>(dataAlvo);
    }
    if (!nullToAbsent || kmAlvo != null) {
      map['km_alvo'] = Variable<int>(kmAlvo);
    }
    {
      map['status'] = Variable<String>(
        $LembretesTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  LembretesCompanion toCompanion(bool nullToAbsent) {
    return LembretesCompanion(
      id: Value(id),
      veiculoPlaca: Value(veiculoPlaca),
      manutencaoId: manutencaoId == null && nullToAbsent
          ? const Value.absent()
          : Value(manutencaoId),
      tipo: Value(tipo),
      descricao: Value(descricao),
      dataAlvo: dataAlvo == null && nullToAbsent
          ? const Value.absent()
          : Value(dataAlvo),
      kmAlvo: kmAlvo == null && nullToAbsent
          ? const Value.absent()
          : Value(kmAlvo),
      status: Value(status),
    );
  }

  factory Lembrete.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lembrete(
      id: serializer.fromJson<int>(json['id']),
      veiculoPlaca: serializer.fromJson<String>(json['veiculoPlaca']),
      manutencaoId: serializer.fromJson<int?>(json['manutencaoId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      descricao: serializer.fromJson<String>(json['descricao']),
      dataAlvo: serializer.fromJson<DateTime?>(json['dataAlvo']),
      kmAlvo: serializer.fromJson<int?>(json['kmAlvo']),
      status: $LembretesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'veiculoPlaca': serializer.toJson<String>(veiculoPlaca),
      'manutencaoId': serializer.toJson<int?>(manutencaoId),
      'tipo': serializer.toJson<String>(tipo),
      'descricao': serializer.toJson<String>(descricao),
      'dataAlvo': serializer.toJson<DateTime?>(dataAlvo),
      'kmAlvo': serializer.toJson<int?>(kmAlvo),
      'status': serializer.toJson<String>(
        $LembretesTable.$converterstatus.toJson(status),
      ),
    };
  }

  Lembrete copyWith({
    int? id,
    String? veiculoPlaca,
    Value<int?> manutencaoId = const Value.absent(),
    String? tipo,
    String? descricao,
    Value<DateTime?> dataAlvo = const Value.absent(),
    Value<int?> kmAlvo = const Value.absent(),
    StatusLembrete? status,
  }) => Lembrete(
    id: id ?? this.id,
    veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
    manutencaoId: manutencaoId.present ? manutencaoId.value : this.manutencaoId,
    tipo: tipo ?? this.tipo,
    descricao: descricao ?? this.descricao,
    dataAlvo: dataAlvo.present ? dataAlvo.value : this.dataAlvo,
    kmAlvo: kmAlvo.present ? kmAlvo.value : this.kmAlvo,
    status: status ?? this.status,
  );
  Lembrete copyWithCompanion(LembretesCompanion data) {
    return Lembrete(
      id: data.id.present ? data.id.value : this.id,
      veiculoPlaca: data.veiculoPlaca.present
          ? data.veiculoPlaca.value
          : this.veiculoPlaca,
      manutencaoId: data.manutencaoId.present
          ? data.manutencaoId.value
          : this.manutencaoId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      dataAlvo: data.dataAlvo.present ? data.dataAlvo.value : this.dataAlvo,
      kmAlvo: data.kmAlvo.present ? data.kmAlvo.value : this.kmAlvo,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lembrete(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('manutencaoId: $manutencaoId, ')
          ..write('tipo: $tipo, ')
          ..write('descricao: $descricao, ')
          ..write('dataAlvo: $dataAlvo, ')
          ..write('kmAlvo: $kmAlvo, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    veiculoPlaca,
    manutencaoId,
    tipo,
    descricao,
    dataAlvo,
    kmAlvo,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lembrete &&
          other.id == this.id &&
          other.veiculoPlaca == this.veiculoPlaca &&
          other.manutencaoId == this.manutencaoId &&
          other.tipo == this.tipo &&
          other.descricao == this.descricao &&
          other.dataAlvo == this.dataAlvo &&
          other.kmAlvo == this.kmAlvo &&
          other.status == this.status);
}

class LembretesCompanion extends UpdateCompanion<Lembrete> {
  final Value<int> id;
  final Value<String> veiculoPlaca;
  final Value<int?> manutencaoId;
  final Value<String> tipo;
  final Value<String> descricao;
  final Value<DateTime?> dataAlvo;
  final Value<int?> kmAlvo;
  final Value<StatusLembrete> status;
  const LembretesCompanion({
    this.id = const Value.absent(),
    this.veiculoPlaca = const Value.absent(),
    this.manutencaoId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.descricao = const Value.absent(),
    this.dataAlvo = const Value.absent(),
    this.kmAlvo = const Value.absent(),
    this.status = const Value.absent(),
  });
  LembretesCompanion.insert({
    this.id = const Value.absent(),
    required String veiculoPlaca,
    this.manutencaoId = const Value.absent(),
    required String tipo,
    required String descricao,
    this.dataAlvo = const Value.absent(),
    this.kmAlvo = const Value.absent(),
    required StatusLembrete status,
  }) : veiculoPlaca = Value(veiculoPlaca),
       tipo = Value(tipo),
       descricao = Value(descricao),
       status = Value(status);
  static Insertable<Lembrete> custom({
    Expression<int>? id,
    Expression<String>? veiculoPlaca,
    Expression<int>? manutencaoId,
    Expression<String>? tipo,
    Expression<String>? descricao,
    Expression<DateTime>? dataAlvo,
    Expression<int>? kmAlvo,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (veiculoPlaca != null) 'veiculo_placa': veiculoPlaca,
      if (manutencaoId != null) 'manutencao_id': manutencaoId,
      if (tipo != null) 'tipo': tipo,
      if (descricao != null) 'descricao': descricao,
      if (dataAlvo != null) 'data_alvo': dataAlvo,
      if (kmAlvo != null) 'km_alvo': kmAlvo,
      if (status != null) 'status': status,
    });
  }

  LembretesCompanion copyWith({
    Value<int>? id,
    Value<String>? veiculoPlaca,
    Value<int?>? manutencaoId,
    Value<String>? tipo,
    Value<String>? descricao,
    Value<DateTime?>? dataAlvo,
    Value<int?>? kmAlvo,
    Value<StatusLembrete>? status,
  }) {
    return LembretesCompanion(
      id: id ?? this.id,
      veiculoPlaca: veiculoPlaca ?? this.veiculoPlaca,
      manutencaoId: manutencaoId ?? this.manutencaoId,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      dataAlvo: dataAlvo ?? this.dataAlvo,
      kmAlvo: kmAlvo ?? this.kmAlvo,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (veiculoPlaca.present) {
      map['veiculo_placa'] = Variable<String>(veiculoPlaca.value);
    }
    if (manutencaoId.present) {
      map['manutencao_id'] = Variable<int>(manutencaoId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (dataAlvo.present) {
      map['data_alvo'] = Variable<DateTime>(dataAlvo.value);
    }
    if (kmAlvo.present) {
      map['km_alvo'] = Variable<int>(kmAlvo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $LembretesTable.$converterstatus.toSql(status.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LembretesCompanion(')
          ..write('id: $id, ')
          ..write('veiculoPlaca: $veiculoPlaca, ')
          ..write('manutencaoId: $manutencaoId, ')
          ..write('tipo: $tipo, ')
          ..write('descricao: $descricao, ')
          ..write('dataAlvo: $dataAlvo, ')
          ..write('kmAlvo: $kmAlvo, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $PostosSugestaoTable extends PostosSugestao
    with TableInfo<$PostosSugestaoTable, PostoSugestao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostosSugestaoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [nome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'postos_sugestao';
  @override
  VerificationContext validateIntegrity(
    Insertable<PostoSugestao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nome};
  @override
  PostoSugestao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PostoSugestao(
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
    );
  }

  @override
  $PostosSugestaoTable createAlias(String alias) {
    return $PostosSugestaoTable(attachedDatabase, alias);
  }
}

class PostoSugestao extends DataClass implements Insertable<PostoSugestao> {
  final String nome;
  const PostoSugestao({required this.nome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['nome'] = Variable<String>(nome);
    return map;
  }

  PostosSugestaoCompanion toCompanion(bool nullToAbsent) {
    return PostosSugestaoCompanion(nome: Value(nome));
  }

  factory PostoSugestao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PostoSugestao(nome: serializer.fromJson<String>(json['nome']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'nome': serializer.toJson<String>(nome)};
  }

  PostoSugestao copyWith({String? nome}) =>
      PostoSugestao(nome: nome ?? this.nome);
  PostoSugestao copyWithCompanion(PostosSugestaoCompanion data) {
    return PostoSugestao(nome: data.nome.present ? data.nome.value : this.nome);
  }

  @override
  String toString() {
    return (StringBuffer('PostoSugestao(')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => nome.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostoSugestao && other.nome == this.nome);
}

class PostosSugestaoCompanion extends UpdateCompanion<PostoSugestao> {
  final Value<String> nome;
  final Value<int> rowid;
  const PostosSugestaoCompanion({
    this.nome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PostosSugestaoCompanion.insert({
    required String nome,
    this.rowid = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<PostoSugestao> custom({
    Expression<String>? nome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nome != null) 'nome': nome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PostosSugestaoCompanion copyWith({Value<String>? nome, Value<int>? rowid}) {
    return PostosSugestaoCompanion(
      nome: nome ?? this.nome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostosSugestaoCompanion(')
          ..write('nome: $nome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TiposManutencaoPadraoTable extends TiposManutencaoPadrao
    with TableInfo<$TiposManutencaoPadraoTable, TipoManutencaoPadrao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiposManutencaoPadraoTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<TipoManutencao, String> tipo =
      GeneratedColumn<String>(
        'tipo',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TipoManutencao>(
        $TiposManutencaoPadraoTable.$convertertipo,
      );
  static const VerificationMeta _intervaloKmMeta = const VerificationMeta(
    'intervaloKm',
  );
  @override
  late final GeneratedColumn<int> intervaloKm = GeneratedColumn<int>(
    'intervalo_km',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervaloMesesMeta = const VerificationMeta(
    'intervaloMeses',
  );
  @override
  late final GeneratedColumn<int> intervaloMeses = GeneratedColumn<int>(
    'intervalo_meses',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [tipo, intervaloKm, intervaloMeses];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tipos_manutencao_padrao';
  @override
  VerificationContext validateIntegrity(
    Insertable<TipoManutencaoPadrao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('intervalo_km')) {
      context.handle(
        _intervaloKmMeta,
        intervaloKm.isAcceptableOrUnknown(
          data['intervalo_km']!,
          _intervaloKmMeta,
        ),
      );
    }
    if (data.containsKey('intervalo_meses')) {
      context.handle(
        _intervaloMesesMeta,
        intervaloMeses.isAcceptableOrUnknown(
          data['intervalo_meses']!,
          _intervaloMesesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tipo};
  @override
  TipoManutencaoPadrao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TipoManutencaoPadrao(
      tipo: $TiposManutencaoPadraoTable.$convertertipo.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tipo'],
        )!,
      ),
      intervaloKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intervalo_km'],
      ),
      intervaloMeses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intervalo_meses'],
      ),
    );
  }

  @override
  $TiposManutencaoPadraoTable createAlias(String alias) {
    return $TiposManutencaoPadraoTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TipoManutencao, String, String> $convertertipo =
      const EnumNameConverter<TipoManutencao>(TipoManutencao.values);
}

class TipoManutencaoPadrao extends DataClass
    implements Insertable<TipoManutencaoPadrao> {
  final TipoManutencao tipo;
  final int? intervaloKm;
  final int? intervaloMeses;
  const TipoManutencaoPadrao({
    required this.tipo,
    this.intervaloKm,
    this.intervaloMeses,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['tipo'] = Variable<String>(
        $TiposManutencaoPadraoTable.$convertertipo.toSql(tipo),
      );
    }
    if (!nullToAbsent || intervaloKm != null) {
      map['intervalo_km'] = Variable<int>(intervaloKm);
    }
    if (!nullToAbsent || intervaloMeses != null) {
      map['intervalo_meses'] = Variable<int>(intervaloMeses);
    }
    return map;
  }

  TiposManutencaoPadraoCompanion toCompanion(bool nullToAbsent) {
    return TiposManutencaoPadraoCompanion(
      tipo: Value(tipo),
      intervaloKm: intervaloKm == null && nullToAbsent
          ? const Value.absent()
          : Value(intervaloKm),
      intervaloMeses: intervaloMeses == null && nullToAbsent
          ? const Value.absent()
          : Value(intervaloMeses),
    );
  }

  factory TipoManutencaoPadrao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TipoManutencaoPadrao(
      tipo: $TiposManutencaoPadraoTable.$convertertipo.fromJson(
        serializer.fromJson<String>(json['tipo']),
      ),
      intervaloKm: serializer.fromJson<int?>(json['intervaloKm']),
      intervaloMeses: serializer.fromJson<int?>(json['intervaloMeses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tipo': serializer.toJson<String>(
        $TiposManutencaoPadraoTable.$convertertipo.toJson(tipo),
      ),
      'intervaloKm': serializer.toJson<int?>(intervaloKm),
      'intervaloMeses': serializer.toJson<int?>(intervaloMeses),
    };
  }

  TipoManutencaoPadrao copyWith({
    TipoManutencao? tipo,
    Value<int?> intervaloKm = const Value.absent(),
    Value<int?> intervaloMeses = const Value.absent(),
  }) => TipoManutencaoPadrao(
    tipo: tipo ?? this.tipo,
    intervaloKm: intervaloKm.present ? intervaloKm.value : this.intervaloKm,
    intervaloMeses: intervaloMeses.present
        ? intervaloMeses.value
        : this.intervaloMeses,
  );
  TipoManutencaoPadrao copyWithCompanion(TiposManutencaoPadraoCompanion data) {
    return TipoManutencaoPadrao(
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      intervaloKm: data.intervaloKm.present
          ? data.intervaloKm.value
          : this.intervaloKm,
      intervaloMeses: data.intervaloMeses.present
          ? data.intervaloMeses.value
          : this.intervaloMeses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TipoManutencaoPadrao(')
          ..write('tipo: $tipo, ')
          ..write('intervaloKm: $intervaloKm, ')
          ..write('intervaloMeses: $intervaloMeses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tipo, intervaloKm, intervaloMeses);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TipoManutencaoPadrao &&
          other.tipo == this.tipo &&
          other.intervaloKm == this.intervaloKm &&
          other.intervaloMeses == this.intervaloMeses);
}

class TiposManutencaoPadraoCompanion
    extends UpdateCompanion<TipoManutencaoPadrao> {
  final Value<TipoManutencao> tipo;
  final Value<int?> intervaloKm;
  final Value<int?> intervaloMeses;
  final Value<int> rowid;
  const TiposManutencaoPadraoCompanion({
    this.tipo = const Value.absent(),
    this.intervaloKm = const Value.absent(),
    this.intervaloMeses = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TiposManutencaoPadraoCompanion.insert({
    required TipoManutencao tipo,
    this.intervaloKm = const Value.absent(),
    this.intervaloMeses = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tipo = Value(tipo);
  static Insertable<TipoManutencaoPadrao> custom({
    Expression<String>? tipo,
    Expression<int>? intervaloKm,
    Expression<int>? intervaloMeses,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tipo != null) 'tipo': tipo,
      if (intervaloKm != null) 'intervalo_km': intervaloKm,
      if (intervaloMeses != null) 'intervalo_meses': intervaloMeses,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TiposManutencaoPadraoCompanion copyWith({
    Value<TipoManutencao>? tipo,
    Value<int?>? intervaloKm,
    Value<int?>? intervaloMeses,
    Value<int>? rowid,
  }) {
    return TiposManutencaoPadraoCompanion(
      tipo: tipo ?? this.tipo,
      intervaloKm: intervaloKm ?? this.intervaloKm,
      intervaloMeses: intervaloMeses ?? this.intervaloMeses,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tipo.present) {
      map['tipo'] = Variable<String>(
        $TiposManutencaoPadraoTable.$convertertipo.toSql(tipo.value),
      );
    }
    if (intervaloKm.present) {
      map['intervalo_km'] = Variable<int>(intervaloKm.value);
    }
    if (intervaloMeses.present) {
      map['intervalo_meses'] = Variable<int>(intervaloMeses.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiposManutencaoPadraoCompanion(')
          ..write('tipo: $tipo, ')
          ..write('intervaloKm: $intervaloKm, ')
          ..write('intervaloMeses: $intervaloMeses, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VeiculosTable veiculos = $VeiculosTable(this);
  late final $AbastecimentosTable abastecimentos = $AbastecimentosTable(this);
  late final $ManutencoesTable manutencoes = $ManutencoesTable(this);
  late final $DespesasRecorrentesTable despesasRecorrentes =
      $DespesasRecorrentesTable(this);
  late final $OcorrenciasDespesaTable ocorrenciasDespesa =
      $OcorrenciasDespesaTable(this);
  late final $LembretesTable lembretes = $LembretesTable(this);
  late final $PostosSugestaoTable postosSugestao = $PostosSugestaoTable(this);
  late final $TiposManutencaoPadraoTable tiposManutencaoPadrao =
      $TiposManutencaoPadraoTable(this);
  late final VeiculosDao veiculosDao = VeiculosDao(this as AppDatabase);
  late final AbastecimentosDao abastecimentosDao = AbastecimentosDao(
    this as AppDatabase,
  );
  late final ManutencoesDao manutencoesDao = ManutencoesDao(
    this as AppDatabase,
  );
  late final TiposManutencaoPadraoDao tiposManutencaoPadraoDao =
      TiposManutencaoPadraoDao(this as AppDatabase);
  late final DespesasRecorrentesDao despesasRecorrentesDao =
      DespesasRecorrentesDao(this as AppDatabase);
  late final OcorrenciasDespesaDao ocorrenciasDespesaDao =
      OcorrenciasDespesaDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    veiculos,
    abastecimentos,
    manutencoes,
    despesasRecorrentes,
    ocorrenciasDespesa,
    lembretes,
    postosSugestao,
    tiposManutencaoPadrao,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'veiculos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('abastecimentos', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'veiculos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('manutencoes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'veiculos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('despesas_recorrentes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'despesas_recorrentes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ocorrencias_despesa', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'veiculos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lembretes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'manutencoes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lembretes', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$VeiculosTableCreateCompanionBuilder = VeiculosCompanion Function({
  required String placa,
  Value<String?> apelido,
  required String marca,
  required String modelo,
  required int ano,
  required TipoVeiculo tipo,
  required TipoCombustivelVeiculo combustivel,
  required int kmInicial,
  Value<bool> arquivado,
  Value<int> rowid,
});
typedef $$VeiculosTableUpdateCompanionBuilder = VeiculosCompanion Function({
  Value<String> placa,
  Value<String?> apelido,
  Value<String> marca,
  Value<String> modelo,
  Value<int> ano,
  Value<TipoVeiculo> tipo,
  Value<TipoCombustivelVeiculo> combustivel,
  Value<int> kmInicial,
  Value<bool> arquivado,
  Value<int> rowid,
});

final class $$VeiculosTableReferences
    extends BaseReferences<_$AppDatabase, $VeiculosTable, Veiculo> {
  $$VeiculosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AbastecimentosTable, List<Abastecimento>>
  _abastecimentosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.abastecimentos,
    aliasName: 'veiculos__placa__abastecimentos__veiculo_placa',
  );

  $$AbastecimentosTableProcessedTableManager get abastecimentosRefs {
    final manager = $$AbastecimentosTableTableManager($_db, $_db.abastecimentos)
        .filter(
          (f) => f.veiculoPlaca.placa.sqlEquals($_itemColumn<String>('placa')!),
        );

    final cache = $_typedResult.readTableOrNull(_abastecimentosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ManutencoesTable, List<Manutencao>>
  _manutencoesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.manutencoes,
    aliasName: 'veiculos__placa__manutencoes__veiculo_placa',
  );

  $$ManutencoesTableProcessedTableManager get manutencoesRefs {
    final manager = $$ManutencoesTableTableManager($_db, $_db.manutencoes)
        .filter(
          (f) => f.veiculoPlaca.placa.sqlEquals($_itemColumn<String>('placa')!),
        );

    final cache = $_typedResult.readTableOrNull(_manutencoesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DespesasRecorrentesTable, List<DespesaRecorrente>>
  _despesasRecorrentesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.despesasRecorrentes,
        aliasName: 'veiculos__placa__despesas_recorrentes__veiculo_placa',
      );

  $$DespesasRecorrentesTableProcessedTableManager get despesasRecorrentesRefs {
    final manager =
        $$DespesasRecorrentesTableTableManager(
          $_db,
          $_db.despesasRecorrentes,
        ).filter(
          (f) => f.veiculoPlaca.placa.sqlEquals($_itemColumn<String>('placa')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _despesasRecorrentesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LembretesTable, List<Lembrete>>
  _lembretesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lembretes,
    aliasName: 'veiculos__placa__lembretes__veiculo_placa',
  );

  $$LembretesTableProcessedTableManager get lembretesRefs {
    final manager = $$LembretesTableTableManager($_db, $_db.lembretes).filter(
      (f) => f.veiculoPlaca.placa.sqlEquals($_itemColumn<String>('placa')!),
    );

    final cache = $_typedResult.readTableOrNull(_lembretesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VeiculosTableFilterComposer
    extends Composer<_$AppDatabase, $VeiculosTable> {
  $$VeiculosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get placa => $composableBuilder(
    column: $table.placa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apelido => $composableBuilder(
    column: $table.apelido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ano => $composableBuilder(
    column: $table.ano,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoVeiculo, TipoVeiculo, String> get tipo =>
      $composableBuilder(
        column: $table.tipo,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<
    TipoCombustivelVeiculo,
    TipoCombustivelVeiculo,
    String
  >
  get combustivel => $composableBuilder(
    column: $table.combustivel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get kmInicial => $composableBuilder(
    column: $table.kmInicial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get arquivado => $composableBuilder(
    column: $table.arquivado,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> abastecimentosRefs(
    Expression<bool> Function($$AbastecimentosTableFilterComposer f) f,
  ) {
    final $$AbastecimentosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.abastecimentos,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AbastecimentosTableFilterComposer(
            $db: $db,
            $table: $db.abastecimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> manutencoesRefs(
    Expression<bool> Function($$ManutencoesTableFilterComposer f) f,
  ) {
    final $$ManutencoesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.manutencoes,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManutencoesTableFilterComposer(
            $db: $db,
            $table: $db.manutencoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> despesasRecorrentesRefs(
    Expression<bool> Function($$DespesasRecorrentesTableFilterComposer f) f,
  ) {
    final $$DespesasRecorrentesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.despesasRecorrentes,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DespesasRecorrentesTableFilterComposer(
            $db: $db,
            $table: $db.despesasRecorrentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lembretesRefs(
    Expression<bool> Function($$LembretesTableFilterComposer f) f,
  ) {
    final $$LembretesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.lembretes,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LembretesTableFilterComposer(
            $db: $db,
            $table: $db.lembretes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VeiculosTableOrderingComposer
    extends Composer<_$AppDatabase, $VeiculosTable> {
  $$VeiculosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get placa => $composableBuilder(
    column: $table.placa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apelido => $composableBuilder(
    column: $table.apelido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marca => $composableBuilder(
    column: $table.marca,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelo => $composableBuilder(
    column: $table.modelo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ano => $composableBuilder(
    column: $table.ano,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get combustivel => $composableBuilder(
    column: $table.combustivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kmInicial => $composableBuilder(
    column: $table.kmInicial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get arquivado => $composableBuilder(
    column: $table.arquivado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VeiculosTableAnnotationComposer
    extends Composer<_$AppDatabase, $VeiculosTable> {
  $$VeiculosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get placa =>
      $composableBuilder(column: $table.placa, builder: (column) => column);

  GeneratedColumn<String> get apelido =>
      $composableBuilder(column: $table.apelido, builder: (column) => column);

  GeneratedColumn<String> get marca =>
      $composableBuilder(column: $table.marca, builder: (column) => column);

  GeneratedColumn<String> get modelo =>
      $composableBuilder(column: $table.modelo, builder: (column) => column);

  GeneratedColumn<int> get ano =>
      $composableBuilder(column: $table.ano, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoVeiculo, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoCombustivelVeiculo, String>
  get combustivel => $composableBuilder(
    column: $table.combustivel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kmInicial =>
      $composableBuilder(column: $table.kmInicial, builder: (column) => column);

  GeneratedColumn<bool> get arquivado =>
      $composableBuilder(column: $table.arquivado, builder: (column) => column);

  Expression<T> abastecimentosRefs<T extends Object>(
    Expression<T> Function($$AbastecimentosTableAnnotationComposer a) f,
  ) {
    final $$AbastecimentosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.abastecimentos,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AbastecimentosTableAnnotationComposer(
            $db: $db,
            $table: $db.abastecimentos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> manutencoesRefs<T extends Object>(
    Expression<T> Function($$ManutencoesTableAnnotationComposer a) f,
  ) {
    final $$ManutencoesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.manutencoes,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManutencoesTableAnnotationComposer(
            $db: $db,
            $table: $db.manutencoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> despesasRecorrentesRefs<T extends Object>(
    Expression<T> Function($$DespesasRecorrentesTableAnnotationComposer a) f,
  ) {
    final $$DespesasRecorrentesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.placa,
          referencedTable: $db.despesasRecorrentes,
          getReferencedColumn: (t) => t.veiculoPlaca,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DespesasRecorrentesTableAnnotationComposer(
                $db: $db,
                $table: $db.despesasRecorrentes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> lembretesRefs<T extends Object>(
    Expression<T> Function($$LembretesTableAnnotationComposer a) f,
  ) {
    final $$LembretesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placa,
      referencedTable: $db.lembretes,
      getReferencedColumn: (t) => t.veiculoPlaca,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LembretesTableAnnotationComposer(
            $db: $db,
            $table: $db.lembretes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VeiculosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VeiculosTable,
          Veiculo,
          $$VeiculosTableFilterComposer,
          $$VeiculosTableOrderingComposer,
          $$VeiculosTableAnnotationComposer,
          $$VeiculosTableCreateCompanionBuilder,
          $$VeiculosTableUpdateCompanionBuilder,
          (Veiculo, $$VeiculosTableReferences),
          Veiculo,
          PrefetchHooks Function({
            bool abastecimentosRefs,
            bool manutencoesRefs,
            bool despesasRecorrentesRefs,
            bool lembretesRefs,
          })
        > {
  $$VeiculosTableTableManager(_$AppDatabase db, $VeiculosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VeiculosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VeiculosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VeiculosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> placa = const Value.absent(),
                Value<String?> apelido = const Value.absent(),
                Value<String> marca = const Value.absent(),
                Value<String> modelo = const Value.absent(),
                Value<int> ano = const Value.absent(),
                Value<TipoVeiculo> tipo = const Value.absent(),
                Value<TipoCombustivelVeiculo> combustivel =
                    const Value.absent(),
                Value<int> kmInicial = const Value.absent(),
                Value<bool> arquivado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VeiculosCompanion(
                placa: placa,
                apelido: apelido,
                marca: marca,
                modelo: modelo,
                ano: ano,
                tipo: tipo,
                combustivel: combustivel,
                kmInicial: kmInicial,
                arquivado: arquivado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String placa,
                Value<String?> apelido = const Value.absent(),
                required String marca,
                required String modelo,
                required int ano,
                required TipoVeiculo tipo,
                required TipoCombustivelVeiculo combustivel,
                required int kmInicial,
                Value<bool> arquivado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VeiculosCompanion.insert(
                placa: placa,
                apelido: apelido,
                marca: marca,
                modelo: modelo,
                ano: ano,
                tipo: tipo,
                combustivel: combustivel,
                kmInicial: kmInicial,
                arquivado: arquivado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VeiculosTable, Veiculo>(table),
                  $$VeiculosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                abastecimentosRefs = false,
                manutencoesRefs = false,
                despesasRecorrentesRefs = false,
                lembretesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (abastecimentosRefs) db.abastecimentos,
                    if (manutencoesRefs) db.manutencoes,
                    if (despesasRecorrentesRefs) db.despesasRecorrentes,
                    if (lembretesRefs) db.lembretes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (abastecimentosRefs)
                        await $_getPrefetchedData<
                          Veiculo,
                          $VeiculosTable,
                          Abastecimento
                        >(
                          currentTable: table,
                          referencedTable: $$VeiculosTableReferences
                              ._abastecimentosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VeiculosTableReferences(
                                db,
                                table,
                                p0,
                              ).abastecimentosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.veiculoPlaca == item.placa,
                              ),
                          typedResults: items,
                        ),
                      if (manutencoesRefs)
                        await $_getPrefetchedData<
                          Veiculo,
                          $VeiculosTable,
                          Manutencao
                        >(
                          currentTable: table,
                          referencedTable: $$VeiculosTableReferences
                              ._manutencoesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VeiculosTableReferences(
                                db,
                                table,
                                p0,
                              ).manutencoesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.veiculoPlaca == item.placa,
                              ),
                          typedResults: items,
                        ),
                      if (despesasRecorrentesRefs)
                        await $_getPrefetchedData<
                          Veiculo,
                          $VeiculosTable,
                          DespesaRecorrente
                        >(
                          currentTable: table,
                          referencedTable: $$VeiculosTableReferences
                              ._despesasRecorrentesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VeiculosTableReferences(
                                db,
                                table,
                                p0,
                              ).despesasRecorrentesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.veiculoPlaca == item.placa,
                              ),
                          typedResults: items,
                        ),
                      if (lembretesRefs)
                        await $_getPrefetchedData<
                          Veiculo,
                          $VeiculosTable,
                          Lembrete
                        >(
                          currentTable: table,
                          referencedTable: $$VeiculosTableReferences
                              ._lembretesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VeiculosTableReferences(
                                db,
                                table,
                                p0,
                              ).lembretesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.veiculoPlaca == item.placa,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VeiculosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VeiculosTable,
      Veiculo,
      $$VeiculosTableFilterComposer,
      $$VeiculosTableOrderingComposer,
      $$VeiculosTableAnnotationComposer,
      $$VeiculosTableCreateCompanionBuilder,
      $$VeiculosTableUpdateCompanionBuilder,
      (Veiculo, $$VeiculosTableReferences),
      Veiculo,
      PrefetchHooks Function({
        bool abastecimentosRefs,
        bool manutencoesRefs,
        bool despesasRecorrentesRefs,
        bool lembretesRefs,
      })
    >;
typedef $$AbastecimentosTableCreateCompanionBuilder =
    AbastecimentosCompanion Function({
      Value<int> id,
      required String veiculoPlaca,
      required DateTime data,
      required int km,
      required TipoCombustivelAbastecimento tipoCombustivel,
      required double precoLitro,
      required double valorTotal,
      required double litros,
      Value<String?> posto,
      Value<bool> tanqueCheio,
    });
typedef $$AbastecimentosTableUpdateCompanionBuilder =
    AbastecimentosCompanion Function({
      Value<int> id,
      Value<String> veiculoPlaca,
      Value<DateTime> data,
      Value<int> km,
      Value<TipoCombustivelAbastecimento> tipoCombustivel,
      Value<double> precoLitro,
      Value<double> valorTotal,
      Value<double> litros,
      Value<String?> posto,
      Value<bool> tanqueCheio,
    });

final class $$AbastecimentosTableReferences
    extends BaseReferences<_$AppDatabase, $AbastecimentosTable, Abastecimento> {
  $$AbastecimentosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VeiculosTable _veiculoPlacaTable(_$AppDatabase db) =>
      db.veiculos.createAlias('abastecimentos__veiculo_placa__veiculos__placa');

  $$VeiculosTableProcessedTableManager get veiculoPlaca {
    final $_column = $_itemColumn<String>('veiculo_placa')!;

    final manager = $$VeiculosTableTableManager(
      $_db,
      $_db.veiculos,
    ).filter((f) => f.placa.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_veiculoPlacaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AbastecimentosTableFilterComposer
    extends Composer<_$AppDatabase, $AbastecimentosTable> {
  $$AbastecimentosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    TipoCombustivelAbastecimento,
    TipoCombustivelAbastecimento,
    String
  >
  get tipoCombustivel => $composableBuilder(
    column: $table.tipoCombustivel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get precoLitro => $composableBuilder(
    column: $table.precoLitro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valorTotal => $composableBuilder(
    column: $table.valorTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get litros => $composableBuilder(
    column: $table.litros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posto => $composableBuilder(
    column: $table.posto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tanqueCheio => $composableBuilder(
    column: $table.tanqueCheio,
    builder: (column) => ColumnFilters(column),
  );

  $$VeiculosTableFilterComposer get veiculoPlaca {
    final $$VeiculosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableFilterComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AbastecimentosTableOrderingComposer
    extends Composer<_$AppDatabase, $AbastecimentosTable> {
  $$AbastecimentosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoCombustivel => $composableBuilder(
    column: $table.tipoCombustivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precoLitro => $composableBuilder(
    column: $table.precoLitro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valorTotal => $composableBuilder(
    column: $table.valorTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get litros => $composableBuilder(
    column: $table.litros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posto => $composableBuilder(
    column: $table.posto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tanqueCheio => $composableBuilder(
    column: $table.tanqueCheio,
    builder: (column) => ColumnOrderings(column),
  );

  $$VeiculosTableOrderingComposer get veiculoPlaca {
    final $$VeiculosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableOrderingComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AbastecimentosTableAnnotationComposer
    extends Composer<_$AppDatabase, $AbastecimentosTable> {
  $$AbastecimentosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get km =>
      $composableBuilder(column: $table.km, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoCombustivelAbastecimento, String>
  get tipoCombustivel => $composableBuilder(
    column: $table.tipoCombustivel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precoLitro => $composableBuilder(
    column: $table.precoLitro,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valorTotal => $composableBuilder(
    column: $table.valorTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get litros =>
      $composableBuilder(column: $table.litros, builder: (column) => column);

  GeneratedColumn<String> get posto =>
      $composableBuilder(column: $table.posto, builder: (column) => column);

  GeneratedColumn<bool> get tanqueCheio => $composableBuilder(
    column: $table.tanqueCheio,
    builder: (column) => column,
  );

  $$VeiculosTableAnnotationComposer get veiculoPlaca {
    final $$VeiculosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableAnnotationComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AbastecimentosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AbastecimentosTable,
          Abastecimento,
          $$AbastecimentosTableFilterComposer,
          $$AbastecimentosTableOrderingComposer,
          $$AbastecimentosTableAnnotationComposer,
          $$AbastecimentosTableCreateCompanionBuilder,
          $$AbastecimentosTableUpdateCompanionBuilder,
          (Abastecimento, $$AbastecimentosTableReferences),
          Abastecimento,
          PrefetchHooks Function({bool veiculoPlaca})
        > {
  $$AbastecimentosTableTableManager(
    _$AppDatabase db,
    $AbastecimentosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbastecimentosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbastecimentosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbastecimentosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> veiculoPlaca = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<int> km = const Value.absent(),
                Value<TipoCombustivelAbastecimento> tipoCombustivel =
                    const Value.absent(),
                Value<double> precoLitro = const Value.absent(),
                Value<double> valorTotal = const Value.absent(),
                Value<double> litros = const Value.absent(),
                Value<String?> posto = const Value.absent(),
                Value<bool> tanqueCheio = const Value.absent(),
              }) => AbastecimentosCompanion(
                id: id,
                veiculoPlaca: veiculoPlaca,
                data: data,
                km: km,
                tipoCombustivel: tipoCombustivel,
                precoLitro: precoLitro,
                valorTotal: valorTotal,
                litros: litros,
                posto: posto,
                tanqueCheio: tanqueCheio,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String veiculoPlaca,
                required DateTime data,
                required int km,
                required TipoCombustivelAbastecimento tipoCombustivel,
                required double precoLitro,
                required double valorTotal,
                required double litros,
                Value<String?> posto = const Value.absent(),
                Value<bool> tanqueCheio = const Value.absent(),
              }) => AbastecimentosCompanion.insert(
                id: id,
                veiculoPlaca: veiculoPlaca,
                data: data,
                km: km,
                tipoCombustivel: tipoCombustivel,
                precoLitro: precoLitro,
                valorTotal: valorTotal,
                litros: litros,
                posto: posto,
                tanqueCheio: tanqueCheio,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AbastecimentosTable, Abastecimento>(table),
                  $$AbastecimentosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({veiculoPlaca = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (veiculoPlaca) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.veiculoPlaca,
                        referencedTable: $$AbastecimentosTableReferences
                            ._veiculoPlacaTable(db),
                        referencedColumn: $$AbastecimentosTableReferences
                            ._veiculoPlacaTable(db)
                            .placa,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AbastecimentosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AbastecimentosTable,
      Abastecimento,
      $$AbastecimentosTableFilterComposer,
      $$AbastecimentosTableOrderingComposer,
      $$AbastecimentosTableAnnotationComposer,
      $$AbastecimentosTableCreateCompanionBuilder,
      $$AbastecimentosTableUpdateCompanionBuilder,
      (Abastecimento, $$AbastecimentosTableReferences),
      Abastecimento,
      PrefetchHooks Function({bool veiculoPlaca})
    >;
typedef $$ManutencoesTableCreateCompanionBuilder =
    ManutencoesCompanion Function({
      Value<int> id,
      required String veiculoPlaca,
      required TipoManutencao tipo,
      Value<String?> nomeLivre,
      required DateTime data,
      required int km,
      Value<double?> valor,
      Value<String?> oficina,
      Value<String?> observacoes,
    });
typedef $$ManutencoesTableUpdateCompanionBuilder =
    ManutencoesCompanion Function({
      Value<int> id,
      Value<String> veiculoPlaca,
      Value<TipoManutencao> tipo,
      Value<String?> nomeLivre,
      Value<DateTime> data,
      Value<int> km,
      Value<double?> valor,
      Value<String?> oficina,
      Value<String?> observacoes,
    });

final class $$ManutencoesTableReferences
    extends BaseReferences<_$AppDatabase, $ManutencoesTable, Manutencao> {
  $$ManutencoesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VeiculosTable _veiculoPlacaTable(_$AppDatabase db) =>
      db.veiculos.createAlias('manutencoes__veiculo_placa__veiculos__placa');

  $$VeiculosTableProcessedTableManager get veiculoPlaca {
    final $_column = $_itemColumn<String>('veiculo_placa')!;

    final manager = $$VeiculosTableTableManager(
      $_db,
      $_db.veiculos,
    ).filter((f) => f.placa.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_veiculoPlacaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LembretesTable, List<Lembrete>>
  _lembretesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lembretes,
    aliasName: 'manutencoes__id__lembretes__manutencao_id',
  );

  $$LembretesTableProcessedTableManager get lembretesRefs {
    final manager = $$LembretesTableTableManager(
      $_db,
      $_db.lembretes,
    ).filter((f) => f.manutencaoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lembretesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ManutencoesTableFilterComposer
    extends Composer<_$AppDatabase, $ManutencoesTable> {
  $$ManutencoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TipoManutencao, TipoManutencao, String>
  get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get nomeLivre => $composableBuilder(
    column: $table.nomeLivre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oficina => $composableBuilder(
    column: $table.oficina,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnFilters(column),
  );

  $$VeiculosTableFilterComposer get veiculoPlaca {
    final $$VeiculosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableFilterComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lembretesRefs(
    Expression<bool> Function($$LembretesTableFilterComposer f) f,
  ) {
    final $$LembretesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lembretes,
      getReferencedColumn: (t) => t.manutencaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LembretesTableFilterComposer(
            $db: $db,
            $table: $db.lembretes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ManutencoesTableOrderingComposer
    extends Composer<_$AppDatabase, $ManutencoesTable> {
  $$ManutencoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomeLivre => $composableBuilder(
    column: $table.nomeLivre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get km => $composableBuilder(
    column: $table.km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oficina => $composableBuilder(
    column: $table.oficina,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => ColumnOrderings(column),
  );

  $$VeiculosTableOrderingComposer get veiculoPlaca {
    final $$VeiculosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableOrderingComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ManutencoesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManutencoesTable> {
  $$ManutencoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TipoManutencao, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get nomeLivre =>
      $composableBuilder(column: $table.nomeLivre, builder: (column) => column);

  GeneratedColumn<DateTime> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get km =>
      $composableBuilder(column: $table.km, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get oficina =>
      $composableBuilder(column: $table.oficina, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
    column: $table.observacoes,
    builder: (column) => column,
  );

  $$VeiculosTableAnnotationComposer get veiculoPlaca {
    final $$VeiculosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableAnnotationComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lembretesRefs<T extends Object>(
    Expression<T> Function($$LembretesTableAnnotationComposer a) f,
  ) {
    final $$LembretesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lembretes,
      getReferencedColumn: (t) => t.manutencaoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LembretesTableAnnotationComposer(
            $db: $db,
            $table: $db.lembretes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ManutencoesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManutencoesTable,
          Manutencao,
          $$ManutencoesTableFilterComposer,
          $$ManutencoesTableOrderingComposer,
          $$ManutencoesTableAnnotationComposer,
          $$ManutencoesTableCreateCompanionBuilder,
          $$ManutencoesTableUpdateCompanionBuilder,
          (Manutencao, $$ManutencoesTableReferences),
          Manutencao,
          PrefetchHooks Function({bool veiculoPlaca, bool lembretesRefs})
        > {
  $$ManutencoesTableTableManager(_$AppDatabase db, $ManutencoesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManutencoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManutencoesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManutencoesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> veiculoPlaca = const Value.absent(),
                Value<TipoManutencao> tipo = const Value.absent(),
                Value<String?> nomeLivre = const Value.absent(),
                Value<DateTime> data = const Value.absent(),
                Value<int> km = const Value.absent(),
                Value<double?> valor = const Value.absent(),
                Value<String?> oficina = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
              }) => ManutencoesCompanion(
                id: id,
                veiculoPlaca: veiculoPlaca,
                tipo: tipo,
                nomeLivre: nomeLivre,
                data: data,
                km: km,
                valor: valor,
                oficina: oficina,
                observacoes: observacoes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String veiculoPlaca,
                required TipoManutencao tipo,
                Value<String?> nomeLivre = const Value.absent(),
                required DateTime data,
                required int km,
                Value<double?> valor = const Value.absent(),
                Value<String?> oficina = const Value.absent(),
                Value<String?> observacoes = const Value.absent(),
              }) => ManutencoesCompanion.insert(
                id: id,
                veiculoPlaca: veiculoPlaca,
                tipo: tipo,
                nomeLivre: nomeLivre,
                data: data,
                km: km,
                valor: valor,
                oficina: oficina,
                observacoes: observacoes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ManutencoesTable, Manutencao>(table),
                  $$ManutencoesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({veiculoPlaca = false, lembretesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (lembretesRefs) db.lembretes],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (veiculoPlaca) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.veiculoPlaca,
                            referencedTable: $$ManutencoesTableReferences
                                ._veiculoPlacaTable(db),
                            referencedColumn: $$ManutencoesTableReferences
                                ._veiculoPlacaTable(db)
                                .placa,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lembretesRefs)
                        await $_getPrefetchedData<
                          Manutencao,
                          $ManutencoesTable,
                          Lembrete
                        >(
                          currentTable: table,
                          referencedTable: $$ManutencoesTableReferences
                              ._lembretesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ManutencoesTableReferences(
                                db,
                                table,
                                p0,
                              ).lembretesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.manutencaoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ManutencoesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManutencoesTable,
      Manutencao,
      $$ManutencoesTableFilterComposer,
      $$ManutencoesTableOrderingComposer,
      $$ManutencoesTableAnnotationComposer,
      $$ManutencoesTableCreateCompanionBuilder,
      $$ManutencoesTableUpdateCompanionBuilder,
      (Manutencao, $$ManutencoesTableReferences),
      Manutencao,
      PrefetchHooks Function({bool veiculoPlaca, bool lembretesRefs})
    >;
typedef $$DespesasRecorrentesTableCreateCompanionBuilder =
    DespesasRecorrentesCompanion Function({
      Value<int> id,
      required String veiculoPlaca,
      required String nome,
      required CategoriaDespesa categoria,
      required double valor,
      required FrequenciaDespesa frequencia,
      required DateTime dataInicio,
      Value<DateTime?> dataFim,
    });
typedef $$DespesasRecorrentesTableUpdateCompanionBuilder =
    DespesasRecorrentesCompanion Function({
      Value<int> id,
      Value<String> veiculoPlaca,
      Value<String> nome,
      Value<CategoriaDespesa> categoria,
      Value<double> valor,
      Value<FrequenciaDespesa> frequencia,
      Value<DateTime> dataInicio,
      Value<DateTime?> dataFim,
    });

final class $$DespesasRecorrentesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DespesasRecorrentesTable,
          DespesaRecorrente
        > {
  $$DespesasRecorrentesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VeiculosTable _veiculoPlacaTable(_$AppDatabase db) => db.veiculos
      .createAlias('despesas_recorrentes__veiculo_placa__veiculos__placa');

  $$VeiculosTableProcessedTableManager get veiculoPlaca {
    final $_column = $_itemColumn<String>('veiculo_placa')!;

    final manager = $$VeiculosTableTableManager(
      $_db,
      $_db.veiculos,
    ).filter((f) => f.placa.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_veiculoPlacaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OcorrenciasDespesaTable, List<OcorrenciaDespesa>>
  _ocorrenciasDespesaRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ocorrenciasDespesa,
        aliasName: 'despesas_recorrentes__id__ocorrencias_despesa__despesa_id',
      );

  $$OcorrenciasDespesaTableProcessedTableManager get ocorrenciasDespesaRefs {
    final manager = $$OcorrenciasDespesaTableTableManager(
      $_db,
      $_db.ocorrenciasDespesa,
    ).filter((f) => f.despesaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ocorrenciasDespesaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DespesasRecorrentesTableFilterComposer
    extends Composer<_$AppDatabase, $DespesasRecorrentesTable> {
  $$DespesasRecorrentesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoriaDespesa, CategoriaDespesa, String>
  get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FrequenciaDespesa, FrequenciaDespesa, String>
  get frequencia => $composableBuilder(
    column: $table.frequencia,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataFim => $composableBuilder(
    column: $table.dataFim,
    builder: (column) => ColumnFilters(column),
  );

  $$VeiculosTableFilterComposer get veiculoPlaca {
    final $$VeiculosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableFilterComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ocorrenciasDespesaRefs(
    Expression<bool> Function($$OcorrenciasDespesaTableFilterComposer f) f,
  ) {
    final $$OcorrenciasDespesaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ocorrenciasDespesa,
      getReferencedColumn: (t) => t.despesaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OcorrenciasDespesaTableFilterComposer(
            $db: $db,
            $table: $db.ocorrenciasDespesa,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DespesasRecorrentesTableOrderingComposer
    extends Composer<_$AppDatabase, $DespesasRecorrentesTable> {
  $$DespesasRecorrentesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencia => $composableBuilder(
    column: $table.frequencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataFim => $composableBuilder(
    column: $table.dataFim,
    builder: (column) => ColumnOrderings(column),
  );

  $$VeiculosTableOrderingComposer get veiculoPlaca {
    final $$VeiculosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableOrderingComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DespesasRecorrentesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DespesasRecorrentesTable> {
  $$DespesasRecorrentesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoriaDespesa, String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FrequenciaDespesa, String> get frequencia =>
      $composableBuilder(
        column: $table.frequencia,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get dataInicio => $composableBuilder(
    column: $table.dataInicio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataFim =>
      $composableBuilder(column: $table.dataFim, builder: (column) => column);

  $$VeiculosTableAnnotationComposer get veiculoPlaca {
    final $$VeiculosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableAnnotationComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ocorrenciasDespesaRefs<T extends Object>(
    Expression<T> Function($$OcorrenciasDespesaTableAnnotationComposer a) f,
  ) {
    final $$OcorrenciasDespesaTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ocorrenciasDespesa,
          getReferencedColumn: (t) => t.despesaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OcorrenciasDespesaTableAnnotationComposer(
                $db: $db,
                $table: $db.ocorrenciasDespesa,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DespesasRecorrentesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DespesasRecorrentesTable,
          DespesaRecorrente,
          $$DespesasRecorrentesTableFilterComposer,
          $$DespesasRecorrentesTableOrderingComposer,
          $$DespesasRecorrentesTableAnnotationComposer,
          $$DespesasRecorrentesTableCreateCompanionBuilder,
          $$DespesasRecorrentesTableUpdateCompanionBuilder,
          (DespesaRecorrente, $$DespesasRecorrentesTableReferences),
          DespesaRecorrente,
          PrefetchHooks Function({
            bool veiculoPlaca,
            bool ocorrenciasDespesaRefs,
          })
        > {
  $$DespesasRecorrentesTableTableManager(
    _$AppDatabase db,
    $DespesasRecorrentesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DespesasRecorrentesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DespesasRecorrentesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DespesasRecorrentesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> veiculoPlaca = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<CategoriaDespesa> categoria = const Value.absent(),
                Value<double> valor = const Value.absent(),
                Value<FrequenciaDespesa> frequencia = const Value.absent(),
                Value<DateTime> dataInicio = const Value.absent(),
                Value<DateTime?> dataFim = const Value.absent(),
              }) => DespesasRecorrentesCompanion(
                id: id,
                veiculoPlaca: veiculoPlaca,
                nome: nome,
                categoria: categoria,
                valor: valor,
                frequencia: frequencia,
                dataInicio: dataInicio,
                dataFim: dataFim,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String veiculoPlaca,
                required String nome,
                required CategoriaDespesa categoria,
                required double valor,
                required FrequenciaDespesa frequencia,
                required DateTime dataInicio,
                Value<DateTime?> dataFim = const Value.absent(),
              }) => DespesasRecorrentesCompanion.insert(
                id: id,
                veiculoPlaca: veiculoPlaca,
                nome: nome,
                categoria: categoria,
                valor: valor,
                frequencia: frequencia,
                dataInicio: dataInicio,
                dataFim: dataFim,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DespesasRecorrentesTable, DespesaRecorrente>(
                    table,
                  ),
                  $$DespesasRecorrentesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({veiculoPlaca = false, ocorrenciasDespesaRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ocorrenciasDespesaRefs) db.ocorrenciasDespesa,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (veiculoPlaca) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.veiculoPlaca,
                            referencedTable:
                                $$DespesasRecorrentesTableReferences
                                    ._veiculoPlacaTable(db),
                            referencedColumn:
                                $$DespesasRecorrentesTableReferences
                                    ._veiculoPlacaTable(db)
                                    .placa,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ocorrenciasDespesaRefs)
                        await $_getPrefetchedData<
                          DespesaRecorrente,
                          $DespesasRecorrentesTable,
                          OcorrenciaDespesa
                        >(
                          currentTable: table,
                          referencedTable: $$DespesasRecorrentesTableReferences
                              ._ocorrenciasDespesaRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DespesasRecorrentesTableReferences(
                                db,
                                table,
                                p0,
                              ).ocorrenciasDespesaRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.despesaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DespesasRecorrentesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DespesasRecorrentesTable,
      DespesaRecorrente,
      $$DespesasRecorrentesTableFilterComposer,
      $$DespesasRecorrentesTableOrderingComposer,
      $$DespesasRecorrentesTableAnnotationComposer,
      $$DespesasRecorrentesTableCreateCompanionBuilder,
      $$DespesasRecorrentesTableUpdateCompanionBuilder,
      (DespesaRecorrente, $$DespesasRecorrentesTableReferences),
      DespesaRecorrente,
      PrefetchHooks Function({bool veiculoPlaca, bool ocorrenciasDespesaRefs})
    >;
typedef $$OcorrenciasDespesaTableCreateCompanionBuilder =
    OcorrenciasDespesaCompanion Function({
      Value<int> id,
      required int despesaId,
      required DateTime dataVencimento,
      Value<DateTime?> dataPagamento,
      Value<double?> valorPago,
      required StatusOcorrencia status,
    });
typedef $$OcorrenciasDespesaTableUpdateCompanionBuilder =
    OcorrenciasDespesaCompanion Function({
      Value<int> id,
      Value<int> despesaId,
      Value<DateTime> dataVencimento,
      Value<DateTime?> dataPagamento,
      Value<double?> valorPago,
      Value<StatusOcorrencia> status,
    });

final class $$OcorrenciasDespesaTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OcorrenciasDespesaTable,
          OcorrenciaDespesa
        > {
  $$OcorrenciasDespesaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DespesasRecorrentesTable _despesaIdTable(_$AppDatabase db) => db
      .despesasRecorrentes
      .createAlias('ocorrencias_despesa__despesa_id__despesas_recorrentes__id');

  $$DespesasRecorrentesTableProcessedTableManager get despesaId {
    final $_column = $_itemColumn<int>('despesa_id')!;

    final manager = $$DespesasRecorrentesTableTableManager(
      $_db,
      $_db.despesasRecorrentes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_despesaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OcorrenciasDespesaTableFilterComposer
    extends Composer<_$AppDatabase, $OcorrenciasDespesaTable> {
  $$OcorrenciasDespesaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataVencimento => $composableBuilder(
    column: $table.dataVencimento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataPagamento => $composableBuilder(
    column: $table.dataPagamento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valorPago => $composableBuilder(
    column: $table.valorPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StatusOcorrencia, StatusOcorrencia, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$DespesasRecorrentesTableFilterComposer get despesaId {
    final $$DespesasRecorrentesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.despesaId,
      referencedTable: $db.despesasRecorrentes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DespesasRecorrentesTableFilterComposer(
            $db: $db,
            $table: $db.despesasRecorrentes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OcorrenciasDespesaTableOrderingComposer
    extends Composer<_$AppDatabase, $OcorrenciasDespesaTable> {
  $$OcorrenciasDespesaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataVencimento => $composableBuilder(
    column: $table.dataVencimento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataPagamento => $composableBuilder(
    column: $table.dataPagamento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valorPago => $composableBuilder(
    column: $table.valorPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$DespesasRecorrentesTableOrderingComposer get despesaId {
    final $$DespesasRecorrentesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.despesaId,
          referencedTable: $db.despesasRecorrentes,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DespesasRecorrentesTableOrderingComposer(
                $db: $db,
                $table: $db.despesasRecorrentes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OcorrenciasDespesaTableAnnotationComposer
    extends Composer<_$AppDatabase, $OcorrenciasDespesaTable> {
  $$OcorrenciasDespesaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get dataVencimento => $composableBuilder(
    column: $table.dataVencimento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataPagamento => $composableBuilder(
    column: $table.dataPagamento,
    builder: (column) => column,
  );

  GeneratedColumn<double> get valorPago =>
      $composableBuilder(column: $table.valorPago, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StatusOcorrencia, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$DespesasRecorrentesTableAnnotationComposer get despesaId {
    final $$DespesasRecorrentesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.despesaId,
          referencedTable: $db.despesasRecorrentes,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DespesasRecorrentesTableAnnotationComposer(
                $db: $db,
                $table: $db.despesasRecorrentes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OcorrenciasDespesaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OcorrenciasDespesaTable,
          OcorrenciaDespesa,
          $$OcorrenciasDespesaTableFilterComposer,
          $$OcorrenciasDespesaTableOrderingComposer,
          $$OcorrenciasDespesaTableAnnotationComposer,
          $$OcorrenciasDespesaTableCreateCompanionBuilder,
          $$OcorrenciasDespesaTableUpdateCompanionBuilder,
          (OcorrenciaDespesa, $$OcorrenciasDespesaTableReferences),
          OcorrenciaDespesa,
          PrefetchHooks Function({bool despesaId})
        > {
  $$OcorrenciasDespesaTableTableManager(
    _$AppDatabase db,
    $OcorrenciasDespesaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OcorrenciasDespesaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OcorrenciasDespesaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OcorrenciasDespesaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> despesaId = const Value.absent(),
                Value<DateTime> dataVencimento = const Value.absent(),
                Value<DateTime?> dataPagamento = const Value.absent(),
                Value<double?> valorPago = const Value.absent(),
                Value<StatusOcorrencia> status = const Value.absent(),
              }) => OcorrenciasDespesaCompanion(
                id: id,
                despesaId: despesaId,
                dataVencimento: dataVencimento,
                dataPagamento: dataPagamento,
                valorPago: valorPago,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int despesaId,
                required DateTime dataVencimento,
                Value<DateTime?> dataPagamento = const Value.absent(),
                Value<double?> valorPago = const Value.absent(),
                required StatusOcorrencia status,
              }) => OcorrenciasDespesaCompanion.insert(
                id: id,
                despesaId: despesaId,
                dataVencimento: dataVencimento,
                dataPagamento: dataPagamento,
                valorPago: valorPago,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OcorrenciasDespesaTable, OcorrenciaDespesa>(
                    table,
                  ),
                  $$OcorrenciasDespesaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({despesaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (despesaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.despesaId,
                        referencedTable: $$OcorrenciasDespesaTableReferences
                            ._despesaIdTable(db),
                        referencedColumn: $$OcorrenciasDespesaTableReferences
                            ._despesaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OcorrenciasDespesaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OcorrenciasDespesaTable,
      OcorrenciaDespesa,
      $$OcorrenciasDespesaTableFilterComposer,
      $$OcorrenciasDespesaTableOrderingComposer,
      $$OcorrenciasDespesaTableAnnotationComposer,
      $$OcorrenciasDespesaTableCreateCompanionBuilder,
      $$OcorrenciasDespesaTableUpdateCompanionBuilder,
      (OcorrenciaDespesa, $$OcorrenciasDespesaTableReferences),
      OcorrenciaDespesa,
      PrefetchHooks Function({bool despesaId})
    >;
typedef $$LembretesTableCreateCompanionBuilder = LembretesCompanion Function({
  Value<int> id,
  required String veiculoPlaca,
  Value<int?> manutencaoId,
  required String tipo,
  required String descricao,
  Value<DateTime?> dataAlvo,
  Value<int?> kmAlvo,
  required StatusLembrete status,
});
typedef $$LembretesTableUpdateCompanionBuilder = LembretesCompanion Function({
  Value<int> id,
  Value<String> veiculoPlaca,
  Value<int?> manutencaoId,
  Value<String> tipo,
  Value<String> descricao,
  Value<DateTime?> dataAlvo,
  Value<int?> kmAlvo,
  Value<StatusLembrete> status,
});

final class $$LembretesTableReferences
    extends BaseReferences<_$AppDatabase, $LembretesTable, Lembrete> {
  $$LembretesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VeiculosTable _veiculoPlacaTable(_$AppDatabase db) =>
      db.veiculos.createAlias('lembretes__veiculo_placa__veiculos__placa');

  $$VeiculosTableProcessedTableManager get veiculoPlaca {
    final $_column = $_itemColumn<String>('veiculo_placa')!;

    final manager = $$VeiculosTableTableManager(
      $_db,
      $_db.veiculos,
    ).filter((f) => f.placa.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_veiculoPlacaTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ManutencoesTable _manutencaoIdTable(_$AppDatabase db) =>
      db.manutencoes.createAlias('lembretes__manutencao_id__manutencoes__id');

  $$ManutencoesTableProcessedTableManager? get manutencaoId {
    final $_column = $_itemColumn<int>('manutencao_id');
    if ($_column == null) return null;
    final manager = $$ManutencoesTableTableManager(
      $_db,
      $_db.manutencoes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_manutencaoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LembretesTableFilterComposer
    extends Composer<_$AppDatabase, $LembretesTable> {
  $$LembretesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataAlvo => $composableBuilder(
    column: $table.dataAlvo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kmAlvo => $composableBuilder(
    column: $table.kmAlvo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StatusLembrete, StatusLembrete, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$VeiculosTableFilterComposer get veiculoPlaca {
    final $$VeiculosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableFilterComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ManutencoesTableFilterComposer get manutencaoId {
    final $$ManutencoesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.manutencaoId,
      referencedTable: $db.manutencoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManutencoesTableFilterComposer(
            $db: $db,
            $table: $db.manutencoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LembretesTableOrderingComposer
    extends Composer<_$AppDatabase, $LembretesTable> {
  $$LembretesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataAlvo => $composableBuilder(
    column: $table.dataAlvo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kmAlvo => $composableBuilder(
    column: $table.kmAlvo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$VeiculosTableOrderingComposer get veiculoPlaca {
    final $$VeiculosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableOrderingComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ManutencoesTableOrderingComposer get manutencaoId {
    final $$ManutencoesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.manutencaoId,
      referencedTable: $db.manutencoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManutencoesTableOrderingComposer(
            $db: $db,
            $table: $db.manutencoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LembretesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LembretesTable> {
  $$LembretesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<DateTime> get dataAlvo =>
      $composableBuilder(column: $table.dataAlvo, builder: (column) => column);

  GeneratedColumn<int> get kmAlvo =>
      $composableBuilder(column: $table.kmAlvo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StatusLembrete, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$VeiculosTableAnnotationComposer get veiculoPlaca {
    final $$VeiculosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.veiculoPlaca,
      referencedTable: $db.veiculos,
      getReferencedColumn: (t) => t.placa,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VeiculosTableAnnotationComposer(
            $db: $db,
            $table: $db.veiculos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ManutencoesTableAnnotationComposer get manutencaoId {
    final $$ManutencoesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.manutencaoId,
      referencedTable: $db.manutencoes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManutencoesTableAnnotationComposer(
            $db: $db,
            $table: $db.manutencoes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LembretesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LembretesTable,
          Lembrete,
          $$LembretesTableFilterComposer,
          $$LembretesTableOrderingComposer,
          $$LembretesTableAnnotationComposer,
          $$LembretesTableCreateCompanionBuilder,
          $$LembretesTableUpdateCompanionBuilder,
          (Lembrete, $$LembretesTableReferences),
          Lembrete,
          PrefetchHooks Function({bool veiculoPlaca, bool manutencaoId})
        > {
  $$LembretesTableTableManager(_$AppDatabase db, $LembretesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LembretesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LembretesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LembretesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> veiculoPlaca = const Value.absent(),
                Value<int?> manutencaoId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<DateTime?> dataAlvo = const Value.absent(),
                Value<int?> kmAlvo = const Value.absent(),
                Value<StatusLembrete> status = const Value.absent(),
              }) => LembretesCompanion(
                id: id,
                veiculoPlaca: veiculoPlaca,
                manutencaoId: manutencaoId,
                tipo: tipo,
                descricao: descricao,
                dataAlvo: dataAlvo,
                kmAlvo: kmAlvo,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String veiculoPlaca,
                Value<int?> manutencaoId = const Value.absent(),
                required String tipo,
                required String descricao,
                Value<DateTime?> dataAlvo = const Value.absent(),
                Value<int?> kmAlvo = const Value.absent(),
                required StatusLembrete status,
              }) => LembretesCompanion.insert(
                id: id,
                veiculoPlaca: veiculoPlaca,
                manutencaoId: manutencaoId,
                tipo: tipo,
                descricao: descricao,
                dataAlvo: dataAlvo,
                kmAlvo: kmAlvo,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LembretesTable, Lembrete>(table),
                  $$LembretesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({veiculoPlaca = false, manutencaoId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (veiculoPlaca) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.veiculoPlaca,
                            referencedTable: $$LembretesTableReferences
                                ._veiculoPlacaTable(db),
                            referencedColumn: $$LembretesTableReferences
                                ._veiculoPlacaTable(db)
                                .placa,
                          ) as T;
                        }
                        if (manutencaoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.manutencaoId,
                            referencedTable: $$LembretesTableReferences
                                ._manutencaoIdTable(db),
                            referencedColumn: $$LembretesTableReferences
                                ._manutencaoIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LembretesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LembretesTable,
      Lembrete,
      $$LembretesTableFilterComposer,
      $$LembretesTableOrderingComposer,
      $$LembretesTableAnnotationComposer,
      $$LembretesTableCreateCompanionBuilder,
      $$LembretesTableUpdateCompanionBuilder,
      (Lembrete, $$LembretesTableReferences),
      Lembrete,
      PrefetchHooks Function({bool veiculoPlaca, bool manutencaoId})
    >;
typedef $$PostosSugestaoTableCreateCompanionBuilder =
    PostosSugestaoCompanion Function({required String nome, Value<int> rowid});
typedef $$PostosSugestaoTableUpdateCompanionBuilder =
    PostosSugestaoCompanion Function({Value<String> nome, Value<int> rowid});

class $$PostosSugestaoTableFilterComposer
    extends Composer<_$AppDatabase, $PostosSugestaoTable> {
  $$PostosSugestaoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PostosSugestaoTableOrderingComposer
    extends Composer<_$AppDatabase, $PostosSugestaoTable> {
  $$PostosSugestaoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PostosSugestaoTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostosSugestaoTable> {
  $$PostosSugestaoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);
}

class $$PostosSugestaoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostosSugestaoTable,
          PostoSugestao,
          $$PostosSugestaoTableFilterComposer,
          $$PostosSugestaoTableOrderingComposer,
          $$PostosSugestaoTableAnnotationComposer,
          $$PostosSugestaoTableCreateCompanionBuilder,
          $$PostosSugestaoTableUpdateCompanionBuilder,
          (
            PostoSugestao,
            BaseReferences<_$AppDatabase, $PostosSugestaoTable, PostoSugestao>,
          ),
          PostoSugestao,
          PrefetchHooks Function()
        > {
  $$PostosSugestaoTableTableManager(
    _$AppDatabase db,
    $PostosSugestaoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostosSugestaoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostosSugestaoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostosSugestaoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> nome = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PostosSugestaoCompanion(nome: nome, rowid: rowid),
          createCompanionCallback: ({
            required String nome,
            Value<int> rowid = const Value.absent(),
          }) => PostosSugestaoCompanion.insert(nome: nome, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PostosSugestaoTable, PostoSugestao>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PostosSugestaoTable,
                    PostoSugestao
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PostosSugestaoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostosSugestaoTable,
      PostoSugestao,
      $$PostosSugestaoTableFilterComposer,
      $$PostosSugestaoTableOrderingComposer,
      $$PostosSugestaoTableAnnotationComposer,
      $$PostosSugestaoTableCreateCompanionBuilder,
      $$PostosSugestaoTableUpdateCompanionBuilder,
      (
        PostoSugestao,
        BaseReferences<_$AppDatabase, $PostosSugestaoTable, PostoSugestao>,
      ),
      PostoSugestao,
      PrefetchHooks Function()
    >;
typedef $$TiposManutencaoPadraoTableCreateCompanionBuilder =
    TiposManutencaoPadraoCompanion Function({
      required TipoManutencao tipo,
      Value<int?> intervaloKm,
      Value<int?> intervaloMeses,
      Value<int> rowid,
    });
typedef $$TiposManutencaoPadraoTableUpdateCompanionBuilder =
    TiposManutencaoPadraoCompanion Function({
      Value<TipoManutencao> tipo,
      Value<int?> intervaloKm,
      Value<int?> intervaloMeses,
      Value<int> rowid,
    });

class $$TiposManutencaoPadraoTableFilterComposer
    extends Composer<_$AppDatabase, $TiposManutencaoPadraoTable> {
  $$TiposManutencaoPadraoTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<TipoManutencao, TipoManutencao, String>
  get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get intervaloKm => $composableBuilder(
    column: $table.intervaloKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervaloMeses => $composableBuilder(
    column: $table.intervaloMeses,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TiposManutencaoPadraoTableOrderingComposer
    extends Composer<_$AppDatabase, $TiposManutencaoPadraoTable> {
  $$TiposManutencaoPadraoTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervaloKm => $composableBuilder(
    column: $table.intervaloKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervaloMeses => $composableBuilder(
    column: $table.intervaloMeses,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TiposManutencaoPadraoTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiposManutencaoPadraoTable> {
  $$TiposManutencaoPadraoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<TipoManutencao, String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<int> get intervaloKm => $composableBuilder(
    column: $table.intervaloKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervaloMeses => $composableBuilder(
    column: $table.intervaloMeses,
    builder: (column) => column,
  );
}

class $$TiposManutencaoPadraoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TiposManutencaoPadraoTable,
          TipoManutencaoPadrao,
          $$TiposManutencaoPadraoTableFilterComposer,
          $$TiposManutencaoPadraoTableOrderingComposer,
          $$TiposManutencaoPadraoTableAnnotationComposer,
          $$TiposManutencaoPadraoTableCreateCompanionBuilder,
          $$TiposManutencaoPadraoTableUpdateCompanionBuilder,
          (
            TipoManutencaoPadrao,
            BaseReferences<
              _$AppDatabase,
              $TiposManutencaoPadraoTable,
              TipoManutencaoPadrao
            >,
          ),
          TipoManutencaoPadrao,
          PrefetchHooks Function()
        > {
  $$TiposManutencaoPadraoTableTableManager(
    _$AppDatabase db,
    $TiposManutencaoPadraoTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiposManutencaoPadraoTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TiposManutencaoPadraoTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TiposManutencaoPadraoTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<TipoManutencao> tipo = const Value.absent(),
                Value<int?> intervaloKm = const Value.absent(),
                Value<int?> intervaloMeses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposManutencaoPadraoCompanion(
                tipo: tipo,
                intervaloKm: intervaloKm,
                intervaloMeses: intervaloMeses,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required TipoManutencao tipo,
                Value<int?> intervaloKm = const Value.absent(),
                Value<int?> intervaloMeses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TiposManutencaoPadraoCompanion.insert(
                tipo: tipo,
                intervaloKm: intervaloKm,
                intervaloMeses: intervaloMeses,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TiposManutencaoPadraoTable,
                    TipoManutencaoPadrao
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TiposManutencaoPadraoTable,
                    TipoManutencaoPadrao
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TiposManutencaoPadraoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TiposManutencaoPadraoTable,
      TipoManutencaoPadrao,
      $$TiposManutencaoPadraoTableFilterComposer,
      $$TiposManutencaoPadraoTableOrderingComposer,
      $$TiposManutencaoPadraoTableAnnotationComposer,
      $$TiposManutencaoPadraoTableCreateCompanionBuilder,
      $$TiposManutencaoPadraoTableUpdateCompanionBuilder,
      (
        TipoManutencaoPadrao,
        BaseReferences<
          _$AppDatabase,
          $TiposManutencaoPadraoTable,
          TipoManutencaoPadrao
        >,
      ),
      TipoManutencaoPadrao,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VeiculosTableTableManager get veiculos =>
      $$VeiculosTableTableManager(_db, _db.veiculos);
  $$AbastecimentosTableTableManager get abastecimentos =>
      $$AbastecimentosTableTableManager(_db, _db.abastecimentos);
  $$ManutencoesTableTableManager get manutencoes =>
      $$ManutencoesTableTableManager(_db, _db.manutencoes);
  $$DespesasRecorrentesTableTableManager get despesasRecorrentes =>
      $$DespesasRecorrentesTableTableManager(_db, _db.despesasRecorrentes);
  $$OcorrenciasDespesaTableTableManager get ocorrenciasDespesa =>
      $$OcorrenciasDespesaTableTableManager(_db, _db.ocorrenciasDespesa);
  $$LembretesTableTableManager get lembretes =>
      $$LembretesTableTableManager(_db, _db.lembretes);
  $$PostosSugestaoTableTableManager get postosSugestao =>
      $$PostosSugestaoTableTableManager(_db, _db.postosSugestao);
  $$TiposManutencaoPadraoTableTableManager get tiposManutencaoPadrao =>
      $$TiposManutencaoPadraoTableTableManager(_db, _db.tiposManutencaoPadrao);
}
