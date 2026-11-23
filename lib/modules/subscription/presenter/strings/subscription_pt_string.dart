import 'package:flutter/widgets.dart';

/// Textos do módulo Subscription internacionalizados.
class SubscriptionStrings {
  const SubscriptionStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get pageTitle => _isPt ? 'Premium' : 'Premium';

  static String get benefitsTitle => _isPt ? 'Benefícios' : 'Benefits';

  static String get expandLess => _isPt ? 'menos' : 'less';

  static String get expandMore => _isPt ? 'mais..' : 'more..';

  static String get priceTitle => _isPt ? 'Preço' : 'Price';

  static String get subscribeButton =>
      _isPt ? 'ASSINAR AGORA' : 'SUBSCRIBE NOW';

  static String get restoreButton =>
      _isPt ? 'Restaurar Compras' : 'Restore Purchases';

  static String get subscriptionNotCompleted =>
      _isPt
          ? 'Não foi possível concluir o pagamento. Tente novamente.'
          : 'We could not complete the payment. Please try again.';

  static String get errorTitle =>
      _isPt ? 'Pagamento não realizado' : 'Payment not completed';

  static String get cancelledTitle =>
      _isPt ? 'Pagamento cancelado' : 'Payment cancelled';

  static String get cancelledMessage =>
      _isPt
          ? 'Você pode assinar o Premium quando quiser.'
          : 'You can subscribe to Premium anytime.';

  static String get successTitle =>
      _isPt ? 'Bem-vindo ao Premium!' : 'Welcome to Premium!';

  static String get paymentSuccess =>
      _isPt ? 'Pagamento realizado com sucesso!' : 'Payment successful!';

  static String offerTokenError(String sku) =>
      _isPt
          ? 'Offer token não encontrado. Verifique se o produto "$sku" está configurado com base plan na Play Console.'
          : 'Offer token not found. Please check if product "$sku" is configured with base plan in the Play Console.';

  static String get ratingTitle => _isPt ? 'Avaliações' : 'Reviews';

  static String get ratingValue => '5.0';

  static String get bestPrice => _isPt ? 'Melhor preço' : 'Best price';

  // ---------------- Hero ----------------

  static String get heroTitle =>
      _isPt ? 'Orce mais rápido, com IA' : 'Quote faster, with AI';

  static String get heroSubtitle =>
      _isPt
          ? 'Tudo que você precisa para fechar mais serviços e organizar o seu dinheiro.'
          : 'Everything you need to win more jobs and keep your money organized.';

  // ---------------- Novidades com IA ----------------

  static String get aiSectionTitle =>
      _isPt ? 'Novidades com IA' : 'New with AI';

  static String get newBadge => _isPt ? 'NOVO' : 'NEW';

  static String get featureAssistantTitle =>
      _isPt ? 'Assistente inteligente' : 'Smart assistant';

  static String get featureAssistantDescription =>
      _isPt
          ? 'Converse e a IA cria o orçamento completo para você, sem preencher formulário.'
          : 'Just chat and the AI builds the full budget for you, no forms to fill in.';

  static String get featureProofTitle =>
      _isPt ? 'Comprovantes pelo chat' : 'Payment proofs in chat';

  static String get featureProofDescription =>
      _isPt
          ? 'Envie a foto ou compartilhe o comprovante e o pagamento é lançado para você.'
          : 'Send a photo or share the proof and the payment is recorded for you.';

  static String get featureReportTitle =>
      _isPt ? 'Relatório de recibos' : 'Receipts report';

  static String get featureReportDescription =>
      _isPt
          ? 'Veja o que recebeu por semana ou por mês, direto na conversa.'
          : 'See what you received by week or by month, right in the chat.';

  static String get featureCommentsTitle =>
      _isPt ? 'Biblioteca de comentários' : 'Comment library';

  static String get featureCommentsDescription =>
      _isPt
          ? 'Salve textos prontos e use "Melhorar com IA" para deixar tudo profissional.'
          : 'Save ready-made texts and use "Improve with AI" to make them professional.';

  // ---------------- Tudo do plano ----------------

  static String get planIncludesTitle =>
      _isPt ? 'Tudo do plano' : 'Everything included';

  static String get benefitUnlimitedBudgets =>
      _isPt ? 'Orçamentos ilimitados' : 'Unlimited budgets';

  static String get benefitUnlimitedPriceList =>
      _isPt ? 'Lista de preço ilimitada' : 'Unlimited price list';

  static String get benefitCompanyLogo =>
      _isPt ? 'Logo da empresa' : 'Company logo';

  static String get benefitNoAds => _isPt ? 'Sem anúncios' : 'No ads';

  // ---------------- Planos ----------------

  static String get choosePlanTitle =>
      _isPt ? 'Escolha seu plano' : 'Choose your plan';

  static String get planMonthly => _isPt ? 'Mensal' : 'Monthly';

  static String get planYearly => _isPt ? 'Anual' : 'Yearly';

  static String get perMonth => _isPt ? 'por mês' : 'per month';

  static String get perYear => _isPt ? 'por ano' : 'per year';

  static String get bestValue => _isPt ? 'Melhor valor' : 'Best value';

  static String get plansUnavailable =>
      _isPt
          ? 'Não foi possível carregar os planos. Verifique sua conexão e tente novamente.'
          : 'We could not load the plans. Check your connection and try again.';

  // ---------------- Rodapé ----------------

  /// Ex.: "Anual por R$ 99,90 · cancele quando quiser".
  static String subscribeCaption(String planLabel, String price) =>
      _isPt
          ? '$planLabel por $price · cancele quando quiser'
          : '$planLabel for $price · cancel anytime';

  static String get renewalNotice =>
      _isPt
          ? 'A assinatura renova automaticamente até ser cancelada nas configurações da loja.'
          : 'The subscription renews automatically until cancelled in your store settings.';

  static String get termsAndPrivacy =>
      _isPt
          ? 'Termos de uso e Política de privacidade'
          : 'Terms of Use and Privacy Policy';
}
