-- Active la suppression totale d'un utilisateur depuis l'application (super-administrateur uniquement).
-- À exécuter une fois dans Supabase > SQL Editor > Run.
create or replace function public.admin_delete_user(p_email text)
returns text
language plpgsql security definer set search_path = '' as $$
declare
  e  text := lower(trim(p_email));
  me text := lower(coalesce(auth.jwt() ->> 'email',''));
  n  int;
begin
  if not private.is_superadmin() then raise exception 'Réservé au super-administrateur'; end if;
  if e = me then raise exception 'Vous ne pouvez pas supprimer votre propre compte'; end if;
  delete from auth.users where lower(email) = e;
  get diagnostics n = row_count;
  delete from public.members where email = e;
  return case when n > 0 then 'supprime' else 'acces_supprime' end;
end;
$$;
revoke execute on function public.admin_delete_user(text) from public, anon;
grant execute on function public.admin_delete_user(text) to authenticated;
