-- Manual RLS checks. Run as the indicated authenticated test user via the Supabase SQL Editor
-- (or an API client with that user's JWT). Replace the UUIDs/values with disposable test data.
-- These are intentionally comments: each check that should fail is expected to raise a permission error
-- or affect zero rows. Never use a service_role key for these checks.

-- As PATIENT A, selecting PATIENT B's appointments returns no rows:
-- select * from public.appointments where user_id = '<PATIENT_B_UUID>';

-- As PATIENT A, inserting an appointment with status confirmed must fail:
-- insert into public.appointments (user_id, patient_name, health_unit_id, appointment_type, appointment_date, appointment_time, status)
-- values (auth.uid(), 'Test', 1, 'Checkup', current_date, '09:00', 'confirmed');

-- As PATIENT A, changing own profile role must fail:
-- update public.profiles set role = 'ADMIN' where id = auth.uid();

-- As MEDSTAFF, changing another profile role must fail:
-- update public.profiles set role = 'ADMIN' where id = '<PATIENT_A_UUID>';

-- As MEDSTAFF, reminders are inaccessible (returns no rows; writes affect zero rows or fail):
-- select * from public.reminders;

-- As PATIENT A, selecting own appointment is allowed; selecting PATIENT B's symptom report is not.
-- As MEDSTAFF, listing appointments/reports and changing only appointment status or handled is allowed.
-- As non-ADMIN, insert/update/delete on health_units and delete on appointments/announcements/reports must fail.
