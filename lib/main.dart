import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CalculatorScreen(),
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3142)),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = "0";          // số đang hiển thị
  String _expression = "";        // dùng để hiển thị phương trình
  double? _num1;                  // toán hạng 1
  String _operation = "";         // phép toán hiện tại
  bool _waitingForNewOperand = false; // dùng khi nhập toán hạng mới

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3142),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ===================== DISPLAY =====================
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Expression nhỏ ở trên
                    Text(
                      _expression,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Display lớn
                    Text(
                      _display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===================== BUTTON GRID =====================
              Expanded(
                flex: 2,
                child: buildButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButtons() {
    final List<String> btns = [
      "C", "CE", "%", "÷",
      "7", "8", "9", "×",
      "4", "5", "6", "-",
      "1", "2", "3", "+",
      "±", "0", ".", "=",
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: btns.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return buildButton(btns[index]);
      },
    );
  }

  Widget buildButton(String text) {
    bool isOperator = ["+", "-", "×", "÷", "="].contains(text);
    Color bg = isOperator ? const Color(0xFFEF8354) : const Color(0xFF4F5D75);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onBtnPress(text),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // =======================================================
  // ===================== LOGIC ============================
  // =======================================================

  void onBtnPress(String text) {
    setState(() {
      // ====== 0–9 ======
      if (RegExp(r'^[0-9]$').hasMatch(text)) {
        if (_waitingForNewOperand) {
          _display = text; // GHI ĐÈ
          _waitingForNewOperand = false;
        } else {
          if (_display == "0") {
            _display = text;
          } else {
            _display += text;
          }
        }
        return;
      }

      // ====== Dấu chấm ======
      if (text == ".") {
        if (_waitingForNewOperand) {
          _display = "0.";
          _waitingForNewOperand = false;
        } else if (!_display.contains(".")) {
          _display += ".";
        }
        return;
      }

      // ====== C ======
      if (text == "C") {
        _display = "0";
        _expression = "";
        _num1 = null;
        _operation = "";
        _waitingForNewOperand = false;
        return;
      }

      // ====== CE ======
      if (text == "CE") {
        if (_waitingForNewOperand) {
          _display = "0";
          _waitingForNewOperand = false;
        } else {
          if (_display.length > 1) {
            _display = _display.substring(0, _display.length - 1);
          } else {
            _display = "0";
          }
        }
        return;
      }

      // ====== +/- ======
      if (text == "±") {
        if (_display.startsWith("-")) {
          _display = _display.substring(1);
        } else if (_display != "0") {
          _display = "-$_display";
        }
        return;
      }

      // ====== % ======
      if (text == "%") {
        double v = double.tryParse(_display) ?? 0;
        v = v / 100.0;
        _display = _formatDouble(v);
        return;
      }

      // ====== Operator (+ - × ÷) ======
      if (["+", "-", "×", "÷"].contains(text)) {
        double current = double.tryParse(_display) ?? 0;

        if (_operation.isNotEmpty && _num1 != null && !_waitingForNewOperand) {
          // tính chuỗi phép toán
          double result = _compute(_num1!, current, _operation);
          _num1 = result;
          _display = _formatDouble(result);
        } else {
          _num1 = current;
        }

        _operation = text;
        _expression = "${_formatDouble(_num1!)} $text";
        _waitingForNewOperand = true;
        return;
      }

      // ====== "=" ======
      if (text == "=") {
        if (_operation.isNotEmpty && _num1 != null) {
          double current = double.tryParse(_display) ?? 0;

          double result = _compute(_num1!, current, _operation);

          _expression =
          "${_formatDouble(_num1!)} $_operation ${_formatDouble(current)} =";

          _display = _formatDouble(result);

          _num1 = null;
          _operation = "";
          _waitingForNewOperand = true;
        }
        return;
      }
    });
  }

  // =======================================================
  // ===================== TOÁN HỌC ========================
  // =======================================================

  double _compute(double a, double b, String op) {
    switch (op) {
      case "+":
        return a + b;
      case "-":
        return a - b;
      case "×":
        return a * b;
      case "÷":
        if (b == 0) return double.nan;
        return a / b;
    }
    return b;
  }

  String _formatDouble(double v) {
    if (v.isNaN) return "Error";

    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }

    return v
        .toStringAsFixed(10)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
