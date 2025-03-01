import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conversor de Monedas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  const CurrencyConverter({super.key});

  @override
  State<CurrencyConverter> createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  final TextEditingController _amountController = TextEditingController();
  
  final List<String> _currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'SEK', 'NZD'
  ]; 

  final List<int> _years = [];
  
  String _fromCurrency = 'USD'; 
  String _toCurrency = 'EUR';
  String _result = '';
  int? _selectedYear;
  bool _isHistorical = false;

  @override
  void initState() {
    super.initState();
    _initializeYears();
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    for (int year = currentYear; year >= 1999; year--) {
      _years.add(year);
    }
  }

  Future<void> _convertCurrency() async {
    if (_amountController.text.isEmpty) {
      _showError('Ingresa una cantidad');
      return;
    }

    try {
      final amount = double.parse(_amountController.text);
      final String datePath = _isHistorical && _selectedYear != null 
          ? '${_selectedYear!}-12-31' 
          : 'latest';
      
      final String url = 'https://api.frankfurter.app/$datePath?from=$_fromCurrency&to=$_toCurrency';
      
      

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('La API devolvio un error: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      if (!data.containsKey('rates') || !data['rates'].containsKey(_toCurrency)) {
        throw Exception('Conversioon no disponible.');
      }

      final rate = data['rates'][_toCurrency] as double;
      
      setState(() {
        _result = '${amount.toStringAsFixed(2)} $_fromCurrency = '
                  '${(amount * rate).toStringAsFixed(2)} $_toCurrency\n'
                  '(${_isHistorical ? 'Año $_selectedYear' : 'Tasa actual'})';
      });

    } on FormatException {
      _showError('Solo numeros permitidos');
    } catch (e) {
      _showError('Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversor de monedas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _fromCurrency,
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _fromCurrency = value!);
                    },
                    decoration: const InputDecoration(
                      labelText: 'De',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _toCurrency,
                    items: _currencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _toCurrency = value!);
                    },
                    decoration: const InputDecoration(
                      labelText: 'A',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isHistorical,
                  onChanged: (value) {
                    setState(() => _isHistorical = value!);
                  },
                ),
                const Text('Elegir año especifico'),
                const SizedBox(width: 16),
                if (_isHistorical)
                  DropdownButton<int>(
                    value: _selectedYear,
                    hint: const Text('Año'),
                    items: _years.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedYear = value);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _convertCurrency,
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Convertir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900]
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
