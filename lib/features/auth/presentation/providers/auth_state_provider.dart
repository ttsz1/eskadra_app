import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/auth/current_user_provider.dart';

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authSessionProvider);

  return authState.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => false,
  );
});