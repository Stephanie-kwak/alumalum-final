import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/form_bits.dart';

/// 로그인. 피그마에 없는 화면이라 가입 화면과 같은 모양으로 만들었다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _id = '', _pw = '';
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    if (_id.trim().isEmpty || _pw.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 적어 주세요');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // 로그인되면 라우터가 홈으로 보낸다. 가입 도중 끊겨 프로필이 없는 계정이면 여기 남아 안내한다.
      final auth = context.read<AuthService>();
      final users = context.read<UserRepository>();
      final uid = await auth.signIn(_id, _pw);
      if (await users.watch(uid).first == null) {
        await auth.signOut();
        if (mounted) setState(() => _error = '가입이 끝나지 않은 아이디예요. 다른 아이디로 다시 가입해 주세요');
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.messageOf(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          const Text('다시 오셨네요', style: AppText.h1),
          const SizedBox(height: 6),
          const Text('가입할 때 만든 아이디로 로그인해 주세요.', style: AppText.lead),
          const SizedBox(height: 26),
          const FieldLabel('아이디'),
          AppTextField(fieldKey: const Key('loginId'), hint: '아이디', onChanged: (v) => _id = v),
          const SizedBox(height: 18),
          const FieldLabel('비밀번호'),
          AppTextField(fieldKey: const Key('password'), hint: '비밀번호', obscure: true, error: _error, onChanged: (v) => _pw = v),
          const SizedBox(height: 26),
          AppButton(_busy ? '로그인 중…' : '로그인', onPressed: _busy ? null : _submit),
        ],
      ),
    );
  }
}
