import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/trip.dart';
import '../../places/services/places_service.dart';
import '../services/database_service.dart';
import '../services/frankfurter_service.dart';
import '../widgets/currency_picker_bottom_sheet.dart';
import '../widgets/custom_input.dart';

class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({super.key, required this.trip});

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _titleCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  final FrankfurterService _frankfurterService = FrankfurterService();
  final PlacesService _placesService = PlacesService();

  String _selectedCurrency = 'USD';
  Map<String, String> _currencies = const {'USD': 'US Dollar'};
  bool _isLoadingCurrencies = false;
  String? _currencyLoadError;

  List<DestinationSuggestion> _destinationSuggestions = [];
  DestinationSuggestion? _selectedDestination;
  Timer? _destinationDebounce;
  bool _isSearchingDestination = false;
  bool _destinationEdited = false;
  bool _isSavingTrip = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.trip.title;
    _destCtrl.text = widget.trip.destination;
    _startCtrl.text = widget.trip.startDate;
    _endCtrl.text = widget.trip.endDate;
    _budgetCtrl.text = widget.trip.budget.toStringAsFixed(2);
    _selectedCurrency = widget.trip.currency;

    if (widget.trip.city != null &&
        widget.trip.country != null &&
        widget.trip.countryCode != null &&
        widget.trip.lat != null &&
        widget.trip.lon != null) {
      _selectedDestination = (
        displayName: widget.trip.destination,
        city: widget.trip.city!,
        country: widget.trip.country!,
        countryCode: widget.trip.countryCode!,
        lat: widget.trip.lat!,
        lon: widget.trip.lon!,
      );
    }

    _setInitialBudgetInThb();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _destinationDebounce?.cancel();
    _titleCtrl.dispose();
    _destCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    developer.log('Start loading supported currencies', name: 'EditTrip');
    setState(() {
      _isLoadingCurrencies = true;
      _currencyLoadError = null;
    });

    try {
      final currencies = await _frankfurterService.fetchSupportedCurrencies();
      final map = <String, String>{
        for (final item in currencies) item.code: item.name,
      };

      if (!mounted) return;
      setState(() {
        _currencies = map;
        if (!_currencies.containsKey(_selectedCurrency) &&
            _currencies.isNotEmpty) {
          _selectedCurrency = _currencies.keys.first;
        }
      });
    } catch (e, st) {
      developer.log(
        'Failed to load currencies from API',
        name: 'EditTrip',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _currencyLoadError = 'Unable to load currencies from Frankfurt API';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrencies = false;
        });
      }
    }
  }

  Future<void> _onDestinationChanged(String value) async {
    _destinationEdited = true;

    if (_selectedDestination != null &&
        value != _selectedDestination!.displayName) {
      _selectedDestination = null;
    }

    _destinationDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _destinationSuggestions = [];
        _isSearchingDestination = false;
      });
      return;
    }

    _destinationDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingDestination = true);

      try {
        final suggestions = await _placesService.searchCityCountrySuggestions(
          query,
        );
        if (!mounted) return;
        setState(() {
          _destinationSuggestions = suggestions;
        });
      } catch (e, st) {
        developer.log(
          'Destination search failed',
          name: 'EditTrip',
          error: e,
          stackTrace: st,
        );
        if (!mounted) return;
        setState(() => _destinationSuggestions = []);
      } finally {
        if (mounted) {
          setState(() => _isSearchingDestination = false);
        }
      }
    });
  }

  void _selectDestinationSuggestion(DestinationSuggestion suggestion) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedDestination = suggestion;
      _destCtrl.text = suggestion.displayName;
      _destinationSuggestions = [];
      _destinationEdited = false;
    });
  }

  Future<void> _openCurrencyPicker() async {
    if (_currencies.isEmpty) return;

    final selected = await showCurrencyPickerBottomSheet(
      context: context,
      selectedCurrency: _selectedCurrency,
      currencies: _currencies,
    );

    if (selected != null && mounted) {
      setState(() => _selectedCurrency = selected);
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isEndDate,
  ) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    final lastDate = DateTime(2101);

    if (isEndDate && _startCtrl.text.isNotEmpty) {
      try {
        firstDate = DateFormat('MMM dd, yyyy').parse(_startCtrl.text);
        initialDate = firstDate;
      } catch (_) {
        initialDate = DateTime.now();
      }
    }

    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateFormat('MMM dd, yyyy').parse(controller.text);
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _setInitialBudgetInThb() async {
    if (widget.trip.budget <= 0) {
      _budgetCtrl.text = widget.trip.budget.toStringAsFixed(2);
      return;
    }

    if (widget.trip.currency == 'THB') {
      _budgetCtrl.text = widget.trip.budget.toStringAsFixed(2);
      return;
    }

    try {
      final budgetThb = await _frankfurterService.convertAmount(
        amount: widget.trip.budget,
        from: widget.trip.currency,
        to: 'THB',
      );
      if (!mounted) return;
      _budgetCtrl.text = budgetThb.toStringAsFixed(2);
    } catch (e, st) {
      developer.log(
        'Failed to convert existing budget to THB. Keeping original value.',
        name: 'EditTrip',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<double> _convertBudgetFromThb({
    required double budgetThb,
    required String targetCurrency,
  }) async {
    if (targetCurrency == 'THB') return budgetThb;

    final converted = await _frankfurterService.convertAmount(
      amount: budgetThb,
      from: 'THB',
      to: targetCurrency,
    );

    developer.log(
      'Converted budget THB=$budgetThb to $targetCurrency=$converted',
      name: 'EditTrip',
    );
    return converted;
  }

  Widget _buildDestinationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destination',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _destCtrl,
          onChanged: _onDestinationChanged,
          decoration: InputDecoration(
            hintText: 'Search city, country',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _isSearchingDestination
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[100]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        if (_destinationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _destinationSuggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _destinationSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_city_outlined),
                  title: Text(item.displayName),
                  subtitle: Text(
                    '${item.lat.toStringAsFixed(4)}, ${item.lon.toStringAsFixed(4)}',
                  ),
                  onTap: () => _selectDestinationSuggestion(item),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Trip',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomInputField(
                    label: 'Trip Title',
                    hint: 'e.g., Summer Vacation 2025',
                    controller: _titleCtrl,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 8),
                  _buildDestinationInput(),
                  const SizedBox(height: 16),
                  const Text(
                    'Travel Dates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateBox('Start Date', _startCtrl, false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateBox('End Date', _endCtrl, true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Base Currency',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildCurrencySelector(),
                  const SizedBox(height: 24),
                  CustomInputField(
                    label: 'Budget (THB)',
                    hint: 'e.g., 5000 (Thai Baht)',
                    controller: _budgetCtrl,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSavingTrip
                    ? null
                    : () async {
                        if (_titleCtrl.text.isEmpty) {
                          _showErrorDialog('Please enter trip title');
                          return;
                        }
                        if (_destCtrl.text.isEmpty) {
                          _showErrorDialog('Please enter destination');
                          return;
                        }
                        if (_destinationEdited &&
                            _selectedDestination == null) {
                          _showErrorDialog(
                            'Please select a destination from suggestions',
                          );
                          return;
                        }
                        if (_startCtrl.text.isEmpty) {
                          _showErrorDialog('Please select start date');
                          return;
                        }
                        if (_endCtrl.text.isEmpty) {
                          _showErrorDialog('Please select end date');
                          return;
                        }

                        try {
                          final startDate = DateFormat(
                            'MMM dd, yyyy',
                          ).parse(_startCtrl.text);
                          final endDate = DateFormat(
                            'MMM dd, yyyy',
                          ).parse(_endCtrl.text);
                          if (endDate.isBefore(startDate)) {
                            _showErrorDialog(
                              'End date must be after start date',
                            );
                            return;
                          }
                        } catch (_) {
                          _showErrorDialog('Invalid date format');
                          return;
                        }

                        final budgetThb = double.tryParse(
                          _budgetCtrl.text.replaceAll(',', '').trim(),
                        );
                        if (budgetThb == null || budgetThb < 0) {
                          _showErrorDialog(
                            'Please enter a valid budget in THB',
                          );
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          _showErrorDialog('Please Login');
                          return;
                        }

                        final destination = _selectedDestination;
                        setState(() => _isSavingTrip = true);

                        try {
                          final convertedBudget = await _convertBudgetFromThb(
                            budgetThb: budgetThb,
                            targetCurrency: _selectedCurrency,
                          );

                          final updatedTrip = Trip(
                            id: widget.trip.id,
                            title: _titleCtrl.text,
                            destination:
                                destination?.displayName ?? _destCtrl.text,
                            city: destination?.city ?? widget.trip.city,
                            country:
                                destination?.country ?? widget.trip.country,
                            countryCode:
                                destination?.countryCode ??
                                widget.trip.countryCode,
                            lat: destination?.lat ?? widget.trip.lat,
                            lon: destination?.lon ?? widget.trip.lon,
                            startDate: _startCtrl.text,
                            endDate: _endCtrl.text,
                            currency: _selectedCurrency,
                            budget: convertedBudget,
                            isFavorite: widget.trip.isFavorite,
                            userId: user.uid,
                          );

                          await DatabaseService().insertTrip(updatedTrip);
                        } catch (e, st) {
                          developer.log(
                            'Failed to convert/save trip budget during edit',
                            name: 'EditTrip',
                            error: e,
                            stackTrace: st,
                          );
                          if (mounted) {
                            _showErrorDialog(
                              'Unable to convert THB to $_selectedCurrency now. Please try again.',
                            );
                          }
                          return;
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingTrip = false);
                          }
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(
    String label,
    TextEditingController ctrl,
    bool isEndDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, ctrl, isEndDate),
          child: IgnorePointer(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Select date',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    final currentName = _currencies[_selectedCurrency] ?? 'Unknown currency';

    return InkWell(
      onTap: _isLoadingCurrencies ? null : _openCurrencyPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _isLoadingCurrencies
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    currencyFlagEmoji(_selectedCurrency),
                    style: const TextStyle(fontSize: 24),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCurrency,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currentName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_currencyLoadError != null)
                    Text(
                      _currencyLoadError!,
                      style: const TextStyle(color: Colors.red, fontSize: 11),
                    ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
