import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/database_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Activity _activity;
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _titleCtrl.text = _activity.title;
    _locationCtrl.text = _activity.location ?? '';
    _timeCtrl.text = _activity.time ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeCtrl.text = picked.format(context);
      });
    }
  }

  void _saveChanges() async {
    final updatedActivity = Activity(
      id: _activity.id,
      tripId: _activity.tripId,
      dayNumber: _activity.dayNumber,
      title: _titleCtrl.text,
      location: _locationCtrl.text.isNotEmpty ? _locationCtrl.text : null,
      time: _timeCtrl.text.isNotEmpty ? _timeCtrl.text : null,
      imageUrl: _activity.imageUrl,
      category: _activity.category,
    );

    await DatabaseService().insertActivity(updatedActivity);
    setState(() {
      _activity = updatedActivity;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity updated successfully')),
      );
    }
  }

  void _deleteActivity() async {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().deleteActivity(
                _activity.tripId,
                _activity.id,
              );
              if (!rootContext.mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(rootContext, true); // Return to previous screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
          'Itinerary Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Day',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Day ${_activity.dayNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isEditing) _buildEditForm() else _buildViewMode(),
                ],
              ),
            ),
          ),
          if (_isEditing)
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
                  onPressed: _saveChanges,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _deleteActivity,
                  child: const Text(
                    'Delete Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailField('Title', _activity.title, Icons.title),
        const SizedBox(height: 16),
        if (_activity.location != null && _activity.location!.isNotEmpty)
          Column(
            children: [
              _buildDetailField(
                'Location',
                _activity.location!,
                Icons.location_on,
              ),
              const SizedBox(height: 16),
            ],
          ),
        if (_activity.time != null && _activity.time!.isNotEmpty)
          _buildDetailField('Time', _activity.time!, Icons.schedule),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditField('Title', _titleCtrl),
        const SizedBox(height: 16),
        _buildEditField('Location', _locationCtrl, icon: Icons.location_on),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              child: IgnorePointer(
                child: TextField(
                  controller: _timeCtrl,
                  decoration: InputDecoration(
                    hintText: 'Select time',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.schedule_outlined,
                      color: Colors.blue,
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
        ),
      ],
    );
  }

  Widget _buildDetailField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
