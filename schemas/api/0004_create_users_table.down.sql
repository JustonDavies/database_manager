-- Drop triggers -------------------------------------------------------------------------------------------------------
drop trigger if exists trigger_shared_enforce_immutable_properties on users;
drop trigger if exists trigger_shared_maintain_automated_properties on users;
drop trigger if exists trigger_shared_prevent_protected_data_destruction on users;

drop trigger if exists trigger_users_enforce_immutable_properties on users;

-- Drop functions ------------------------------------------------------------------------------------------------------
drop function if exists public.users_enforce_immutable_properties();

-- Drop tables ---------------------------------------------------------------------------------------------------------
drop table if exists users;

-- Drop types ----------------------------------------------------------------------------------------------------------