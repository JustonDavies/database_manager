-- Create types --------------------------------------------------------------------------------------------------------

-- Create tables -------------------------------------------------------------------------------------------------------

-- Create functions ----------------------------------------------------------------------------------------------------
drop function if exists public.shared_maintain_automated_properties();
create or replace function public.shared_maintain_automated_properties() returns trigger as
$$
begin
    if (tg_op = 'INSERT') then
        new.automated_created_at = now();
        new.automated_updated_at = null;
        new.automated_revision = 0;
        return new;
    elsif (tg_op = 'UPDATE') then
        if row (new.*) is distinct from row (old.*) then
            new.automated_created_at = old.automated_created_at;
            new.automated_updated_at = now();
            new.automated_revision = old.automated_revision + 1;
            return new;
        else
            return old;
        end if;
    end if;
end;
$$ language 'plpgsql';

-- Create triggers -----------------------------------------------------------------------------------------------------

-- Insert default data -------------------------------------------------------------------------------------------------