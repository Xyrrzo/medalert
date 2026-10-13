-- Add this column to the existing profiles table for account-synced Health Tools data.
alter table public.profiles
  add column if not exists health_data jsonb not null default '{}'::jsonb;
