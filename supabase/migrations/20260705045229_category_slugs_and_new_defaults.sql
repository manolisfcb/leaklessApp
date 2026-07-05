-- Add stable identifiers for default categories so their display names can be
-- localized independently from the data stored for each household.

alter table public.categories
  add column if not exists slug text;

update public.categories
set slug = case icon_name
  when 'cart' then 'groceries'
  when 'restaurant' then 'dining'
  when 'car' then 'transport'
  when 'movie' then 'leisure'
  when 'subscriptions' then 'subscriptions'
  when 'savings' then 'savings'
end
where is_default
  and slug is null
  and icon_name in (
    'cart',
    'restaurant',
    'car',
    'movie',
    'subscriptions',
    'savings'
  );

create unique index if not exists idx_categories_household_slug
  on public.categories (household_id, slug)
  where slug is not null;

insert into public.categories (
  household_id,
  name,
  icon_name,
  is_default,
  slug
)
select
  households.id,
  default_categories.name,
  default_categories.icon_name,
  true,
  default_categories.slug
from public.households
cross join (
  values
    ('essentials', 'Gastos esenciales', 'essentials'),
    ('education', 'Estudios', 'education'),
    ('emergency_fund', 'Reserva de emergencia', 'emergency'),
    ('health', 'Salud', 'health')
) as default_categories(slug, name, icon_name)
where not exists (
  select 1
  from public.categories
  where categories.household_id = households.id
    and categories.slug = default_categories.slug
);
