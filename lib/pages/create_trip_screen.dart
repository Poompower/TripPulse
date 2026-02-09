import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // อย่าลืมเพิ่ม intl ใน pubspec.yaml
import '../widgets/custom_input.dart';
import '../models/trip.dart';
import '../services/database_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _titleCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  // ฟังก์ชันแสดง Error Dialog
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

  // ฟังก์ชันเลือกวันที่
  Future<void> _selectDate(BuildContext context, TextEditingController controller, bool isEndDate) async {
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
        title: const Text("Create Trip", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                  const Text("Travel Dates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDateBox("Start Date", _startCtrl, false)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateBox("End Date", _endCtrl, true)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Base Currency", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildCurrencySelector(),
                  // คุณสามารถเพิ่มช่อง Budget ตรงนี้ได้ถ้าต้องการ
                  const SizedBox(height: 24),
                  CustomInputField(
                    label: "Budget",
                    hint: "e.g., 5000",
                    controller: _budgetCtrl,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
            ),
          ),
          // ปุ่ม Save Trip ด้านล่างสุด
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A), // สีดำตาม UI
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                  await DatabaseService().insertTrip(Trip(
                    title: _titleCtrl.text,
                    destination: _destCtrl.text,
                    startDate: _startCtrl.text,
                    endDate: _endCtrl.text,
                    currency: "USD",
                    budget: double.tryParse(_budgetCtrl.text) ?? 0,
                  ));
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Save Trip", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
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
                prefixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.blue, size: 20),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
          // ส่วนนี้แนะนำให้ใช้ Image.asset หรือ Icon แทน
          const Text("🇺🇸", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("USD", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("US Dollar", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }
}