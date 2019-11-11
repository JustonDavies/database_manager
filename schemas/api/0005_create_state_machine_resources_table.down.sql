-- Drop triggers -------------------------------------------------------------------------------------------------------
drop trigger if exists trigger_shared_enforce_immutable_properties on state_machine_resources;
drop trigger if exists trigger_shared_maintain_automated_properties on state_machine_resources;
drop trigger if exists trigger_shared_prevent_protected_data_destruction on state_machine_resources;

drop trigger if exists trigger_state_machine_resources_enforce_state_machine on state_machine_resources;

-- Drop functions ------------------------------------------------------------------------------------------------------
drop function if exists public.state_machine_resources_default_resource_id();
drop function if exists public.state_machine_resources_enforce_state_machine();

-- Drop tables ---------------------------------------------------------------------------------------------------------
drop table if exists state_machine_resources;

-- Drop types ----------------------------------------------------------------------------------------------------------
drop type if exists state_machine_resource_state;