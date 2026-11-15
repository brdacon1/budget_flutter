import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/enums/alert_type_enum.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/utils/height_calculate_utils.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';
import 'components/product_screen_bottom_part.dart';
import 'components/product_screen_top_part.dart';
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [slateGray, darkSlate],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          tileMode: TileMode.clamp,
        ),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: screenAwareSize(20.0, context)),
            onPressed: () async {
              await _viewModel.checkExistingSubscription();
              if (mounted) Navigator.pop(context, true);
            },
          ),
          title: Text(
            SubscriptionStrings.pageTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenAwareSize(18.0, context),
              fontFamily: "Montserrat-Bold",
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const ProductScreenTopPart(),
              ProductScreenBottomPart(
                price: _viewModel.displayPrice,
                onSubscribe: _viewModel.requestSubscription,
                onRestore: _viewModel.restorePurchases,
                isLoading: _viewModel.state == SubscriptionState.loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
