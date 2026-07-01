-- leakless — auto-provision a new user.
--
-- On sign-up, create the user's profile, a starter household, their owner
-- membership, and a set of default categories, then link the profile to the
-- household. This means a brand-new Supabase user lands in a fully working
-- household with no extra round-trips from the app.

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

  insert into public.categories (household_id, name, icon_name, is_default)
  values
    (new_household_id, 'Supermercado', 'cart', true),
    (new_household_id, 'Restaurantes', 'restaurant', true),
    (new_household_id, 'Transporte', 'car', true),
    (new_household_id, 'Ocio', 'movie', true),
    (new_household_id, 'Suscripciones', 'subscriptions', true),
    (new_household_id, 'Ahorro', 'savings', true);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
