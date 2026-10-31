import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;

/// Configurações de ambiente.
///
/// As chaves ficam **exclusivamente** em arquivos JSON dentro de `env/` na
/// raiz do projeto:
///   - `env/development_environment.json`
///   - `env/production_environment.json`
///
/// O ambiente é escolhido automaticamente pelo modo de build:
///   - **Release** (ex.: `flutter build apk --release`) → `production`
///   - **Debug/Profile** (ex.: `flutter run`) → `development`
///
/// Isso garante que um build de produção use as chaves reais mesmo sem
/// passar nenhum argumento extra. Para forçar/sobrescrever manualmente, use:
///
///   --dart-define=ENVIRONMENT=production
///   --dart-define-from-file=env/production_environment.json
///
/// Os JSONs são lidos em runtime (declarados como assets no `pubspec.yaml`),
/// então o [Environment.initialize] precisa ser chamado em `main` antes do
/// `runApp`. Depois disso os valores ficam disponíveis de forma síncrona.
///
/// **Não há chaves hardcoded no código.** Se o JSON do ambiente não puder ser
/// lido ou faltar uma chave, [initialize] lança um erro explícito — prefira
/// falhar cedo a servir a chave errada em produção.
class Environment {
  Environment._();

  static final Environment instance = Environment._();

  /// Ambiente padrão conforme o modo de build: release → produção,
  /// debug/profile → desenvolvimento.
  static const String _kDefaultEnvironment =
      kReleaseMode ? 'production' : 'development';

  /// Nome do ambiente atual. Pode ser sobrescrito por `--dart-define`.
  String get environment => const String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: _kDefaultEnvironment,
      );

  /// Indica se [initialize] já foi executada com sucesso.
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Configurações do AdMob (preenchidas em [initialize]).
  late final AdMobConfig adMob;

  /// Nome do arquivo JSON do ambiente correspondente (na pasta `env/`).
  String get _environmentFileName => environment == 'production'
      ? 'env/production_environment.json'
      : 'env/development_environment.json';

  /// Carrega as chaves do JSON do ambiente atual.
  ///
  /// Deve ser chamado em `main` antes do `runApp`. Lança um [StateError] se
  /// o JSON não puder ser lido ou se faltar alguma chave obrigatória.
  Future<void> initialize() async {
    if (_initialized) return;

    final Map<String, dynamic> json;
    try {
      final raw = await rootBundle.loadString(_environmentFileName);
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw StateError(
        '[Environment] Não foi possível ler "$_environmentFileName". '
        'Verifique se o arquivo existe e está declarado em assets: no '
        'pubspec.yaml, e faça `flutter clean` antes de rodar. Erro: $e',
      );
    }

    // Aceita tanto o JSON plano (dart-define-from-file friendly)
    // quanto o aninhado antigo (adMob.*). Sem fallbacks hardcoded: se uma
    // chave faltar, lança erro explícito.
    final adMobJson = json['adMob'] as Map<String, dynamic>?;
    final bannerAdUnitId = (json['ADMOB_BANNER_AD_UNIT_ID'] as String?) ??
        (adMobJson?['bannerAdUnitId'] as String?);
    final interstitialAdUnitId =
        (json['ADMOB_INTERSTITIAL_AD_UNIT_ID'] as String?) ??
            (adMobJson?['interstitialAdUnitId'] as String?);

    if (bannerAdUnitId == null || bannerAdUnitId.isEmpty) {
      throw StateError(
        '[Environment] Chave "ADMOB_BANNER_AD_UNIT_ID" ausente/vazia em '
        '"$_environmentFileName".',
      );
    }
    if (interstitialAdUnitId == null || interstitialAdUnitId.isEmpty) {
      throw StateError(
        '[Environment] Chave "ADMOB_INTERSTITIAL_AD_UNIT_ID" ausente/vazia '
        'em "$_environmentFileName".',
      );
    }

    adMob = AdMobConfig(
      bannerAdUnitId: bannerAdUnitId,
      interstitialAdUnitId: interstitialAdUnitId,
    );
    _initialized = true;

    // Diagnóstico: mostra exatamente qual ambiente/chave foi carregado.
    // Procure por "[Environment]" no logcat. Se aparecer "development" +
    // chave de teste mesmo passando --dart-define-from-file=production,
    // o build está desatualizado (faça `flutter clean` e rode de novo).
    debugPrint(
      '[Environment] ambiente="$environment" '
      'buildMode=${kReleaseMode ? 'release' : 'debug'} '
      'arquivo="$_environmentFileName" '
      'bannerAdUnitId="$bannerAdUnitId" '
      'interstitialAdUnitId="$interstitialAdUnitId"',
    );
  }
}

/// Configurações do AdMob por ambiente.
class AdMobConfig {
  const AdMobConfig({
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
  });

  /// ID do bloco de anúncios banner.
  final String bannerAdUnitId;

  /// ID do bloco de anúncios intersticial.
  final String interstitialAdUnitId;
}
