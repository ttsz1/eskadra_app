insert into public.profiles (id, email, full_name, org_unit, org_function, personnel_type, rank_group)
values
  ('11111111-1111-1111-1111-111111111111', 'jan.kowalski@eskadra.local', 'Jan Kowalski', 'command', 'commander', 'pilot', 'officer'),
  ('22222222-2222-2222-2222-222222222222', 'piotr.nowak@eskadra.local', 'Piotr Nowak', 'command', 'personnel', 'ground_staff', 'officer'),
  ('33333333-3333-3333-3333-333333333333', 'anna.wisniewska@eskadra.local', 'Anna Wiśniewska', 'current_operations_section', 'chief', 'pilot', 'officer'),
  ('44444444-4444-4444-4444-444444444444', 'marek.zielinski@eskadra.local', 'Marek Zieliński', 'current_operations_section', 'personnel', 'ground_staff', 'non_commissioned_officer'),
  ('55555555-5555-5555-5555-555555555555', 'ewa.dabrowska@eskadra.local', 'Ewa Dąbrowska', 'flight_training_section', 'chief', 'pilot', 'officer')
on conflict (id) do update
set
  email = excluded.email,
  full_name = excluded.full_name,
  org_unit = excluded.org_unit,
  org_function = excluded.org_function,
  personnel_type = excluded.personnel_type,
  rank_group = excluded.rank_group;