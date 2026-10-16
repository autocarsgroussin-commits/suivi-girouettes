-- Suivi des girouettes : base de données Supabase
-- À coller dans Supabase > SQL Editor, puis « Run ». Le script peut être relancé sans risque.

-- 1. Table : une ligne par car, avec ses pannes, tâches et demandes SAV.
create table if not exists public.cars (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  plate       text not null,
  parc        text not null default '',
  ligne       text not null default '',
  type        text not null default '',
  notes       text not null default '',
  pannes      jsonb not null default '[]'::jsonb,
  taches      jsonb not null default '[]'::jsonb,
  sav         jsonb not null default '[]'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint cars_plate_unique unique (user_id, plate)
);

-- 2. Sécurité : chaque utilisateur ne voit et ne modifie que ses propres cars.
alter table public.cars enable row level security;

drop policy if exists "cars_select_own" on public.cars;
drop policy if exists "cars_insert_own" on public.cars;
drop policy if exists "cars_update_own" on public.cars;
drop policy if exists "cars_delete_own" on public.cars;

create policy "cars_select_own" on public.cars
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "cars_insert_own" on public.cars
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "cars_update_own" on public.cars
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "cars_delete_own" on public.cars
  for delete to authenticated using ((select auth.uid()) = user_id);

-- 3. Date de dernière modification tenue à jour automatiquement.
create or replace function public.cars_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists cars_updated_at on public.cars;
create trigger cars_updated_at before update on public.cars
  for each row execute function public.cars_set_updated_at();

-- 4. Temps réel : les modifications faites sur un appareil apparaissent sur les autres.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'cars'
  ) then
    alter publication supabase_realtime add table public.cars;
  end if;
end;
$$;

-- ============================================================
-- 5. Parc partagé en équipe (appliqué le 29/09/2026)
--    Tous les membres actifs voient et modifient les mêmes cars.
-- ============================================================
create table if not exists public.members (
  email      text primary key check (email = lower(email)),
  nom        text not null default '',
  role       text not null default 'membre' check (role in ('admin','membre')),
  actif      boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.members enable row level security;

create schema if not exists private;
grant usage on schema private to authenticated;
create or replace function private.is_member() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.members m
                 where m.email = lower(coalesce(auth.jwt() ->> 'email','')) and m.actif);
$$;
create or replace function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.members m
                 where m.email = lower(coalesce(auth.jwt() ->> 'email','')) and m.actif and m.role = 'admin');
$$;
revoke execute on function private.is_member() from public, anon;
revoke execute on function private.is_admin() from public, anon;
grant execute on function private.is_member() to authenticated;
grant execute on function private.is_admin() to authenticated;

drop policy if exists "members_select" on public.members;
drop policy if exists "members_insert" on public.members;
drop policy if exists "members_update" on public.members;
drop policy if exists "members_delete" on public.members;
create policy "members_select" on public.members for select to authenticated using (private.is_member());
create policy "members_insert" on public.members for insert to authenticated with check (private.is_admin());
create policy "members_update" on public.members for update to authenticated using (private.is_admin()) with check (private.is_admin());
create policy "members_delete" on public.members for delete to authenticated using (private.is_admin());

alter table public.cars drop constraint if exists cars_plate_unique;
alter table public.cars drop constraint if exists cars_plate_key;
alter table public.cars add constraint cars_plate_key unique (plate);
alter table public.cars drop constraint if exists cars_user_id_fkey;
alter table public.cars alter column user_id drop not null;
alter table public.cars add constraint cars_user_id_fkey foreign key (user_id) references auth.users (id) on delete set null;
alter table public.cars add column if not exists created_by text default (auth.jwt() ->> 'email');
alter table public.cars add column if not exists updated_by text default (auth.jwt() ->> 'email');

create or replace function public.cars_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  new.updated_by = coalesce(auth.jwt() ->> 'email', new.updated_by);
  new.user_id = old.user_id;
  new.created_by = old.created_by;
  return new;
end;
$$;

drop policy if exists "cars_select_own" on public.cars;
drop policy if exists "cars_insert_own" on public.cars;
drop policy if exists "cars_update_own" on public.cars;
drop policy if exists "cars_delete_own" on public.cars;
drop policy if exists "cars_select_team" on public.cars;
drop policy if exists "cars_insert_team" on public.cars;
drop policy if exists "cars_update_team" on public.cars;
drop policy if exists "cars_delete_team" on public.cars;
create policy "cars_select_team" on public.cars for select to authenticated using (private.is_member());
create policy "cars_insert_team" on public.cars for insert to authenticated with check (private.is_member());
create policy "cars_update_team" on public.cars for update to authenticated using (private.is_member()) with check (private.is_member());
create policy "cars_delete_team" on public.cars for delete to authenticated using (private.is_member());
-- Premier administrateur : insert into public.members (email, nom, role) values ('votre@adresse', 'Prénom', 'admin');

-- ============================================================
-- 6. E-mail aux administrateurs à chaque nouvelle panne (Brevo)
--    Clé stockée dans Supabase Vault :
--    select vault.create_secret('VOTRE-CLE-BREVO', 'brevo_api_key');
--    (optionnel) select vault.create_secret('expediteur@domaine.fr', 'brevo_sender');
--    Le code complet de la fonction private.notify_new_panne() et du
--    déclencheur cars_notify_new_panne a été appliqué directement sur le projet
--    (migration « notification_email_nouvelle_panne »).
-- ============================================================

-- ============================================================
-- 7. Inscription libre réservée au domaine @autocars-groussin.com
--    - Déclencheur on_auth_user_created_members : tout nouveau compte du domaine
--      est ajouté à public.members (rôle membre).
--    - Fonction public.hook_before_user_created(jsonb) : à activer dans
--      Authentication > Hooks > Before User Created (refuse les autres domaines).
--    Migration appliquée : « inscription_domaine_autocars_groussin ».
-- ============================================================

-- ============================================================
-- 8. Profil conducteur et signalements (appliqué le 12/10/2026)
--    Migration : « profil_conducteur_signalements »
--    - members.role accepte 'conducteur' ; colonne members.car_habituel
--    - private.is_staff() (admin + membre) / private.is_driver()
--    - cars : lecture/écriture réservées à l'équipe bureau (is_staff)
--    - fleet : copie plaque/parc/ligne lisible par tous les membres (liste des cars pour les conducteurs)
--    - reports : signalements ; un conducteur ne voit que les siens
--    - private.report_to_panne() : chaque signalement ajoute une panne au car (créé si inconnu),
--      ce qui déclenche l'e-mail aux administrateurs
--    - private.sync_report_status() : panne résolue -> signalement « Réparé » côté conducteur
--    - hook_before_user_created : accepte le domaine OU une adresse déjà ajoutée dans l'Équipe
-- ============================================================

-- 9. Annulation par le conducteur : public.cancel_report(uuid) (migration « annulation_signalement_conducteur »)
--    Statut « annule », panne retirée de la fiche, e-mail « Signalement annulé » aux administrateurs.

-- 10. Heure des signalements dans la panne (« heure ») et rattachement par n° du car (migration « panne_heure_signalement »)
