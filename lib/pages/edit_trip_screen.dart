import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
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
  final _budgetCtrl = TextEditingController(); // Added budget controller

  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.trip.title;
    _destCtrl.text = widget.trip.destination;
    _startCtrl.text = widget.trip.startDate;
    _endCtrl.text = widget.trip.endDate;
    _budgetCtrl.text = widget.trip.budget.toString();
    _selectedCurrency = widget.trip.currency;
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isEndDate,
  ) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);

    // ถ้าเป็น End Date ให้ firstDate เป็น Start Date ที่เลือก
    if (isEndDate && _startCtrl.text.isNotEmpty) {
      try {
        firstDate = DateFormat('MMM dd, yyyy').parse(_startCtrl.text);
        initialDate = firstDate;
      } catch (e) {
        // ถ้าแปลงวันที่ไม่ได้ให้ใช้วันปัจจุบัน
        initialDate = DateTime.now();
      }
    }

    // ใช้วันที่เก่าเป็น initialDate ถ้ามีค่าอยู่แล้ว
    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateFormat('MMm dd, yyyy').parse(controller.text);
      }
    } catch (e) {
      // If parse fails, use the firstDate or current date
    }

    DateTime? picked = await showDatePicker(
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
          "Edit Trip",
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
                    label: "Trip Title",
                    hint: "e.g., Summer Vacation 2025",
                    controller: _titleCtrl,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 8),
                  CustomInputField(
                    label: "Destination",
                    hint: "Search for a destination",
                    controller: _destCtrl,
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Travel Dates",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDateBox("Start Date", _startCtrl, false)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateBox("End Date", _endCtrl, true)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Base Currency",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildCurrencySelector(),
                  const SizedBox(height: 24),
                  // Preserving budget field as it's part of the model
                  CustomInputField(
                    label: "Budget",
                    hint: "e.g., 5000",
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
                onPressed: () async {
                  // ตรวจสอบข้อมูล
                  if (_titleCtrl.text.isEmpty) {
                    _showErrorDialog('Please enter trip title');
                    return;
                  }
                  if (_destCtrl.text.isEmpty) {
                    _showErrorDialog('Please enter destination');
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

                  // ตรวจสอบว่า End Date ไม่น้อยกว่า Start Date
                  try {
                    DateTime startDate = DateFormat('MMM dd, yyyy').parse(_startCtrl.text);
                    DateTime endDate = DateFormat('MMM dd, yyyy').parse(_endCtrl.text);
                    
                    if (endDate.isBefore(startDate)) {
                      _showErrorDialog('End date must be after start date');
                      return;
                    }
                  } catch (e) {
                    _showErrorDialog('Invalid date format');
                    return;
                  }

                  // Create updated trip object
                  // Using conflictAlgorithm.replace in insertTrip will update existing ID
                  final updatedTrip = Trip(
                    id: widget.trip.id,
                    title: _titleCtrl.text,
                    destination: _destCtrl.text,
                    startDate: _startCtrl.text,
                    endDate: _endCtrl.text,
                    currency: _selectedCurrency,
                    budget: double.tryParse(_budgetCtrl.text) ?? 0,
                  );
                  await DatabaseService().insertTrip(updatedTrip);

                  if (mounted)
                    Navigator.pop(
                      context,
                      true,
                    ); // Return true to indicate update
                },
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildDateBox(String label, TextEditingController ctrl, bool isEndDate) {
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
                hintText: "Select date",
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text("🇺🇸", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCurrency,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "US Dollar",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }
}
