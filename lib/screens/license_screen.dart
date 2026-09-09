// ============================================================
// EduAcademy - شاشة التفعيل (تظهر عند إيقاف النسخة من ملف التحكم)
// ============================================================

import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../theme.dart';

class LicenseScreen extends StatefulWidget {
  final LicenseState state;
  final VoidCallback onActivated;
  const LicenseScreen({
    super.key,
    required this.state,
    required this.onActivated,
  });

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _ctl = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _rechecking = false;

  Future<void> _activate() async {
    if (_ctl.text.trim().isEmpty) {
      setState(() => _error = 'أدخل كود التفعيل');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await LicenseService.activate(_ctl.text);
    if (!mounted) return;
    if (ok) {
      widget.onActivated();
    } else {
      setState(() {
        _busy = false;
        _error = 'الكود غير صحيح أو غير مسموح حالياً';
      });
    }
  }

  /// إعادة قراءة ملف التحكم مباشرة (لو تم تفعيل النسخة عن بُعد)
  Future<void> _recheck() async {
    setState(() => _rechecking = true);
    final st = await LicenseService.check();
    if (!mounted) return;
    setState(() => _rechecking = false);
    if (st.allowed) {
      widget.onActivated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            st.offline
                ? 'لا يوجد اتصال بالإنترنت للتحقق'
                : 'النسخة ما زالت غير مفعّلة',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deleted = !widget.state.codeAccepted;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  deleted ? 'انتهى ترخيص النسخة' : 'النسخة تحتاج تفعيل',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.state.message.isNotEmpty
                      ? widget.state.message
                      : 'يرجى التواصل مع المطوّر للحصول على كود التفعيل.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDim, height: 1.6),
                ),
                const SizedBox(height: 32),
                if (!deleted) ...[
                  TextField(
                    controller: _ctl,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(letterSpacing: 2, fontSize: 16),
                    onSubmitted: (_) => _activate(),
                    decoration: InputDecoration(
                      labelText: 'كود التفعيل',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _activate,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('تفعيل'),
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton.icon(
                  onPressed: _rechecking ? null : _recheck,
                  icon: _rechecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('إعادة التحقق من الترخيص'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
