import 'package:flutter/material.dart';

String currencyFlagEmoji(String currencyCode) {
  const countryByCurrency = {
    'USD': 'US',
    'EUR': 'EU',
    'GBP': 'GB',
    'JPY': 'JP',
    'AUD': 'AU',
    'CAD': 'CA',
    'CHF': 'CH',
    'CNY': 'CN',
    'INR': 'IN',
    'AED': 'AE',
    'SGD': 'SG',
    'THB': 'TH',
  };

  final country = countryByCurrency[currencyCode];
  if (country == null || country.length != 2) return '  ';

  final base = 0x1F1E6;
  final first = country.codeUnitAt(0) - 0x41 + base;
  final second = country.codeUnitAt(1) - 0x41 + base;
  return String.fromCharCode(first) + String.fromCharCode(second);
}

Future<String?> showCurrencyPickerBottomSheet({
  required BuildContext context,
  required String selectedCurrency,
  required Map<String, String> currencies,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CurrencyPickerSheet(
      selectedCurrency: selectedCurrency,
      currencies: currencies,
    ),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String selectedCurrency;
  final Map<String, String> currencies;

  const _CurrencyPickerSheet({
    required this.selectedCurrency,
    required this.currencies,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<MapEntry<String, String>> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.currencies.entries.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies(String query) {
    final normalized = query.trim().toLowerCase();

    setState(() {
      if (normalized.isEmpty) {
        _filteredCurrencies = widget.currencies.entries.toList();
      } else {
        _filteredCurrencies = widget.currencies.entries
            .where(
              (item) =>
                  item.key.toLowerCase().contains(normalized) ||
                  item.value.toLowerCase().contains(normalized),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 36 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 26),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCurrencies,
              decoration: InputDecoration(
                hintText: 'Search currency',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterCurrencies('');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredCurrencies.isEmpty
                ? const Center(child: Text('No currencies found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    itemCount: _filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredCurrencies[index];
                      final code = entry.key;
                      final name = entry.value;
                      final isSelected = code == widget.selectedCurrency;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        leading: Text(
                          currencyFlagEmoji(code),
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 30 / 2,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2F3542),
                          ),
                        ),
                        subtitle: Text(
                          name,
                          style: TextStyle(
                            fontSize: 26 / 2,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF2F80ED),
                                size: 24,
                              )
                            : null,
                        onTap: () => Navigator.pop(context, code),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
