-- Create types --------------------------------------------------------------------------------------------------------

-- Create tables -------------------------------------------------------------------------------------------------------

-- Create functions ----------------------------------------------------------------------------------------------------
drop function if exists public.shared_enforce_immutable_properties();
create or replace function public.shared_enforce_immutable_properties() returns trigger as
$$
begin
    if tg_op = 'UPDATE' then

        if old.id is not null and new.id is distinct from old.id then
            raise exception 'invalid state update, `id` is immutable';
        end if;

        if old.automated_created_at is not null and new.automated_created_at is distinct from old.automated_created_at then
            raise exception 'invalid state update, `automated_created_at` is immutable';
        end if;

        return new;
    end if;
end;
$$ language 'plpgsql';

-- Create triggers -----------------------------------------------------------------------------------------------------

-- Insert default data -------------------------------------------------------------------------------------------------
