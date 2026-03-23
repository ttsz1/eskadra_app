import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/private_calendar_remote_datasource.dart';
import '../../data/repositories/personal_calendar_repository.dart';

final privateCalendarDatasourceProvider =
Provider<PrivateCalendarRemoteDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PrivateCalendarRemoteDatasource(client);
});

final privateCalendarRepositoryProvider =
Provider<PersonalCalendarRepository>((ref) {
  final datasource = ref.watch(privateCalendarDatasourceProvider);
  return PersonalCalendarRepository(datasource);
});