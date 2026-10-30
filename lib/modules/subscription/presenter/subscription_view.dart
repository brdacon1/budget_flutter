import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/utils/height_calculate_utils.dart';
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
    if (_viewModel.state == SubscriptionState.success && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } else if (_viewModel.state == SubscriptionState.error && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_viewModel.errorMessage ?? 'Assinatura não realizada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF696D77), Color(0xFF292C36)],
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
            icon: Icon(
              Icons.arrow_back,
              size: screenAwareSize(20.0, context),
            ),
            onPressed: () async {
              await _viewModel.checkExistingSubscription();
              if (mounted) Navigator.pop(context, true);
            },
          ),
          title: Text(
            "Premium",
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
