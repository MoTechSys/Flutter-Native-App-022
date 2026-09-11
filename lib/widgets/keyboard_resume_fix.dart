// ============================================================
// EduAcademy - إصلاح اختفاء الكيبورد بعد الرجوع إلى التطبيق (Android)
//
// المشكلة: عند وجود حقل نص مُركَّز (كلمة المرور / رمز التحقق) ثم الخروج
// من التطبيق والرجوع إليه، يبقى الحقل مُركَّزاً منطقياً لكن لوحة المفاتيح
// لا تظهر (خلل معروف في اتصال Flutter بـ IME بعد onResume).
//
// الحل: نراقب دورة حياة التطبيق؛ عند `resumed` وإذا كان هناك حقل نص
// مُركَّز، نُلغي التركيز ثم نعيده بعد إطار واحد ونطلب من النظام إظهار
// لوحة المفاتيح صراحةً. الخوارزمية آمنة على كل المنصات (لا تفعل شيئاً
// إن لم يكن هناك حقل مُركَّز).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardResumeFix extends StatefulWidget {
  final Widget child;
  const KeyboardResumeFix({super.key, required this.child});

  @override
  State<KeyboardResumeFix> createState() => _KeyboardResumeFixState();
}

class _KeyboardResumeFixState extends State<KeyboardResumeFix>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final focus = FocusManager.instance.primaryFocus;
    // نهتم فقط بحقول الإدخال (EditableText) لا بأي عنصر مُركَّز آخر
    final ctx = focus?.context;
    if (focus == null || ctx == null) return;
    final isTextField =
        ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null ||
        ctx.findAncestorStateOfType<EditableTextState>() != null;
    if (!isTextField) return;

    focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focus.requestFocus();
      // طلب صريح لإظهار لوحة المفاتيح من النظام
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
