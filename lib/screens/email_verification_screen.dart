import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'main_navigation_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  const EmailVerificationScreen({super.key, this.onVerified});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _timer;
  String? _message;
  bool _isSuccessMessage = true;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final isVerified = await AuthService.instance.reloadUser();
      if (isVerified && mounted) {
        _timer?.cancel();
        _proceed();
      }
    });
  }

  void _proceed() {
    if (widget.onVerified != null) {
      widget.onVerified!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    final isVerified = await AuthService.instance.reloadUser();

    if (mounted) {
      setState(() => _isChecking = false);
      if (isVerified) {
        _proceed();
      } else {
        setState(() {
          _message =
              'Email is not verified yet. Please check your inbox and click the verification link.';
          _isSuccessMessage = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      await AuthService.instance.sendEmailVerification();
      if (mounted) {
        setState(() {
          _message =
              'Verification email resent! Check your inbox and spam folder.';
          _isSuccessMessage = true;
          _resendCooldown = 60;
        });

        Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            if (_resendCooldown > 0) {
              _resendCooldown--;
            } else {
              t.cancel();
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message =
              'Could not resend email: ${AuthService.formatAuthError(e)}';
          _isSuccessMessage = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _continueAsGuest() async {
    final randomId =
        'JM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    await DatabaseService.instance.login(
      email: 'guest.listener@jumbomusic.app',
      name: 'Guest Explorer',
      userId: randomId,
    );
    if (mounted) {
      _proceed();
    }
  }

  Future<void> _signOut() async {
    _timer?.cancel();
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D15),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4B2B), Color(0xFFFF416C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4B2B).withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'We sent an activation link to:\n$userEmail\n\nPlease check your inbox and confirm your address to sync your music and playlists.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_message != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isSuccessMessage
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSuccessMessage
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : Colors.redAccent.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccessMessage
                                ? Icons.check_circle_outline_rounded
                                : Icons.info_outline_rounded,
                            color: _isSuccessMessage
                                ? const Color(0xFF10B981)
                                : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccessMessage
                                    ? const Color(0xFF10B981)
                                    : Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B2B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isChecking ? null : _checkStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _isChecking
                            ? 'Checking...'
                            : "I've Verified (Check Status)",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF191926),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_resendCooldown > 0 || _isResending)
                        ? null
                        : _resendVerificationEmail,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFFF5E3A),
                      size: 18,
                    ),
                    label: Text(
                      _resendCooldown > 0
                          ? 'Resend available in ${_resendCooldown}s'
                          : 'Resend Verification Email',
                      style: TextStyle(
                        color: _resendCooldown > 0
                            ? Colors.white38
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white12)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white60,
                      size: 16,
                    ),
                    label: const Text(
                      'Continue as Guest for now',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: _continueAsGuest,
                  ),

                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white38,
                      size: 16,
                    ),
                    label: const Text(
                      'Sign Out / Use different email',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
