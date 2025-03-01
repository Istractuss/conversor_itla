import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const List<String> currencies = [
  'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'SEK', 'NZD'
];

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    CurrencyConverter(),
    HistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Convertir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
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
        throw Exception('La API devolvioo un error: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      if (!data.containsKey('rates') || !data['rates'].containsKey(_toCurrency)) {
        throw Exception('Conversion no disponible.');
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
                    items: currencies.map((currency) {
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
                    items: currencies.map((currency) {
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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _baseCurrency = 'USD';
  Map<String, Map<String, dynamic>>? _historicalRates;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  Future<void> _fetchHistoricalData() async {
    setState(() => _isLoading = true);

    final DateTime endDate = DateTime.now();
    final DateTime startDate = endDate.subtract(const Duration(days: 7));

    final String start = _formatDate(startDate);
    final String end = _formatDate(endDate);

    final String url = 'https://api.frankfurter.app/$start..$end?from=$_baseCurrency';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Error al obtener datos: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);

      setState(() {
        _historicalRates = Map<String, Map<String, dynamic>>.from(data['rates']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tasas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _baseCurrency,
              items: currencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _baseCurrency = value!;
                  _fetchHistoricalData();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Moneda Base',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historicalRates == null || _historicalRates!.isEmpty
                    ? const Center(child: Text('No hay datos disponibles'))
                    : ListView.builder(
                        itemCount: _historicalRates!.length,
                        itemBuilder: (context, index) {
                          final date = _historicalRates!.keys.elementAt(index);
                          final rates = _historicalRates![date]!;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...rates.entries.map((rate) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(rate.key),
                                          Text(rate.value.toStringAsFixed(4)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}