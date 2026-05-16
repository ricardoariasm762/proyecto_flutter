import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ride_service.dart';
import '../core/localization/language_controller.dart';
import '../core/localization/app_dictionary.dart';

class IncomingRequestScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final bool isDriverPing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingRequestScreen({
    super.key,
    required this.requestData,
    required this.isDriverPing,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingRequestScreen> createState() => _IncomingRequestScreenState();
}

class _IncomingRequestScreenState extends State<IncomingRequestScreen> {
  final _rideService = RideService();
  String _requesterName = "...";

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    final userId = widget.isDriverPing
        ? widget.requestData['creator_id']?.toString()
        : widget.requestData['user_id']?.toString();

    if (userId != null) {
      final name = await _rideService.getUserName(userId);
      if (mounted) {
        setState(() {
          _requesterName = name;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _requesterName = "User";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>().currentLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isDriverPing
                      ? Icons.local_taxi_rounded
                      : Icons.person_add_alt_1_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                widget.isDriverPing
                    ? AppDictionary.text(lang, 'ride_requested')
                    : AppDictionary.text(lang, 'new_request'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _requesterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isDriverPing
                    ? AppDictionary.text(lang, 'driver_ping_desc')
                    : AppDictionary.text(lang, 'passenger_ping_desc'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      label: AppDictionary.text(lang, 'deny'),
                      color: Colors.white.withValues(alpha: 0.1),
                      textColor: Colors.white,
                      onPressed: widget.onReject,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildButton(
                      label: AppDictionary.text(lang, 'accept'),
                      color: Colors.white,
                      textColor: Colors.black,
                      onPressed: widget.onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
