import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/subscription/data/model/subscription_plan.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';
import 'package:oflite/modules/terms_conditions/presenter/terms_conditions_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/enums/alert_type_enum.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'components/subscription_benefit_chip.dart';
import 'components/subscription_bottom_bar.dart';
import 'components/subscription_feature_tile.dart';
import 'components/subscription_hero_card.dart';
import 'components/subscription_plan_card.dart';
import 'subscription_view_model.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionView();
}

class _SubscriptionView extends State<SubscriptionView> {
  late SubscriptionViewModel _viewModel;
  SubscriptionState _lastState = SubscriptionState.idle;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<SubscriptionViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final state = _viewModel.state;
    final changed = state != _lastState;
    _lastState = state;
    if (!changed) return setState(() {});

    switch (state) {
      case SubscriptionState.success:
        AlertSnackBar.show(
          context,
          type: AlertType.success,
          title: SubscriptionStrings.successTitle,
          message: SubscriptionStrings.paymentSuccess,
        );
        Navigator.pop(context, true);
        return;
      case SubscriptionState.cancelled:
        AlertSnackBar.show(
          context,
          type: AlertType.warning,
          title: SubscriptionStrings.cancelledTitle,
          message: SubscriptionStrings.cancelledMessage,
        );
      case SubscriptionState.error:
        AlertSnackBar.show(
          context,
          type: AlertType.error,
          title: SubscriptionStrings.errorTitle,
          message: SubscriptionStrings.subscriptionNotCompleted,
        );
      case SubscriptionState.idle:
      case SubscriptionState.loading:
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: transparentColor,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 26.0),
          onPressed: () async {
            await _viewModel.checkExistingSubscription();
            if (mounted) Navigator.pop(context, true);
          },
        ),
        title: Text(
          SubscriptionStrings.pageTitle,
          style: TextStyle(
            color: whiteColor,
            fontSize: 24.0,
            fontFamily: "Montserrat-Bold",
          ),
        ),
        centerTitle: true,
      ),
      // O botão de assinar fica fixo no rodapé; o conteúdo rola por trás.
      body: AppPageContainer(
        width: AppPageWidth.reading,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubscriptionHeroCard(),
                    _buildSectionLabel(SubscriptionStrings.aiSectionTitle),
                    ..._buildAiFeatures(),
                    _buildSectionLabel(SubscriptionStrings.planIncludesTitle),
                    _buildPlanBenefits(),
                    _buildSectionLabel(SubscriptionStrings.choosePlanTitle),
                    _buildPlans(),
                    const SizedBox(height: 16),
                    Text(
                      SubscriptionStrings.renewalNotice,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: mutedTextColor,
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SubscriptionBottomBar(
              caption: _caption,
              isLoading: _viewModel.state == SubscriptionState.loading,
              canSubscribe: _viewModel.displayPrice != null,
              onSubscribe: _viewModel.requestSubscription,
              onRestore: Platform.isIOS ? _viewModel.restorePurchases : null,
              onTerms:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsView(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _caption {
    final price = _viewModel.displayPrice;
    if (price == null) return null;
    final label =
        _viewModel.selectedPlan == SubscriptionPlan.yearly
            ? SubscriptionStrings.planYearly
            : SubscriptionStrings.planMonthly;
    return SubscriptionStrings.subscribeCaption(label, price);
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: mutedTextColor,
          fontSize: 11,
          letterSpacing: 0.8,
          fontFamily: "Montserrat-SemiBold",
        ),
      ),
    );
  }

  List<Widget> _buildAiFeatures() {
    return [
      SubscriptionFeatureTile(
        icon: Icons.auto_awesome,
        iconBackground: buttonColor,
        iconColor: premiumOnAccentColor,
        title: SubscriptionStrings.featureAssistantTitle,
        description: SubscriptionStrings.featureAssistantDescription,
      ),
      SubscriptionFeatureTile(
        icon: Icons.receipt_long,
        iconBackground: premiumGoldColor,
        iconColor: premiumGoldTextColor,
        title: SubscriptionStrings.featureProofTitle,
        description: SubscriptionStrings.featureProofDescription,
      ),
      SubscriptionFeatureTile(
        icon: Icons.bar_chart,
        iconBackground: premiumPurpleColor,
        iconColor: whiteColor,
        title: SubscriptionStrings.featureReportTitle,
        description: SubscriptionStrings.featureReportDescription,
      ),
      SubscriptionFeatureTile(
        icon: Icons.chat_bubble_outline,
        iconBackground: premiumPinkColor,
        iconColor: whiteColor,
        title: SubscriptionStrings.featureCommentsTitle,
        description: SubscriptionStrings.featureCommentsDescription,
      ),
    ];
  }

  Widget _buildPlanBenefits() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.9,
      children: [
        SubscriptionBenefitChip(
          icon: Icons.all_inclusive,
          label: SubscriptionStrings.benefitUnlimitedBudgets,
        ),
        SubscriptionBenefitChip(
          icon: Icons.list_alt,
          label: SubscriptionStrings.benefitUnlimitedPriceList,
        ),
        SubscriptionBenefitChip(
          icon: Icons.image_outlined,
          label: SubscriptionStrings.benefitCompanyLogo,
        ),
        SubscriptionBenefitChip(
          icon: Icons.block,
          label: SubscriptionStrings.benefitNoAds,
        ),
      ],
    );
  }

  Widget _buildPlans() {
    if (_viewModel.isLoadingProducts) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: loadingIndicatorColor,
          ),
        ),
      );
    }

    final monthly = _viewModel.priceFor(SubscriptionPlan.monthly);
    final yearly = _viewModel.priceFor(SubscriptionPlan.yearly);

    if (monthly == null && yearly == null) {
      return Text(
        SubscriptionStrings.plansUnavailable,
        style: const TextStyle(color: premiumSubtleTextColor, fontSize: 12),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (monthly != null)
          Expanded(
            child: SubscriptionPlanCard(
              label: SubscriptionStrings.planMonthly,
              price: monthly,
              period: SubscriptionStrings.perMonth,
              selected: _viewModel.selectedPlan == SubscriptionPlan.monthly,
              onTap: () => _viewModel.selectPlan(SubscriptionPlan.monthly),
            ),
          ),
        if (monthly != null && yearly != null) const SizedBox(width: 8),
        if (yearly != null)
          Expanded(
            child: SubscriptionPlanCard(
              label: SubscriptionStrings.planYearly,
              price: yearly,
              period: SubscriptionStrings.perYear,
              badge: SubscriptionStrings.bestValue,
              selected: _viewModel.selectedPlan == SubscriptionPlan.yearly,
              onTap: () => _viewModel.selectPlan(SubscriptionPlan.yearly),
            ),
          ),
      ],
    );
  }
}
