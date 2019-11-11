-- Create types --------------------------------------------------------------------------------------------------------

-- Create tables -------------------------------------------------------------------------------------------------------
drop table if exists users;
create table if not exists users
(
    -- Primary key ----------
    id                   uuid                     not null default uuid_generate_v4() primary key, --immutable

    -- User set values ----------
    first_name           varchar(255),
    last_name            varchar(255),
    
    meta                 jsonb                    not null default '{}'::jsonb,

    -- System set values ----------
    authority_id         varchar(255)             not null unique,                                 --immutable

    agreed_to_eula_at    timestamp with time zone,                                                 --immutable

    -- Foreign key(s) ----------

    -- Automata ----------
    automated_created_at timestamp with time zone not null default now(),                          --immutable
    automated_updated_at timestamp with time zone,
    automated_revision   int                      not null default 0
);

-- Create functions ----------------------------------------------------------------------------------------------------
drop function if exists public.users_enforce_immutable_properties();
create or replace function public.users_enforce_immutable_properties() returns trigger as
$$
begin
    if tg_op = 'UPDATE' then
        if old.authority_id is not null and new.authority_id is distinct from old.authority_id then
            raise exception 'invalid update `authority_id` is immutable';
        end if;

        if old.agreed_to_eula_at is not null and new.agreed_to_eula_at is distinct from old.agreed_to_eula_at then
            raise exception 'invalid update `agreed_to_eula_at` is immutable';
        end if;

        return new;
    end if;
end;
$$ language 'plpgsql';

-- Create triggers -----------------------------------------------------------------------------------------------------

-- Enforce shared immutable properties ----------
drop trigger if exists trigger_shared_enforce_immutable_properties on users;
create trigger trigger_shared_enforce_immutable_properties
    before update
    on public.users
    for each row
execute procedure shared_enforce_immutable_properties();

-- Maintain automated fields ----------
drop trigger if exists trigger_shared_maintain_automated_properties on users;
create trigger trigger_maintain_automated_properties
    before insert or update
    on public.users
    for each row
execute procedure shared_maintain_automated_properties();

-- Protect data from DELETE and TRUNCATE under all conditions ----------
drop trigger if exists trigger_shared_prevent_protected_data_destruction on users;
create trigger trigger_prevent_protected_data_destruction
    before truncate
    on public.users
execute procedure shared_prevent_protected_data_destruction();

-- Block changes to immutable properties ----------
drop trigger if exists trigger_users_enforce_immutable_properties on users;
create trigger trigger_users_enforce_immutable_properties
    before update
    on public.users
    for each row
execute procedure users_enforce_immutable_properties();

-- Insert default data -------------------------------------------------------------------------------------------------