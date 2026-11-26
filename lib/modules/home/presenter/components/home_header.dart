import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/presenter/components/header.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Logo da loja (círculo; vazio = toque para inserir) + nome da empresa à
/// esquerda e perfil (menu) à direita.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.companyLogo,
    this.companyName = '',
    required this.onEditLogo,
  });

  final Uint8List? companyLogo;
  final String companyName;
  final VoidCallback onEditLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onEditLogo,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorderColor),
            ),
            child:
                companyLogo != null
                    ? Image.memory(companyLogo!, fit: BoxFit.cover)
                    : const Icon(
                      Icons.add_a_photo_outlined,
                      color: buttonColor,
                      size: 22,
                    ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            companyName.isEmpty ? HomeStrings.appSubtitle : companyName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const ProfileCard(),
      ],
    );
  }
}
