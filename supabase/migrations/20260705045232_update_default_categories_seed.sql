-- Keep automatic household provisioning aligned with the complete default
-- category catalog.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_household_id uuid;
  display text;
begin
  display := coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1));

  insert into public.households (name, owner_id)
  values ('Nuestra casa', new.id)
  returning id into new_household_id;

  insert into public.profiles (id, display_name, household_id)
  values (new.id, display, new_household_id);

  insert into public.household_members (household_id, user_id, display_name, role)
  values (new_household_id, new.id, display, 'owner');

  insert into public.categories (household_id, name, icon_name, is_default, slug)
  values
    (new_household_id, 'Supermercado', 'cart', true, 'groceries'),
    (new_household_id, 'Restaurantes', 'restaurant', true, 'dining'),
    (new_household_id, 'Transporte', 'car', true, 'transport'),
    (new_household_id, 'Ocio', 'movie', true, 'leisure'),
    (new_household_id, 'Suscripciones', 'subscriptions', true, 'subscriptions'),
    (new_household_id, 'Ahorro', 'savings', true, 'savings'),
    (new_household_id, 'Gastos esenciales', 'essentials', true, 'essentials'),
    (new_household_id, 'Estudios', 'education', true, 'education'),
    (new_household_id, 'Reserva de emergencia', 'emergency', true, 'emergency_fund'),
    (new_household_id, 'Salud', 'health', true, 'health');

  return new;
end;
$$;
