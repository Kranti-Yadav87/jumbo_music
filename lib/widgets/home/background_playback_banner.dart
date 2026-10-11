import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/battery_optimization_service.dart';

class BackgroundPlaybackBanner extends StatefulWidget {
  const BackgroundPlaybackBanner({super.key});

  @override
  State<BackgroundPlaybackBanner> createState() =>
      _BackgroundPlaybackBannerState();
}

class _BackgroundPlaybackBannerState extends State<BackgroundPlaybackBanner> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    // Warm check optimization status on mount
    BatteryOptimizationService.instance.checkOptimizationStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            BatteryOptimizationService.mockIsIgnored == null)) {
      return const SizedBox.shrink();
    }

    final service = BatteryOptimizationService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (!service.hasChecked || service.isOptimizationIgnored) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.battery_charging_full_rounded,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Uninterrupted Background Play',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prevent Android battery cleaner from stopping music when screen turns off.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await service.requestIgnoreBatteryOptimization();
                },
                child: const Text(
                  'Allow',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _dismissed = true);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
