import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/rif_validator_utils.dart';

class RifInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool readOnly;
  final String? Function(String?)? validator;

  const RifInputField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.validator,
  });

  @override
  State<RifInputField> createState() => _RifInputFieldState();
}

class _RifInputFieldState extends State<RifInputField> {
  String _selectedPrefix = 'J';
  final TextEditingController _numberController = TextEditingController();
  final FocusNode _numberFocusNode = FocusNode();
  String? _errorText;

  static const List<Map<String, String>> _prefixOptions = [
    {'value': 'J', 'label': 'J - Jurídico'},
    {'value': 'V', 'label': 'V - Natural (Firma Personal)'},
    {'value': 'G', 'label': 'G - Gubernamental'},
    {'value': 'E', 'label': 'E - Extranjero'},
    {'value': 'C', 'label': 'C - Comunal'},
  ];

  @override
  void initState() {
    super.initState();
    _parseInitialControllerValue();
    _numberController.addListener(_onNumberChanged);
    widget.controller.addListener(_onParentControllerChanged);
  }

  @override
  void didUpdateWidget(covariant RifInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.text != widget.controller.text) {
      _parseInitialControllerValue();
    }
  }

  @override
  void dispose() {
    _numberController.removeListener(_onNumberChanged);
    widget.controller.removeListener(_onParentControllerChanged);
    _numberController.dispose();
    _numberFocusNode.dispose();
    super.dispose();
  }

  void _parseInitialControllerValue() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      final parts = text.split('-');
      if (parts.isNotEmpty && RifValidatorUtils.letterBases.containsKey(parts[0].toUpperCase())) {
        _selectedPrefix = parts[0].toUpperCase();
      }
      if (parts.length > 1) {
        final digits = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        if (_numberController.text != digits) {
          _numberController.text = digits;
        }
      }
    }
  }

  void _onParentControllerChanged() {
    if (widget.controller.text.isEmpty && _numberController.text.isNotEmpty) {
      setState(() {
        _numberController.clear();
      });
    }
  }

  void _onNumberChanged() {
    final rawNumber = _numberController.text.trim();
    if (rawNumber.isEmpty) {
      widget.controller.text = '';
      setState(() {
        _errorText = null;
      });
      return;
    }

    final formatted = RifValidatorUtils.formatRif(_selectedPrefix, rawNumber);
    if (formatted != null) {
      widget.controller.text = formatted;
    } else {
      widget.controller.text = '';
    }

    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    } else {
      setState(() {});
    }
  }

  int? get _currentCheckDigit {
    final rawNumber = _numberController.text.trim();
    if (rawNumber.isEmpty) return null;
    return RifValidatorUtils.calculateCheckDigit(_selectedPrefix, rawNumber);
  }

  String? get _fullFormattedRif {
    final rawNumber = _numberController.text.trim();
    if (rawNumber.isEmpty) return null;
    return RifValidatorUtils.formatRif(_selectedPrefix, rawNumber);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkDigit = _currentCheckDigit;
    final fullRif = _fullFormattedRif;
    final hasNumber = _numberController.text.trim().isNotEmpty;

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(widget.controller.text);
        }
        if (widget.controller.text.isEmpty) {
          return 'El RIF es requerido';
        }
        if (!RifValidatorUtils.isValidRif(widget.controller.text)) {
          return 'El RIF ingresado no es válido según el SENIAT';
        }
        return null;
      },
      builder: (fieldState) {
        final errorMsg = _errorText ?? fieldState.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.readOnly ? Colors.grey[100] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorMsg != null
                      ? theme.colorScheme.error
                      : (widget.readOnly ? Colors.grey[300]! : Colors.grey[400]!),
                  width: errorMsg != null ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Icono izquierdo
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedDocumentCode,
                      color: Colors.indigo,
                      size: 20,
                    ),
                  ),

                  // Selector de Prefijo (J, V, G, E, C)
                  if (widget.readOnly)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      child: Text(
                        _selectedPrefix,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    )
                  else
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPrefix,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        items: _prefixOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt['value'],
                            child: Text(opt['value']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPrefix = val;
                            });
                            _onNumberChanged();
                          }
                        },
                      ),
                    ),

                  const Text(
                    '-',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),

                  // Campo numérico de 8 dígitos
                  Expanded(
                    child: TextField(
                      controller: _numberController,
                      focusNode: _numberFocusNode,
                      readOnly: widget.readOnly,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      style: const TextStyle(fontSize: 16, letterSpacing: 1.2),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '30369159',
                        hintStyle: TextStyle(color: Colors.grey, letterSpacing: 1.2),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // Pastilla de Dígito Verificador Módulo 11
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: checkDigit != null
                            ? Colors.indigo.withValues(alpha: 0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: checkDigit != null ? Colors.indigo : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '- ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Text(
                            checkDigit != null ? '$checkDigit' : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: checkDigit != null ? Colors.indigo : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'auto',
                            style: TextStyle(
                              fontSize: 10,
                              color: checkDigit != null ? Colors.indigo : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mensajes informativos y de error
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
              child: errorMsg != null
                  ? Text(
                      errorMsg,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    )
                  : hasNumber && fullRif != null
                      ? Row(
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text(
                              'RIF SENIAT: $fullRif',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Selecciona tipo y escribe hasta 8 dígitos numéricos',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
            ),
          ],
        );
      },
    );
  }
}
