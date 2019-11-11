-- Create types --------------------------------------------------------------------------------------------------------
drop type if exists state_machine_resource_state;
create type state_machine_resource_state as enum ('pending', 'complete', 'deleted');

-- Create tables -------------------------------------------------------------------------------------------------------
drop table if exists state_machine_resources;
create table if not exists state_machine_resources
(
    -- Primary key ----------
    id                         uuid                         not null default uuid_generate_v4() primary key, --immutable

    -- User set values ----------
    name                       varchar(255)                 not null unique,
    public                     boolean                      not null default false,

    -- System set values ----------
    state                      state_machine_resource_state not null default 'pending',

    -- Foreign key(s) ----------

    -- State machine: Time stamps ----------
    state_machine_pending_at   timestamp with time zone     not null default now(),
    state_machine_complete_at timestamp with time zone              default null,
    state_machine_deleted_at   timestamp with time zone              default null,

    -- Automata ----------
    automated_created_at       timestamp with time zone     not null default now(),                          --immutable
    automated_updated_at       timestamp with time zone,
    automated_revision         int                          not null default 0
);

-- Create functions ----------------------------------------------------------------------------------------------------
drop function if exists public.state_machine_resources_enforce_state_machine();
create or replace function public.state_machine_resources_enforce_state_machine() returns trigger as
$$
begin
    if tg_op = 'INSERT' then
        new.state = 'pending';
        new.state_machine_pending_at = now();
        new.state_machine_complete_at = null;
        new.state_machine_deleted_at = null;
        return new;

    elsif tg_op = 'UPDATE' and row (new.*) is distinct from row (old.*) then

        -- Enforce immutability of non-regressive states ----------
        if old.state_machine_pending_at is not null and
           new.state_machine_pending_at is distinct from old.state_machine_pending_at then
            raise exception 'invalid state timestamp update, `state_machine_pending_at` is immutable';
        end if;

        if old.state_machine_complete_at is not null and
           new.state_machine_complete_at is distinct from old.state_machine_complete_at then
            raise exception 'invalid state timestamp update, `state_machine_complete_at` is immutable';
        end if;

        -- Handle/Enforce state transition ----------
        if old.state is distinct from new.state then
            if old.state = 'pending' and new.state = 'complete' then
                new.state_machine_complete_at = now();
            elsif old.state = 'complete' and new.state = 'deleted' then
                new.state_machine_deleted_at = now();
            elsif old.state = 'deleted' and new.state = 'complete' then
                new.state_machine_deleted_at = null;
            else
                raise exception 'invalid state progression, valid state transitions are: `pending` -> `complete` <-> `deleted`';
            end if;
        end if;

        -- Enforce state/property validity ----------
        if new.state = 'pending' then
            -- Check timestamps ----------
            if (new.state_machine_pending_at is null) then
                raise exception 'invalid state timestamps, `pending` requires: `state_machine_pending_at`';
            end if;

            if (new.state_machine_complete_at is not null or new.state_machine_deleted_at is not null) then
                raise exception 'invalid state timestamps, `pending` forbids: `state_machine_complete_at` `state_machine_deleted_at`';
            end if; -- Check expected null/not-null properties ----------

        -- Check for exclusive mutability of expected fields ----------

        elsif new.state = 'complete' then
            -- Check timestamps ----------
            if (new.state_machine_pending_at is null or new.state_machine_complete_at is null) then
                raise exception 'invalid state timestamps, `complete` requires: `state_machine_pending_at` `state_machine_complete_at`';
            end if;

            if (new.state_machine_deleted_at is not null) then
                raise exception 'invalid state timestamps, `complete` forbids: `state_machine_deleted_at`';
            end if; -- Check expected null/not-null properties ----------

        -- Check for exclusive mutability of expected fields ----------

        elsif new.state = 'deleted' then
            -- Check timestamps ----------
            if (new.state_machine_pending_at is null or new.state_machine_complete_at is null or
                new.state_machine_deleted_at is null) then
                raise exception 'invalid state timestamps, `deleted` requires: `state_machine_pending_at` `state_machine_complete_at` `state_machine_deleted_at`';
            end if; -- Check expected null/not-null properties ----------

        -- Check for exclusive mutability of expected fields ----------

        end if;

        -- Enforce IDPD edicts ----------
        if (new.state_machine_complete_at is not null and new.state_machine_complete_at < new.state_machine_pending_at) or
           (new.state_machine_deleted_at is not null and new.state_machine_deleted_at < new.state_machine_complete_at) then
            raise exception 'invalid state timestamp sequence, one of the state machine timestamps violates expected linear order';
        end if;

    elsif tg_op = 'DELETE' then

        -- Enforce forbidden deletes on complete state_machine_resources
        if old.state_machine_complete_at is not null then
            raise exception 'deleting a complete state_machine_resource is not permitted';
        else
            return old;
        end if;

    end if;

    return new;
end;
$$ language 'plpgsql';

drop function if exists public.state_machine_resources_default_state_machine_resource_id();
create or replace function public.state_machine_resources_default_state_machine_resource_id() returns uuid as
$$
begin
    return ( select id from state_machine_resources where name = 'Free to Use Starter' limit 1 );
end;
$$ language 'plpgsql';

-- Create triggers -----------------------------------------------------------------------------------------------------

-- Enforce shared immutable properties ----------
drop trigger if exists trigger_shared_enforce_immutable_properties on state_machine_resources;
create trigger trigger_shared_enforce_immutable_properties
    before update
    on public.state_machine_resources
    for each row
execute procedure shared_enforce_immutable_properties();

-- Maintain automated fields ----------
drop trigger if exists trigger_shared_maintain_automated_properties on state_machine_resources;
create trigger trigger_shared_maintain_automated_properties
    before insert or update
    on public.state_machine_resources
    for each row
execute procedure public.shared_maintain_automated_properties();

-- Protect data from TRUNCATE under all conditions ----------
drop trigger if exists trigger_prevent_protected_data_destruction on state_machine_resources;
create trigger trigger_prevent_protected_data_destruction
    before truncate
    on public.state_machine_resources
execute procedure public.shared_prevent_protected_data_destruction();

-- Enforce state machine ----------
drop trigger if exists trigger_state_machine_resources_enforce_state_machine on state_machine_resources;
create trigger trigger_state_machine_resources_enforce_state_machine
    before insert or update or delete
    on public.state_machine_resources
    for each row
execute procedure state_machine_resources_enforce_state_machine();

-- Insert default data -------------------------------------------------------------------------------------------------
insert into state_machine_resources (name, public)
values ('Default resource', true);

update state_machine_resources
set state = 'complete'
where name = 'Default resource';