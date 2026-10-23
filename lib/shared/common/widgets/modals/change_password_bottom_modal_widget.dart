import 'package:flutter/material.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior para recuperar a senha (envia e-mail de reset).
///
/// Bottom modal que acompanha o teclado, fundo branco, campo no padrão do
/// projeto (cinza máximo) e botão "Solicitar senha" no padrão dos botões.
/// O `onSubmit` recebe o e-mail digitado e é responsável pela regra de negócio
/// (enviar reset, exibir alerta) e por fechar o modal (`Navigator.pop`).
class ChangePasswordBottomModalWidget extends StatefulWidget {
  const ChangePasswordBottomModalWidget({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function(BuildContext context, String email) onSubmit;

  @override
  State<ChangePasswordBottomModalWidget> createState() =>
      _ChangePasswordBottomModalWidgetState();
}

class _ChangePasswordBottomModalWidgetState
    extends State<ChangePasswordBottomModalWidget> {
  final TextEditingController _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onSubmit(context, _emailController.text.trim());
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Recuperação de senha',
      buttonLabel: _submitting ? 'Enviando...' : 'Solicitar senha',
      onButtonPressed: _submitting ? () {} : _handleSubmit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(
              controller: _emailController,
              hintText: 'E-mail',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 2),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          enabledBorder: InputBorder.none,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppBottomModal.grayColor),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: TextStyle(
          color: AppBottomModal.grayColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
