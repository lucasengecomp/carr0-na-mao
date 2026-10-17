import 'package:carro_na_mao/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Delegates de localização a serem passados para os MaterialApp nos testes
/// de widget. Necessário após a migração para flutter_localizations (issue #34).
const List<LocalizationsDelegate<dynamic>> l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Locales suportados — deve ser incluído junto com [l10nDelegates] para que
/// o MaterialApp não caia no locale do sistema (inglês).
const List<Locale> supportedLocales = [Locale('pt'), Locale('en')];

/// Locale padrão pt para testes.
const Locale localeDefault = Locale('pt');
