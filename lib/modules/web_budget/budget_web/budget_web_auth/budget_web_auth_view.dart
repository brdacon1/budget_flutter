import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';
import 'budget_web_auth_view_model.dart';
import 'components/budget_web_auth_field.dart';
import 'components/budget_web_auth_submit_button.dart';

import '../budget_web_app/budget_web_app_view_model.dart' show BudgetWebAppViewModel;

/// Tela inicial Web: o cliente informa o telefone cadastrado no orçamento.
///
/// O telefone é **obrigatório** e atua como segunda camada de segurança —
/// não localiza o orçamento (isso é feito pelo "número do endereço" da URL).
/// Nenhum dado do orçamento é exibido nesta tela.
class BudgetWebAuthView extends StatefulWidget {
  const BudgetWebAuthView({
    super.key,
    required this.viewModel,
    required this.onGranted,
  });

  final BudgetWebAppViewModel viewModel;
  final VoidCallback onGranted;

  @override
  State<BudgetWebAuthView> createState() => _BudgetWebAuthViewState();
}

class _BudgetWebAuthViewState extends State<BudgetWebAuthView> {
  late final BudgetWebAuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetWebAuthViewModel(
      appViewModel: widget.viewModel,
      onGranted: widget.onGranted,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildContent(context, maxWidth: 480),
      desktop: _buildContent(context, maxWidth: 480),
    );
  }

  Widget _buildContent(BuildContext context, {required double maxWidth}) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: secondaryColor,
                      child: Icon(Icons.lock_person_outlined,
                          color: buttonColor, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      BudgetWebStrings.phoneTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.heebo(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      BudgetWebStrings.phoneSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.heebo(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    BudgetWebAuthField(
                      controller: _viewModel.phoneController,
                      focusNode: _viewModel.phoneNode,
                      maskFormatter: _viewModel.maskFormatter,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 24),
                    BudgetWebAuthSubmitButton(
                      label: BudgetWebStrings.validateButton,
                      loading: _viewModel.validating,
                      onPressed: () => _viewModel.validate(context),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
