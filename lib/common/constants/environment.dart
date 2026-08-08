import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;

/// Configurações de ambiente.
///
/// As chaves ficam em arquivos JSON dentro de `env/` na raiz do projeto:
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
  /// Deve ser chamado em `main` antes do `runApp`.
  Future<void> initialize() async {
    if (_initialized) return;

    String bannerAdUnitId;
    try {
      final raw = await rootBundle.loadString(_environmentFileName);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Aceita tanto o JSON plano (dart-define-from-file friendly)
      // quanto o aninhado antigo (adMob.bannerAdUnitId).
      bannerAdUnitId = (json['ADMOB_BANNER_AD_UNIT_ID'] as String?) ??
          ((json['adMob'] as Map<String, dynamic>?)?['bannerAdUnitId']
                  as String?) ??
              _kTestBannerAdUnitId;
    } catch (e) {
      // Se o asset não estiver disponível (build sem clean após editar o
      // pubspec), cai no fallback seguro por modo de build.
      debugPrint('[Environment] Falha ao ler $_environmentFileName: $e');
      bannerAdUnitId =
          kReleaseMode ? _kProdBannerAdUnitId : _kTestBannerAdUnitId;
    }

    adMob = AdMobConfig(bannerAdUnitId: bannerAdUnitId);
    _initialized = true;

    // Diagnóstico: mostra exatamente qual ambiente/chave foi carregado.
    // Procure por "[Environment]" no logcat. Se aparecer "development" +
    // chave de teste mesmo passando --dart-define-from-file=production,
    // o build está desatualizado (faça `flutter clean` e rode de novo).
    debugPrint(
      '[Environment] ambiente="$environment" '
      'buildMode=${kReleaseMode ? 'release' : 'debug'} '
      'arquivo="$_environmentFileName" '
      'bannerAdUnitId="$bannerAdUnitId"',
    );
  }
}

/// Configurações do AdMob por ambiente.
class AdMobConfig {
  const AdMobConfig({required this.bannerAdUnitId});

  /// ID do bloco de anúncios banner. Em desenvolvimento aponta para o bloco
  /// de teste do Google; em produção aponta para o bloco real.
  final String bannerAdUnitId;
}

/// ID de banner de teste do Google — usado em desenvolvimento e como fallback
/// quando a chave não vier no JSON (evita cliques inválidos).
const _kTestBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// ID real de produção (fallback em build release caso o asset do JSON não
/// esteja disponível). Mantenha em sincronia com env/production_environment.json.
const _kProdBannerAdUnitId = 'ca-app-pub-5106035309089315/6550502888';
