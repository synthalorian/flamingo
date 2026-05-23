import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/flamingo_theme.dart';
import '../../core/widgets/crt_background.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorController {
  String _expression = '';
  String _result = '';
  bool _error = false;
  bool _justCalculated = false;

  String get expression => _expression;
  String get result => _result;
  bool get justCalculated => _justCalculated;

  void _inputDigit(String d) {
    if (_justCalculated) {
      _expression = d;
      _result = '';
      _justCalculated = false;
      return;
    }
    if (_expression == '0' && d == '0') return;
    if (_expression == '0') {
      _expression = d;
      return;
    }
    _expression += d;
  }

  void _inputDecimal() {
    if (_justCalculated) {
      _expression = '0.';
      _result = '';
      _justCalculated = false;
      return;
    }
    final lastNum = _expression.split(RegExp(r'[\+\-\×÷]')).last;
    if (lastNum.contains('.')) return;
    _expression += '.';
  }

  void _inputOperator(String op) {
    if (_justCalculated) {
      _expression = _result + op;
      _justCalculated = false;
      return;
    }
    final last = _expression.isNotEmpty ? _expression[_expression.length - 1] : '';
    if (['+', '-', '×', '÷'].contains(last)) {
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else if (_expression.isNotEmpty) {
      _expression += op;
    }
    _justCalculated = false;
  }

  void _toggleSign() {
    if (_expression.isEmpty) return;
    final nums = _expression.split(RegExp(r'(?<=[\d)])[+-\×÷]|[-\×÷](?=[\d(])'));
    if (nums.isNotEmpty) {
      final last = nums.last;
      final prefix = _expression.substring(0, _expression.length - last.length);
      if (last.startsWith('-')) {
        _expression = prefix + last.substring(1);
      } else {
        _expression = prefix + '-$last';
      }
    }
  }

  void _percent() {
    if (_expression.isEmpty) return;
    _calculate();
    if (_result.isNotEmpty && !_error) {
      final val = double.tryParse(_result.replaceAll(',', '')) ?? 0;
      _expression = (val / 100).toString();
      _result = '';
      _justCalculated = false;
    }
  }

  void _clear() {
    _expression = '';
    _result = '';
    _error = false;
    _justCalculated = false;
  }

  void _backspace() {
    if (_justCalculated) {
      _clear();
      return;
    }
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
      _result = '';
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    try {
      final eval = _expression.replaceAll('×', '*').replaceAll('÷', '/');
      final tokens = _tokenize(eval);
      final result = _evalRpn(_toRpn(tokens));
      final formatted = _formatNumber(result);
      _result = formatted;
      _justCalculated = true;
      _error = false;
    } catch (_) {
      _error = true;
      _result = 'Error';
    }
  }

  List<String> _tokenize(String s) {
    final re = RegExp(r'\d+(\.\d+)?|[+\-*/()]');
    return re.allMatches(s).map((m) => m.group(0)!).toList();
  }

  List<String> _toRpn(List<String> tokens) {
    final output = <String>[];
    final ops = <String>[];
    final prec = {'+': 1, '-': 1, '*': 2, '/': 2};
    final ra = {'+': true, '-': true, '*': true, '/': true};
    for (final t in tokens) {
      if (ra[t] ?? false) {
        while (ops.isNotEmpty && (prec[ops.last] ?? 0) >= (prec[t] ?? 0)) {
          output.add(ops.removeLast());
        }
        ops.add(t);
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isNotEmpty && ops.last == '(') {
          ops.removeLast();
        }
      } else {
        output.add(t);
      }
    }
    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }
    return output;
  }

  double _evalRpn(List<String> rpn) {
    final stack = <double>[];
    for (final t in rpn) {
      if (double.tryParse(t) != null) {
        stack.add(double.parse(t));
      } else {
        final b = stack.removeLast();
        final a = stack.removeLast();
        double r;
        switch (t) {
          case '+': r = a + b; break;
          case '-': r = a - b; break;
          case '*': r = a * b; break;
          case '/': r = a / b; break;
          default: r = 0;
        }
        stack.add(r);
      }
    }
    return stack.isNotEmpty ? stack.last : 0;
  }

  String _formatNumber(double n) {
    if (n.isNaN || n.isInfinite) return 'Error';
    final s = n.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    if (s.length > 14) return n.toStringAsPrecision(10);
    return s;
  }
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final controller = _CalculatorController();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlamingoColors.scaffoldBg,
      body: CrtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (controller.expression.isNotEmpty)
                      Text(
                        controller.expression,
                        style: const TextStyle(
                          color: FlamingoColors.muted,
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      controller.result.isNotEmpty && controller.justCalculated
                          ? controller.result
                          : controller.expression.isEmpty
                              ? '0'
                              : controller.expression,
                      style: const TextStyle(
                        color: FlamingoColors.text,
                        fontSize: 52,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _row(['C', '±', '%', '÷'], isOp: [false, false, false, true], op: [null, null, null, '÷']),
                    _row(['1', '2', '3', '−'], isOp: [false, false, false, true]),
                    _row(['4', '5', '6', '+'], isOp: [false, false, false, true]),
                    _row(['7', '8', '9', '×'], isOp: [false, false, false, true]),
                    _row(['0', '.', '⌫', '='], isOp: [false, false, false, true]),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(List<String> labels, {List<bool>? isOp, List<String?>? op}) {
    final ops = op ?? [null, null, null, null];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (i) {
        final label = labels[i];
        final isOpBtn = (isOp?[i] ?? false) || ops[i] != null;
        return _key(label, isOpBtn, () => _onTap(label, ops[i]));
      }),
    );
  }

  void _onTap(String label, String? op) {
    HapticFeedback.lightImpact();
    if (label == 'C') {
      controller._clear();
    } else if (label == '±') {
      controller._toggleSign();
    } else if (label == '%') {
      controller._percent();
    } else if (label == '⌫') {
      controller._backspace();
    } else if (label == '=') {
      controller._calculate();
    } else if (op != null) {
      controller._inputOperator(op);
    } else if (label == '.') {
      controller._inputDecimal();
    } else {
      controller._inputDigit(label);
    }
    setState(() {});
  }

  Widget _key(String label, bool isOpBtn, VoidCallback onTap) {
    final bg = isOpBtn ? FlamingoColors.primary : FlamingoColors.card;
    final txtColor = isOpBtn ? FlamingoColors.scaffoldBg : FlamingoColors.text;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 72,
            height: 68,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 26,
                fontWeight: isOpBtn ? FontWeight.bold : FontWeight.normal,
                color: txtColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
