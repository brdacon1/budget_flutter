import 'package:flutter/material.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior para trocar o nome do usuário.
///
/// Bottom modal que acompanha o teclado, fundo branco, campo no padrão do
/// projeto (cinza máximo) e botão "SALVAR" no padrão dos botões. O `onSubmit`
/// recebe o nome digitado e é responsável pela regra de negócio (atualizar
/// usuário, exibir alerta) e por fechar o modal (`Navigator.pop`).
class ChangeNameBottomModalWidget extends StatefulWidget {
  const ChangeNameBottomModalWidget({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function(BuildContext context, String name) onSubmit;

  @override
  State<ChangeNameBottomModalWidget> createState() =>
      _ChangeNameBottomModalWidgetState();
}

class _ChangeNameBottomModalWidgetState
    extends State<ChangeNameBottomModalWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onSubmit(context, _nameController.text.trim());
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Trocar nome de usuário',
      buttonLabel: _submitting ? 'Salvando...' : 'SALVAR',
      onButtonPressed: _submitting ? () {} : _handleSubmit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _Field(
          controller: _nameController,
          hintText: 'Seu nome',
          icon: Icons.person_pin_outlined,
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
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;

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
