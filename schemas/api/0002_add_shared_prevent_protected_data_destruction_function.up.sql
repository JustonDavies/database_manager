-- Create types --------------------------------------------------------------------------------------------------------

-- Create tables -------------------------------------------------------------------------------------------------------

-- Create functions ----------------------------------------------------------------------------------------------------
drop function if exists public.shared_prevent_protected_data_destruction();
create or replace function public.shared_prevent_protected_data_destruction() returns trigger as
$$
begin
    if (tg_op = 'DELETE') or (tg_op = 'TRUNCATE') then
        raise exception 'cannot DELETE or TRUNCATE protected data';
    else
        return old;
    end if;
end;
$$ language 'plpgsql';

-- Create triggers -----------------------------------------------------------------------------------------------------

-- Insert default data -------------------------------------------------------------------------------------------------
