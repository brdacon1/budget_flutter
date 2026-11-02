import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'pdf_model_select_view_model.dart';

class PdfModelSelectView extends StatefulWidget {
  const PdfModelSelectView({super.key});

  @override
  State<PdfModelSelectView> createState() => _PdfModelSelectViewState();
}

class _PdfModelSelectViewState extends State<PdfModelSelectView> {
  late final PdfModelSelectViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PdfModelSelectViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onSelect() async {
    final success = await _viewModel.selectCurrentLayout();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar modelo. Tente novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            title: Text(
              'Modelo de PDF',
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_viewModel.layouts.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _viewModel.currentIndex == index
                            ? buttonColor
                            : Colors.white24,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          body: _viewModel.loading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 1,
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _viewModel.pageController,
                        onPageChanged: _viewModel.onPageChanged,
                        itemCount: _viewModel.layouts.length,
                        itemBuilder: (context, index) {
                          final bytes = switch (index) {
                            0 => _viewModel.standardBytes,
                            1 => _viewModel.executiveBytes,
                            2 => _viewModel.professionalBytes,
                            _ => null,
                          };
                          final label = _viewModel.layouts[index]['label'] ?? '';

                          if (bytes == null || bytes.isEmpty) {
                            return Center(
                              child: Text(
                                'Não foi possível gerar a pré-visualização de $label',
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.white,
                                child: SfPdfViewer.memory(
                                  bytes,
                                  enableDoubleTapZooming: false,
                                  canShowScrollHead: false,
                                  canShowScrollStatus: false,
                                  canShowPaginationDialog: false,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _viewModel.saving ? null : _onSelect,
                            style: TextButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              disabledBackgroundColor: buttonColor.withOpacity(0.4),
                            ),
                            child: _viewModel.saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    'Quero esse',
                                    style: GoogleFonts.heebo(
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
