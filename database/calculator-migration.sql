-- 1628 KvK planner v12: additive calculator profile extension.
-- Neon additive migration; tested on a production branch clone.
-- No profiles, requests, appointments, admin accounts or reset functions are removed.
begin;
alter table public.player_profiles
 add column if not exists calculator_profile jsonb not null default '{}'::jsonb,
 add column if not exists calculator_revision bigint not null default 0,
 add column if not exists calculator_updated_at timestamptz;

create or replace function public.save_calculator_profile(
 p_device_id uuid,
 p_profile_id uuid,
 p_expected_revision bigint,
 p_expected_updated_at timestamptz,
 p_patch jsonb
) returns public.player_profiles
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
 existing public.player_profiles;
 result public.player_profiles;
 next_profile jsonb;
 section_name text;
 field_name text;
 field_value jsonb;
 numeric_value numeric;
 maximum_value numeric;
begin
 if p_device_id is null then raise exception 'Player identity required'; end if;
 perform set_config('kvk.device_id',p_device_id::text,true);
 if public.kvk_player_actor() is null then raise exception 'Player identity required'; end if;
 select * into existing from public.player_profiles where id=p_profile_id for update;
 if not found or existing.user_id is distinct from public.kvk_player_actor() then
  raise exception 'This player profile is not linked to your session.';
 end if;
 if existing.resources_locked and p_patch ? 'booking' then raise exception 'Resources are currently locked'; end if;
 if existing.resource_snapshot_required then raise exception 'Update your KvK booking profile before using the calculator.'; end if;
 if existing.calculator_revision is distinct from p_expected_revision
    or existing.updated_at is distinct from p_expected_updated_at then
  raise exception 'Your profile changed in another tab or device. Refresh this page and check the latest values before saving.';
 end if;
 if jsonb_typeof(p_patch) is distinct from 'object' or octet_length(p_patch::text)>20000 then raise exception 'Invalid calculator profile.'; end if;
 if exists(select 1 from jsonb_object_keys(p_patch) k where k not in ('resources','booking','stats','city','plan','preferences','resources_checked_at')) then raise exception 'Unknown calculator profile field.'; end if;
 next_profile=existing.calculator_profile;
 foreach section_name in array array['resources','booking','stats','city'] loop
  if p_patch ? section_name then
   if jsonb_typeof(p_patch->section_name) is distinct from 'object' then raise exception 'Invalid % section.',section_name; end if;
   for field_name,field_value in select key,value from jsonb_each(p_patch->section_name) loop
    if jsonb_typeof(field_value) is distinct from 'number' then raise exception 'Invalid number for %.',field_name; end if;
    numeric_value=(field_value#>>'{}')::numeric;
    maximum_value=1000000000000000;
    if section_name='resources' then
     if field_name not in ('bread','wood','stone','iron','tempered_truegold') then raise exception 'Unknown resource.'; end if;
     if field_name='tempered_truegold' and numeric_value<>trunc(numeric_value) then raise exception 'Tempered Truegold must be a whole number.'; end if;
    elsif section_name='booking' then
     if field_name not in ('truegold','construction_speedups','general_speedups') then raise exception 'Unknown booking resource.'; end if;
     maximum_value=case when field_name='truegold' then 2147483647 else 99999999 end;
     if field_name='truegold' and numeric_value<>trunc(numeric_value) then raise exception 'Truegold must be a whole number.'; end if;
    elsif section_name='stats' then
     if field_name not in ('construction_speed','saul_level','wolf_rank','pan_level') then raise exception 'Unknown construction stat.'; end if;
     maximum_value=case when field_name='construction_speed' then 10000 else 5 end;
     if field_name<>'construction_speed' and numeric_value<>trunc(numeric_value) then raise exception 'Skill levels must be whole numbers.'; end if;
    elsif section_name='city' then
     if field_name not in ('town_center','embassy','academy','barracks','stable','range','command_center','infirmary','war_academy') then raise exception 'Unknown building.'; end if;
     maximum_value=case when field_name='academy' then 30 else 70 end;
     if numeric_value<>trunc(numeric_value) or (field_name='war_academy' and numeric_value>0 and numeric_value<35) then raise exception 'Invalid building level.'; end if;
    end if;
    if numeric_value<0 or numeric_value>maximum_value then raise exception 'Value out of range for %.',field_name; end if;
   end loop;
   if section_name<>'booking' then
    -- City and stats are complete sections; resources can be updated individually.
    if section_name='resources' then next_profile=jsonb_set(next_profile,array[section_name],coalesce(next_profile->section_name,'{}'::jsonb)||(p_patch->section_name),true);
    else next_profile=jsonb_set(next_profile,array[section_name],p_patch->section_name,true); end if;
   end if;
  end if;
 end loop;
 if p_patch ? 'plan' then
  if jsonb_typeof(p_patch->'plan') is distinct from 'array' or jsonb_array_length(p_patch->'plan')>9 then raise exception 'Invalid upgrade plan.'; end if;
  next_profile=jsonb_set(next_profile,'{plan}',p_patch->'plan',true);
 end if;
 if p_patch ? 'preferences' then
  if jsonb_typeof(p_patch->'preferences') is distinct from 'object' then raise exception 'Invalid preferences.'; end if;
  next_profile=jsonb_set(next_profile,'{preferences}',p_patch->'preferences',true);
 end if;
 if p_patch ? 'resources_checked_at' then
  -- Use server time, not a client-supplied timestamp.
  next_profile=jsonb_set(next_profile,'{resources_checked_at}',to_jsonb(now()),true);
 end if;
 update public.player_profiles set
  calculator_profile=next_profile,
  calculator_revision=calculator_revision+1,
  calculator_updated_at=now(),
  updated_at=now(),
  truegold=coalesce((p_patch->'booking'->>'truegold')::integer,existing.truegold),
  construction_speedups=coalesce((p_patch->'booking'->>'construction_speedups')::numeric,existing.construction_speedups),
  general_speedups=coalesce((p_patch->'booking'->>'general_speedups')::numeric,existing.general_speedups)
 where id=existing.id returning * into result;
 return result;
end;
$$;
revoke all on function public.save_calculator_profile(uuid,uuid,bigint,timestamptz,jsonb) from public;
grant execute on function public.save_calculator_profile(uuid,uuid,bigint,timestamptz,jsonb) to anonymous,authenticated;
commit;
