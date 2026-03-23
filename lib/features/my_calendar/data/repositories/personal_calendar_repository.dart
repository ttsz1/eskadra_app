import '../../domain/models/personal_calendar_entry.dart';
import '../datasources/private_calendar_remote_datasource.dart';
import '../models/personal_calendar_entry_model.dart';

class PersonalCalendarRepository {
  PersonalCalendarRepository(this.datasource);

  final PrivateCalendarRemoteDatasource datasource;

  Future<List<PersonalCalendarEntry>> getAllEntries() async {
    final rows = await datasource.fetchAllEntries();

    return rows
        .map(PersonalCalendarEntryModel.fromMap)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  Future<PersonalCalendarEntry> createEntry(
      PersonalCalendarEntry entry,
      ) async {
    final row = await datasource.insertEntry(
      title: entry.title,
      description: entry.description,
      startAt: entry.startAt,
      endAt: entry.endAt,
      allDay: entry.allDay,
    );

    return PersonalCalendarEntryModel.fromMap(row);
  }

  Future<PersonalCalendarEntry> updateEntry(
      PersonalCalendarEntry entry,
      ) async {
    final row = await datasource.updateEntry(
      id: entry.id,
      title: entry.title,
      description: entry.description,
      startAt: entry.startAt,
      endAt: entry.endAt,
      allDay: entry.allDay,
    );

    return PersonalCalendarEntryModel.fromMap(row);
  }

  Future<void> deleteEntry(String id) {
    return datasource.deleteEntry(id);
  }
}