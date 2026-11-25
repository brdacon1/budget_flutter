import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/enums/alert_type_enum.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Modal inferior para trocar o nome do usuário.
///
/// Bottom modal que acompanha o teclado, fundo branco, campo no padrão do
/// projeto (cinza máximo) e botão "SALVAR" no padrão dos botões. O modal só
/// coleta o nome: a regra de negócio chega por [onSave] (sem `BuildContext`)
/// e, em sucesso, o modal fecha devolvendo o nome salvo.
class ChangeNameBottomModalWidget extends StatefulWidget {
  const ChangeNameBottomModalWidget({super.key, required this.onSave});

  final Future<Result<void>> Function(String name) onSave;

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

  void _showError(String message) {
    AlertSnackBar.show(
      context,
      type: AlertType.error,
      title: 'Erro!',
      message: message,
    );
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('O campo nome não pode ser vazio!');
      return;
    }
    setState(() => _submitting = true);
    final result = await widget.onSave(name);
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop(name);
      case Error():
        setState(() => _submitting = false);
        _showError('Problemas para atualizar o nome verifique os dados!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      scrollable: true,
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
        style: const TextStyle(
          color: AppBottomModal.grayColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
