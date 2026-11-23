import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Logo da empresa em círculo (barra lateral). Sem logo cadastrado mostra um
/// ícone neutro.
class MainTabCompanyLogo extends StatelessWidget {
  const MainTabCompanyLogo({super.key, this.logo});

  /// Diâmetro do círculo.
  static const double size = 110;

  final Uint8List? logo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: cardBorderColor,
      ),
      child:
          logo == null
              ? const Icon(Icons.business, color: mutedTextColor, size: 22)
              : Image.memory(
                logo!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.business,
                      color: mutedTextColor,
                      size: 22,
                    ),
              ),
    );
  }
}
