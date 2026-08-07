import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Seleciona o ambiente em tempo de compilação.
///
/// Defina o ambiente ao rodar/buildar o app:
///   flutter run --dart-define=ENVIRONMENT=production
///   flutter build apk --dart-define=ENVIRONMENT=production
///
/// Quando omitido, assume `development` por segurança (usa anúncios de teste).
const _kEnvironmentName =
    String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

/// Nome do arquivo JSON do ambiente correspondente na pasta `env/`.
String get _environmentFileName {
  switch (_kEnvironmentName) {
    case 'production':
      return 'env/production_environment.json';
    case 'development':
    default:
      return 'env/development_environment.json';
  }
}

/// Configurações lidas do arquivo JSON do ambiente atual (`env/`).
///
/// É inicializada uma única vez em [main] através de [Environment.initialize],
/// antes do `runApp`. Depois disso os valores ficam disponíveis de forma
/// síncrona via [Environment.instance].
class Environment {
  Environment._();

  static final Environment instance = Environment._();

  /// Indica se [initialize] já foi executada com sucesso.
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Nome do ambiente ("development" ou "production").
  late final String environment;

  /// Configurações do AdMob.
  late final AdMobConfig adMob;

  /// Carrega o JSON do ambiente selecionado por `--dart-define=ENVIRONMENT=...`.
  ///
  /// Deve ser chamado antes do `runApp` (ver [main]).
  Future<void> initialize() async {
    if (_initialized) return;

    final raw = await rootBundle.loadString(_environmentFileName);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    environment = json['environment'] as String? ?? _kEnvironmentName;
    adMob = AdMobConfig.fromJson(
      json['adMob'] as Map<String, dynamic>? ?? const {},
    );

    _initialized = true;
  }
}

/// Configurações do AdMob por ambiente.
class AdMobConfig {
  const AdMobConfig({required this.bannerAdUnitId});

  factory AdMobConfig.fromJson(Map<String, dynamic> json) {
    return AdMobConfig(
      bannerAdUnitId:
          json['bannerAdUnitId'] as String? ?? 'ca-app-pub-3940256099942544/6300978111',
    );
  }

  /// ID do bloco de anúncios banner. Em desenvolvimento deve apontar para o
  /// bloco de teste do Google para evitar cliques inválidos.
  final String bannerAdUnitId;
}
