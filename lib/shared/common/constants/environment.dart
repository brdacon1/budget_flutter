import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kReleaseMode;
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

  /// Configurações de assinatura (preenchidas em [initialize]).
  late final SubscriptionConfig subscription;

  /// Libera o premium para testes (chave opcional `FORCE_PREMIUM` do JSON).
  ///
  /// Só existe no `development_environment.json`. Ausente/vazia → `false`, e
  /// o premium segue a regra do pagamento. Nunca vale em build release.
  bool get forcePremium => !kReleaseMode && _forcePremium;
  bool _forcePremium = false;

  /// Nome do arquivo JSON do ambiente correspondente (na pasta `env/`).
  String get _environmentFileName =>
      environment == 'production'
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

    // As chaves de anúncio são por plataforma; o app usa apenas a da
    // plataforma atual (iOS → *_IOS, demais → *_ANDROID).
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final interstitialKey =
        isIOS
            ? 'ADMOB_INTERSTITIAL_AD_UNIT_ID_IOS'
            : 'ADMOB_INTERSTITIAL_AD_UNIT_ID_ANDROID';

    final interstitialAdUnitId =
        (json[interstitialKey] as String?) ??
        (adMobJson?['interstitialAdUnitId'] as String?);

    final androidSubscriptionSku = json['ANDROID_SUBSCRIPTION_SKU'] as String?;
    final iosSubscriptionSku = json['IOS_SUBSCRIPTION_SKU'] as String?;
    final androidYearSubscriptionSku =
        json['ANDROID_SUBSCRIPTION_BY_YEAR_SKU'] as String?;
    final iosYearSubscriptionSku =
        json['IOS_SUBSCRIPTION_BY_YEAR_SKU'] as String?;

    if (interstitialAdUnitId == null || interstitialAdUnitId.isEmpty) {
      throw StateError(
        '[Environment] Chave "$interstitialKey" ausente/vazia em '
        '"$_environmentFileName".',
      );
    }

    if (androidSubscriptionSku == null || androidSubscriptionSku.isEmpty) {
      throw StateError(
        '[Environment] Chave "ANDROID_SUBSCRIPTION_SKU" ausente/vazia em '
        '"$_environmentFileName".',
      );
    }
    if (iosSubscriptionSku == null || iosSubscriptionSku.isEmpty) {
      throw StateError(
        '[Environment] Chave "IOS_SUBSCRIPTION_SKU" ausente/vazia em '
        '"$_environmentFileName".',
      );
    }

    if (androidYearSubscriptionSku == null ||
        androidYearSubscriptionSku.isEmpty) {
      throw StateError(
        '[Environment] Chave "ANDROID_SUBSCRIPTION_BY_YEAR_SKU" ausente/vazia '
        'em "$_environmentFileName".',
      );
    }
    if (iosYearSubscriptionSku == null || iosYearSubscriptionSku.isEmpty) {
      throw StateError(
        '[Environment] Chave "IOS_SUBSCRIPTION_BY_YEAR_SKU" ausente/vazia em '
        '"$_environmentFileName".',
      );
    }

    _forcePremium = json['FORCE_PREMIUM'] == true;

    adMob = AdMobConfig(interstitialAdUnitId: interstitialAdUnitId);
    subscription = SubscriptionConfig(
      androidSku: androidSubscriptionSku,
      iosSku: iosSubscriptionSku,
      androidYearSku: androidYearSubscriptionSku,
      iosYearSku: iosYearSubscriptionSku,
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
      'plataforma="${isIOS ? 'ios' : 'android'}" '
      'interstitialAdUnitId="$interstitialAdUnitId" '
      'androidSubscriptionSku="$androidSubscriptionSku" '
      'iosSubscriptionSku="$iosSubscriptionSku" '
      'androidYearSku="$androidYearSubscriptionSku" '
      'iosYearSku="$iosYearSubscriptionSku" '
      'forcePremium=$forcePremium',
    );
  }
}

/// Configurações do AdMob por ambiente.
class AdMobConfig {
  const AdMobConfig({required this.interstitialAdUnitId});

  /// ID do bloco de anúncios intersticial da plataforma atual.
  final String interstitialAdUnitId;
}

/// Configurações de assinatura por ambiente.
class SubscriptionConfig {
  const SubscriptionConfig({
    required this.androidSku,
    required this.iosSku,
    required this.androidYearSku,
    required this.iosYearSku,
  });

  /// SKU da assinatura **mensal** na Google Play.
  final String androidSku;

  /// SKU da assinatura **mensal** na App Store.
  final String iosSku;

  /// SKU da assinatura **anual** na Google Play.
  final String androidYearSku;

  /// SKU da assinatura **anual** na App Store.
  final String iosYearSku;
}
