-- Fresh Neon planner schema. Apply to an empty database in a transaction.

CREATE TABLE public."admin_activity_log" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "actor_id" uuid,
  "actor_name" text,
  "action_type" text NOT NULL,
  "summary" text,
  "reversible" boolean DEFAULT false NOT NULL,
  "undone" boolean DEFAULT false NOT NULL,
  "payload" jsonb,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."admin_users" (
  "id" uuid NOT NULL,
  "admin_role" text NOT NULL,
  "display_name" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."appointments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "request_id" uuid NOT NULL,
  "slot_key" text NOT NULL,
  "event_day" text NOT NULL,
  "minister_role" text NOT NULL,
  "profile_id" uuid NOT NULL,
  "awarded_by" uuid,
  "player_name" text,
  "alliance" text,
  "awarded_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE public."day_settings" (
  "event_day" text NOT NULL,
  "is_finalised" boolean DEFAULT false NOT NULL,
  "finalised_at" timestamp with time zone,
  "finalised_by" uuid
);

CREATE TABLE public."kvk_archive_appointments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "cycle_id" uuid NOT NULL,
  "event_day" text NOT NULL,
  "slot_key" text NOT NULL,
  "minister_role" text,
  "player_id" text,
  "player_name" text,
  "alliance" text
);

CREATE TABLE public."kvk_archive_cycles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "cycle_start" date NOT NULL,
  "archived_at" timestamp with time zone DEFAULT now() NOT NULL,
  "archived_by" uuid
);

CREATE TABLE public."player_profiles" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid,
  "player_id" text NOT NULL,
  "player_name" text NOT NULL,
  "alliance" text NOT NULL,
  "truegold" integer DEFAULT 0 NOT NULL,
  "general_speedups" numeric DEFAULT 0 NOT NULL,
  "research_speedups" numeric DEFAULT 0 NOT NULL,
  "training_speedups" numeric DEFAULT 0 NOT NULL,
  "construction_speedups" numeric DEFAULT 0 NOT NULL,
  "resources_locked" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "admin_note" text,
  "resource_updated_at" timestamp with time zone,
  "resource_snapshot_required" boolean DEFAULT false NOT NULL
);

CREATE TABLE public."rejection_log" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "request_id" uuid,
  "profile_id" uuid,
  "player_id" text NOT NULL,
  "player_name" text NOT NULL,
  "alliance" text,
  "event_day" text NOT NULL,
  "slot_key" text NOT NULL,
  "minister_role" text,
  "reason" text,
  "rejected_by" uuid,
  "rejected_at" timestamp with time zone DEFAULT now() NOT NULL,
  "contacted" boolean DEFAULT false NOT NULL,
  "contacted_at" timestamp with time zone,
  "contacted_by" uuid
);

CREATE TABLE public."slot_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "profile_id" uuid NOT NULL,
  "event_day" text NOT NULL,
  "minister_role" text NOT NULL,
  "slot_key" text NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public."admin_activity_log" ADD CONSTRAINT "admin_activity_log_pkey" PRIMARY KEY (id);

ALTER TABLE public."admin_users" ADD CONSTRAINT "admin_users_admin_role_check" CHECK (admin_role = ANY (ARRAY['owner'::text, 'king'::text, 'minister'::text]));

ALTER TABLE public."admin_users" ADD CONSTRAINT "admin_users_pkey" PRIMARY KEY (id);

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_alliance_check" CHECK (alliance IS NULL OR (alliance = ANY (ARRAY['CRN'::text, 'WDG'::text, 'ERA'::text, 'WAR'::text])));

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_event_day_check" CHECK (event_day = ANY (ARRAY['monday'::text, 'tuesday'::text, 'thursday'::text]));

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_minister_role_check" CHECK (minister_role = ANY (ARRAY['Chief Minister'::text, 'Noble Advisor'::text]));

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_pkey" PRIMARY KEY (id);

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_request_id_key" UNIQUE (request_id);

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_slot_key_key" UNIQUE (slot_key);

ALTER TABLE public."day_settings" ADD CONSTRAINT "day_settings_event_day_check" CHECK (event_day = ANY (ARRAY['monday'::text, 'tuesday'::text, 'thursday'::text]));

ALTER TABLE public."day_settings" ADD CONSTRAINT "day_settings_pkey" PRIMARY KEY (event_day);

ALTER TABLE public."kvk_archive_appointments" ADD CONSTRAINT "kvk_archive_appointments_pkey" PRIMARY KEY (id);

ALTER TABLE public."kvk_archive_cycles" ADD CONSTRAINT "kvk_archive_cycles_cycle_start_key" UNIQUE (cycle_start);

ALTER TABLE public."kvk_archive_cycles" ADD CONSTRAINT "kvk_archive_cycles_pkey" PRIMARY KEY (id);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_alliance_check" CHECK (alliance = ANY (ARRAY['CRN'::text, 'WDG'::text, 'ERA'::text, 'WAR'::text]));

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_construction_speedups_check" CHECK (construction_speedups >= 0::numeric);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_general_speedups_check" CHECK (general_speedups >= 0::numeric);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_pkey" PRIMARY KEY (id);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_player_id_key" UNIQUE (player_id);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_research_speedups_check" CHECK (research_speedups >= 0::numeric);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_training_speedups_check" CHECK (training_speedups >= 0::numeric);

ALTER TABLE public."player_profiles" ADD CONSTRAINT "player_profiles_truegold_check" CHECK (truegold >= 0);

ALTER TABLE public."rejection_log" ADD CONSTRAINT "rejection_log_pkey" PRIMARY KEY (id);

ALTER TABLE public."slot_requests" ADD CONSTRAINT "slot_requests_event_day_check" CHECK (event_day = ANY (ARRAY['monday'::text, 'tuesday'::text, 'thursday'::text]));

ALTER TABLE public."slot_requests" ADD CONSTRAINT "slot_requests_minister_role_check" CHECK (minister_role = ANY (ARRAY['Chief Minister'::text, 'Noble Advisor'::text]));

ALTER TABLE public."slot_requests" ADD CONSTRAINT "slot_requests_pkey" PRIMARY KEY (id);

ALTER TABLE public."slot_requests" ADD CONSTRAINT "slot_requests_profile_id_event_day_slot_key_key" UNIQUE (profile_id, event_day, slot_key);

ALTER TABLE public."slot_requests" ADD CONSTRAINT "slot_requests_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'rejected'::text, 'withdrawn'::text]));

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES player_profiles(id) ON DELETE CASCADE;

ALTER TABLE public."appointments" ADD CONSTRAINT "appointments_request_id_fkey" FOREIGN KEY (request_id) REFERENCES slot_requests(id) ON DELETE CASCADE;

ALTER TABLE public."kvk_archive_appointments" ADD CONSTRAINT "kvk_archive_appointments_cycle_id_fkey" FOREIGN KEY (cycle_id) REFERENCES kvk_archive_cycles(id) ON DELETE CASCADE;

ALTER TABLE public."slot_requests" ADD CONSTRAINT "slot_requests_profile_id_fkey" FOREIGN KEY (profile_id) REFERENCES player_profiles(id) ON DELETE CASCADE;

CREATE FUNCTION public.kvk_player_actor() RETURNS uuid LANGUAGE sql STABLE SET search_path = public AS $$
 SELECT CASE WHEN auth.uid() IS NOT NULL THEN auth.uid()
 ELSE nullif(current_setting('kvk.device_id', true),'')::uuid END;
$$;

CREATE OR REPLACE FUNCTION public.admin_manual_assign(p_event_day text, p_slot_key text, p_player_id text, p_player_name text, p_alliance text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_profile_id uuid;
  v_request_id uuid;
  v_role text;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_event_day not in ('monday','tuesday','thursday') then raise exception 'Invalid event day'; end if;
  if p_alliance not in ('CRN','WDG','ERA','WAR') then raise exception 'Invalid alliance'; end if;
  if trim(coalesce(p_player_id,''))='' or trim(coalesce(p_player_name,''))='' then raise exception 'Player ID and name are required'; end if;

  if exists(select 1 from public.day_settings where event_day=p_event_day and is_finalised=true) then
    raise exception 'This day is finalised';
  end if;

  if exists(select 1 from public.appointments where slot_key=p_slot_key) then
    raise exception 'This slot already has a confirmed appointment';
  end if;

  v_role:=case when p_event_day in ('monday','tuesday') then 'Chief Minister' else 'Noble Advisor' end;

  select id into v_profile_id from public.player_profiles where player_id=trim(p_player_id);

  if v_profile_id is null then
    insert into public.player_profiles(user_id,player_id,player_name,alliance,resource_snapshot_required)
    values(null,trim(p_player_id),trim(p_player_name),p_alliance,true)
    returning id into v_profile_id;
  else
    update public.player_profiles
    set player_name=trim(p_player_name),alliance=p_alliance,updated_at=now()
    where id=v_profile_id;
  end if;

  if exists(
    select 1 from public.slot_requests
    where profile_id=v_profile_id and event_day=p_event_day and status='confirmed'
  ) then
    raise exception 'This player already has another confirmed slot for this day';
  end if;

  select id into v_request_id
  from public.slot_requests
  where profile_id=v_profile_id and event_day=p_event_day and slot_key=p_slot_key;

  if v_request_id is null then
    insert into public.slot_requests(profile_id,event_day,minister_role,slot_key,status)
    values(v_profile_id,p_event_day,v_role,p_slot_key,'confirmed')
    returning id into v_request_id;
  else
    update public.slot_requests
    set minister_role=v_role,status='confirmed',updated_at=now()
    where id=v_request_id;
  end if;

  insert into public.appointments(request_id,slot_key,event_day,minister_role,profile_id,awarded_by,player_name,alliance)
  values(v_request_id,p_slot_key,p_event_day,v_role,v_profile_id,auth.uid(),trim(p_player_name),p_alliance);

  update public.slot_requests
  set status='withdrawn'
  where profile_id=v_profile_id and event_day=p_event_day and id<>v_request_id and status='pending';

  perform public.log_admin_action(
    'manual_booking',
    trim(p_player_name)||' manually booked into '||p_slot_key,
    true,
    jsonb_build_object('request_id',v_request_id,'slot_key',p_slot_key,'event_day',p_event_day)
  );

  return v_request_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.archive_current_kvk()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_role text;
  v_cycle_start date:=public.kvk_cycle_start_utc();
  v_cycle_id uuid;
begin
  select admin_role into v_role from public.admin_users where id=auth.uid();
  if v_role is distinct from 'owner' then raise exception 'Owner access required'; end if;

  insert into public.kvk_archive_cycles(cycle_start,archived_by)
  values(v_cycle_start,auth.uid())
  on conflict(cycle_start) do update set archived_at=now(),archived_by=auth.uid()
  returning id into v_cycle_id;

  delete from public.kvk_archive_appointments where cycle_id=v_cycle_id and id is not null;

  insert into public.kvk_archive_appointments(cycle_id,event_day,slot_key,minister_role,player_id,player_name,alliance)
  select v_cycle_id,a.event_day,a.slot_key,a.minister_role,p.player_id,a.player_name,a.alliance
  from public.appointments a
  join public.player_profiles p on p.id=a.profile_id;

  perform public.log_admin_action('kvk_archived','Archived KvK starting '||v_cycle_start,false,null);
  return v_cycle_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.award_slot(p_request_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_req public.slot_requests;
  v_profile public.player_profiles;
  v_existing uuid;
  v_activity uuid;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;

  select * into v_req from public.slot_requests where id=p_request_id;
  if not found then raise exception 'Request not found'; end if;

  if exists(select 1 from public.day_settings where event_day=v_req.event_day and is_finalised=true) then
    raise exception 'This day is finalised';
  end if;

  if exists(
    select 1 from public.slot_requests
    where profile_id=v_req.profile_id and event_day=v_req.event_day and status='confirmed' and id<>v_req.id
  ) then
    raise exception 'This player already has another confirmed slot for this day';
  end if;

  if exists(select 1 from public.appointments where slot_key=v_req.slot_key) then
    raise exception 'This slot already has a confirmed appointment';
  end if;

  select * into v_profile from public.player_profiles where id=v_req.profile_id;

  update public.slot_requests set status='confirmed' where id=v_req.id;

  insert into public.appointments(request_id,slot_key,event_day,minister_role,profile_id,awarded_by,player_name,alliance)
  values(v_req.id,v_req.slot_key,v_req.event_day,v_req.minister_role,v_req.profile_id,auth.uid(),v_profile.player_name,v_profile.alliance);

  update public.slot_requests
  set status='withdrawn'
  where profile_id=v_req.profile_id and event_day=v_req.event_day and id<>v_req.id and status='pending';

  perform public.log_admin_action(
    'slot_awarded',
    v_profile.player_name||' awarded '||v_req.slot_key,
    true,
    jsonb_build_object('request_id',v_req.id,'slot_key',v_req.slot_key,'event_day',v_req.event_day)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.claim_player_profile(p_player_id text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_profile_id uuid;
begin
  if public.kvk_player_actor() is null then
    raise exception 'Authentication required';
  end if;

  select id
  into v_profile_id
  from public.player_profiles
  where player_id = trim(p_player_id);

  if v_profile_id is null then
    return null;
  end if;

  update public.player_profiles
  set user_id = null,
      updated_at = now()
  where user_id = public.kvk_player_actor()
    and id <> v_profile_id;

  update public.player_profiles
  set user_id = public.kvk_player_actor(),
      updated_at = now()
  where id = v_profile_id;

  return v_profile_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_public_slot_activity()
 RETURNS TABLE(slot_key text, event_day text, player_name text, alliance text, status text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    r.slot_key,
    r.event_day,
    p.player_name,
    p.alliance,
    r.status
  from public.slot_requests r
  join public.player_profiles p on p.id = r.profile_id
  where r.status in ('pending','confirmed');
$function$;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.admin_users
    where id = auth.uid()
  );
$function$;

CREATE OR REPLACE FUNCTION public.kvk_cycle_start_utc()
 RETURNS date
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  with params as (
    select
      date '2026-08-10' as anchor_date,
      (now() at time zone 'utc')::date as today
  ),
  calc as (
    select
      anchor_date,
      today,
      greatest(0, floor(((today - anchor_date)::numeric) / 28))::int as cycle_number
    from params
  ),
  candidate as (
    select
      anchor_date + (cycle_number * 28) as cycle_start,
      today
    from calc
  )
  select
    case
      -- After the Thursday of a KvK week, prepare the next 28-day cycle.
      when today > cycle_start + 3 then cycle_start + 28
      else cycle_start
    end
  from candidate;
$function$;

CREATE OR REPLACE FUNCTION public.kvk_deadline_utc(p_event_day text)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare
  v_start date := public.kvk_cycle_start_utc();
  v_event_offset integer;
begin
  v_event_offset := case p_event_day
    when 'monday' then 0
    when 'tuesday' then 1
    when 'thursday' then 3
    else null
  end;

  if v_event_offset is null then
    raise exception 'Invalid event day';
  end if;

  return (
    (v_start + (v_event_offset - 1))::timestamp
    + interval '20 hours'
  ) at time zone 'UTC';
end;
$function$;

CREATE OR REPLACE FUNCTION public.log_admin_action(p_action_type text, p_summary text, p_reversible boolean DEFAULT false, p_payload jsonb DEFAULT NULL::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_name text;
  v_id uuid;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  select coalesce(display_name,admin_role,'Admin') into v_name from public.admin_users where id=auth.uid();

  insert into public.admin_activity_log(actor_id,actor_name,action_type,summary,reversible,payload)
  values(auth.uid(),v_name,p_action_type,p_summary,p_reversible,p_payload)
  returning id into v_id;

  return v_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.mark_rejection_contacted(p_log_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  update public.rejection_log
  set contacted = true,
      contacted_at = now(),
      contacted_by = auth.uid()
  where id = p_log_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.reject_slot_request(p_request_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_req public.slot_requests;
  v_profile public.player_profiles;
  v_log_id uuid;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;

  select * into v_req from public.slot_requests where id=p_request_id;
  if not found then raise exception 'Request not found'; end if;

  if exists(select 1 from public.day_settings where event_day=v_req.event_day and is_finalised=true) then
    raise exception 'This day is finalised';
  end if;

  select * into v_profile from public.player_profiles where id=v_req.profile_id;

  insert into public.rejection_log(
    request_id,profile_id,player_id,player_name,alliance,event_day,slot_key,minister_role,reason,rejected_by
  )
  values(
    v_req.id,v_profile.id,v_profile.player_id,v_profile.player_name,v_profile.alliance,
    v_req.event_day,v_req.slot_key,v_req.minister_role,nullif(trim(coalesce(p_reason,'')),''),auth.uid()
  )
  returning id into v_log_id;

  update public.slot_requests set status='rejected' where id=p_request_id;

  perform public.log_admin_action(
    'request_rejected',
    v_profile.player_name||' rejected for '||v_req.slot_key,
    true,
    jsonb_build_object('request_id',v_req.id,'rejection_log_id',v_log_id)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.remove_appointment_when_request_unconfirmed()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'DELETE' then
    delete from public.appointments
    where request_id = old.id;
    return old;
  end if;

  if old.status = 'confirmed'
     and new.status is distinct from 'confirmed' then
    delete from public.appointments
    where request_id = old.id;
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.reset_kvk_cycle()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_role text;
begin
  select admin_role into v_role from public.admin_users where id=auth.uid();
  if v_role is distinct from 'owner' then raise exception 'Owner access required'; end if;

  delete from public.appointments where id is not null;
  delete from public.slot_requests where id is not null;
  delete from public.rejection_log where id is not null;

  update public.player_profiles
  set truegold=0,
      general_speedups=0,
      research_speedups=0,
      training_speedups=0,
      construction_speedups=0,
      resources_locked=false,
      resource_snapshot_required=true,
      updated_at=now()
  where id is not null;

  update public.day_settings
  set is_finalised=false,finalised_at=null,finalised_by=null
  where event_day in ('monday','tuesday','thursday');

  perform public.log_admin_action('kvk_reset','KvK planner reset',false,null);
end;
$function$;

CREATE OR REPLACE FUNCTION public.save_player_profile(p_profile_id uuid, p_player_name text, p_alliance text, p_truegold numeric, p_general_speedups numeric, p_research_speedups numeric, p_training_speedups numeric, p_construction_speedups numeric)
 RETURNS player_profiles
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_profile public.player_profiles;
begin
  if public.kvk_player_actor() is null then raise exception 'Authentication required'; end if;
  select *
  into v_profile
  from public.player_profiles
  where id = p_profile_id;

  if v_profile.id is null then
    raise exception 'Profile not found';
  end if;

  if v_profile.user_id is distinct from public.kvk_player_actor() then
    raise exception 'You can only update your own profile';
  end if;

  if coalesce(v_profile.resources_locked, false) then
    raise exception 'Resources are currently locked';
  end if;

  update public.player_profiles
  set player_name = trim(p_player_name),
      alliance = p_alliance,
      truegold = greatest(coalesce(p_truegold,0),0),
      general_speedups = greatest(coalesce(p_general_speedups,0),0),
      research_speedups = greatest(coalesce(p_research_speedups,0),0),
      training_speedups = greatest(coalesce(p_training_speedups,0),0),
      construction_speedups = greatest(coalesce(p_construction_speedups,0),0),
      resource_snapshot_required = false,
      resource_updated_at = now(),
      updated_at = now()
  where id = p_profile_id
  returning * into v_profile;

  return v_profile;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_admin_note(p_profile_id uuid, p_note text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_name text;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  update public.player_profiles set admin_note=nullif(trim(coalesce(p_note,'')),'') where id=p_profile_id;
  select player_name into v_name from public.player_profiles where id=p_profile_id;
  perform public.log_admin_action('note_updated','Updated admin note for '||coalesce(v_name,'player'),false,null);
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_day_finalised(p_event_day text, p_finalised boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_role text;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_event_day not in ('monday','tuesday','thursday') then raise exception 'Invalid event day'; end if;

  select admin_role into v_role from public.admin_users where id=auth.uid();

  if p_finalised=false and v_role<>'owner' then
    raise exception 'Only the owner can reopen a finalised day';
  end if;

  update public.day_settings
  set is_finalised=p_finalised,
      finalised_at=case when p_finalised then now() else null end,
      finalised_by=case when p_finalised then auth.uid() else null end
  where event_day=p_event_day;

  perform public.log_admin_action(
    case when p_finalised then 'day_finalised' else 'day_reopened' end,
    initcap(p_event_day)||case when p_finalised then ' finalised' else ' reopened' end,
    false,null
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.submit_slot_requests(p_event_day text, p_slot_keys text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_profile public.player_profiles;
  v_role text;
  v_key text;
begin
  if public.kvk_player_actor() is null then raise exception 'Authentication required'; end if;
  if p_event_day not in ('monday','tuesday','thursday') then raise exception 'Invalid event day'; end if;

  if exists(select 1 from public.day_settings where event_day=p_event_day and is_finalised=true) then
    raise exception 'This day is finalised';
  end if;

  if now() >= public.kvk_deadline_utc(p_event_day) then
    raise exception 'The application deadline for this day has passed';
  end if;

  if coalesce(array_length(p_slot_keys,1),0)<3 or coalesce(array_length(p_slot_keys,1),0)>5 then
    raise exception 'Select between 3 and 5 slots';
  end if;

  if (select count(distinct x) from unnest(p_slot_keys) x) <> array_length(p_slot_keys,1) then
    raise exception 'Duplicate slot choices are not allowed';
  end if;

  select * into v_profile from public.player_profiles where user_id=public.kvk_player_actor();
  if not found then raise exception 'Complete your KvK profile first'; end if;

  v_role:=case when p_event_day in ('monday','tuesday') then 'Chief Minister' else 'Noble Advisor' end;

  if exists(select 1 from public.slot_requests where profile_id=v_profile.id and event_day=p_event_day and status='confirmed') then
    raise exception 'You already have a confirmed appointment for this day';
  end if;

  update public.slot_requests
  set status='withdrawn'
  where profile_id=v_profile.id and event_day=p_event_day and status='pending';

  foreach v_key in array p_slot_keys loop
    if exists(select 1 from public.appointments where slot_key=v_key) then
      raise exception 'One of those slots has already been confirmed';
    end if;

    insert into public.slot_requests(profile_id,event_day,minister_role,slot_key,status)
    values(v_profile.id,p_event_day,v_role,v_key,'pending')
    on conflict(profile_id,event_day,slot_key)
    do update set status='pending',minister_role=excluded.minister_role,updated_at=now();
  end loop;
end;
$function$;

CREATE OR REPLACE FUNCTION public.undo_last_admin_action()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_action public.admin_activity_log;
  v_request_id uuid;
  v_log_id uuid;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;

  select * into v_action
  from public.admin_activity_log
  where reversible=true and undone=false
  order by created_at desc
  limit 1
  for update;

  if not found then return false; end if;

  v_request_id := nullif(v_action.payload->>'request_id','')::uuid;
  v_log_id := nullif(v_action.payload->>'rejection_log_id','')::uuid;

  if v_action.action_type in ('slot_awarded','manual_booking') then
    delete from public.appointments where request_id=v_request_id and id is not null;
    update public.slot_requests set status='pending' where id=v_request_id;
  elsif v_action.action_type='request_rejected' then
    update public.slot_requests set status='pending' where id=v_request_id;
    delete from public.rejection_log where id=v_log_id and id is not null;
  else
    return false;
  end if;

  update public.admin_activity_log set undone=true where id=v_action.id;
  perform public.log_admin_action('undo','Undid '||v_action.action_type,false,jsonb_build_object('undone_action_id',v_action.id));
  return true;
end;
$function$;

CREATE TRIGGER player_profiles_set_updated_at BEFORE UPDATE ON player_profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER slot_requests_set_updated_at BEFORE UPDATE ON slot_requests FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_remove_appointment_when_request_unconfirmed AFTER DELETE OR UPDATE OF status ON slot_requests FOR EACH ROW EXECUTE FUNCTION remove_appointment_when_request_unconfirmed();

ALTER TABLE public."admin_activity_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."admin_users" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."appointments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."day_settings" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."kvk_archive_appointments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."kvk_archive_cycles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."player_profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."rejection_log" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."slot_requests" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins read activity" ON public."admin_activity_log" AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY "Admins can read admin users" ON public."admin_users" AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY "Admins create appointments" ON public."appointments" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (is_admin());

CREATE POLICY "Admins delete appointments" ON public."appointments" AS PERMISSIVE FOR DELETE TO authenticated USING (is_admin());

CREATE POLICY "Admins update appointments" ON public."appointments" AS PERMISSIVE FOR UPDATE TO authenticated USING (is_admin());

CREATE POLICY "Confirmed appointments are public" ON public."appointments" AS PERMISSIVE FOR SELECT TO anonymous, authenticated USING (true);

CREATE POLICY "Day settings public read" ON public."day_settings" AS PERMISSIVE FOR SELECT TO anonymous, authenticated USING (true);

CREATE POLICY "Admins read archive appointments" ON public."kvk_archive_appointments" AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY "Admins read archive cycles" ON public."kvk_archive_cycles" AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY "Players can create own profile" ON public."player_profiles" AS PERMISSIVE FOR INSERT TO authenticated, anonymous WITH CHECK ((user_id = public.kvk_player_actor()));

CREATE POLICY "Players can read own profile" ON public."player_profiles" AS PERMISSIVE FOR SELECT TO authenticated, anonymous USING (((user_id = public.kvk_player_actor()) OR is_admin()));

CREATE POLICY "Players can update own unlocked profile" ON public."player_profiles" AS PERMISSIVE FOR UPDATE TO authenticated, anonymous USING ((((user_id = public.kvk_player_actor()) AND (resources_locked = false)) OR is_admin())) WITH CHECK (((user_id = public.kvk_player_actor()) OR is_admin()));

CREATE POLICY "Admins read rejection log" ON public."rejection_log" AS PERMISSIVE FOR SELECT TO authenticated USING (is_admin());

CREATE POLICY "Admins update rejection log" ON public."rejection_log" AS PERMISSIVE FOR UPDATE TO authenticated USING (is_admin());

CREATE POLICY "Admins delete requests" ON public."slot_requests" AS PERMISSIVE FOR DELETE TO authenticated, anonymous USING (is_admin());

CREATE POLICY "Players create own requests" ON public."slot_requests" AS PERMISSIVE FOR INSERT TO authenticated, anonymous WITH CHECK ((profile_id IN ( SELECT player_profiles.id
   FROM player_profiles
  WHERE (player_profiles.user_id = public.kvk_player_actor()))));

CREATE POLICY "Players see own requests admins see all" ON public."slot_requests" AS PERMISSIVE FOR SELECT TO authenticated, anonymous USING (((profile_id IN ( SELECT player_profiles.id
   FROM player_profiles
  WHERE (player_profiles.user_id = public.kvk_player_actor()))) OR is_admin()));

CREATE POLICY "Players update own requests admins update all" ON public."slot_requests" AS PERMISSIVE FOR UPDATE TO authenticated, anonymous USING ((((profile_id IN ( SELECT player_profiles.id
   FROM player_profiles
  WHERE (player_profiles.user_id = public.kvk_player_actor()))) AND (status = 'pending'::text)) OR is_admin()));

GRANT USAGE ON SCHEMA public TO anonymous, authenticated;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

GRANT SELECT ON public.appointments, public.day_settings, public.player_profiles, public.slot_requests TO anonymous;

GRANT INSERT (user_id, player_id, player_name, alliance, truegold, general_speedups, research_speedups, training_speedups, construction_speedups, resource_snapshot_required, resource_updated_at) ON public.player_profiles TO anonymous, authenticated;

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_manual_assign(text, text, text, text, text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.archive_current_kvk() TO authenticated;

GRANT EXECUTE ON FUNCTION public.award_slot(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.claim_player_profile(text) TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.get_public_slot_activity() TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.is_admin() TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.kvk_cycle_start_utc() TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.kvk_deadline_utc(text) TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.mark_rejection_contacted(uuid) TO authenticated;

GRANT EXECUTE ON FUNCTION public.reject_slot_request(uuid, text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.reset_kvk_cycle() TO authenticated;

GRANT EXECUTE ON FUNCTION public.save_player_profile(uuid, text, text, numeric, numeric, numeric, numeric, numeric) TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.set_admin_note(uuid, text) TO authenticated;

GRANT EXECUTE ON FUNCTION public.set_day_finalised(text, boolean) TO authenticated;

GRANT EXECUTE ON FUNCTION public.submit_slot_requests(text, text[]) TO anonymous, authenticated;

GRANT EXECUTE ON FUNCTION public.undo_last_admin_action() TO authenticated;

GRANT EXECUTE ON FUNCTION public.kvk_player_actor() TO anonymous, authenticated;

INSERT INTO public.day_settings(event_day,is_finalised) VALUES ('monday',false),('tuesday',false),('thursday',false);

NOTIFY pgrst, 'reload schema';


CREATE OR REPLACE FUNCTION public.kvk_player_actor() RETURNS uuid LANGUAGE sql STABLE SET search_path=public AS $$ SELECT coalesce(auth.uid(),nullif(current_setting('kvk.device_id',true),'')::uuid) $$;

CREATE FUNCTION public.get_player_profile(p_device_id uuid) RETURNS SETOF public.player_profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$  BEGIN IF p_device_id IS NULL THEN RAISE EXCEPTION 'Player identity required'; END IF; PERFORM set_config('kvk.device_id',p_device_id::text,true); RETURN QUERY SELECT * FROM public.player_profiles WHERE user_id=public.kvk_player_actor() ORDER BY updated_at DESC LIMIT 1; END $$;

REVOKE ALL ON FUNCTION public.get_player_profile(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_player_profile(uuid) TO anonymous,authenticated;

CREATE FUNCTION public.get_player_requests(p_device_id uuid) RETURNS SETOF public.slot_requests LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$  BEGIN IF p_device_id IS NULL THEN RAISE EXCEPTION 'Player identity required'; END IF; PERFORM set_config('kvk.device_id',p_device_id::text,true); RETURN QUERY SELECT r.* FROM public.slot_requests r JOIN public.player_profiles p ON p.id=r.profile_id WHERE p.user_id=public.kvk_player_actor(); END $$;

REVOKE ALL ON FUNCTION public.get_player_requests(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_player_requests(uuid) TO anonymous,authenticated;

CREATE FUNCTION public.create_player_profile(p_device_id uuid, p_profile jsonb) RETURNS public.player_profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ DECLARE v_profile public.player_profiles; BEGIN IF p_device_id IS NULL THEN RAISE EXCEPTION 'Player identity required'; END IF; PERFORM set_config('kvk.device_id',p_device_id::text,true); INSERT INTO public.player_profiles(user_id,player_id,player_name,alliance,truegold,general_speedups,research_speedups,training_speedups,construction_speedups,resource_snapshot_required,resource_updated_at)
VALUES(public.kvk_player_actor(),trim(p_profile->>'player_id'),trim(p_profile->>'player_name'),p_profile->>'alliance',greatest(coalesce((p_profile->>'truegold')::numeric,0),0),greatest(coalesce((p_profile->>'general_speedups')::numeric,0),0),greatest(coalesce((p_profile->>'research_speedups')::numeric,0),0),greatest(coalesce((p_profile->>'training_speedups')::numeric,0),0),greatest(coalesce((p_profile->>'construction_speedups')::numeric,0),0),false,now()) RETURNING * INTO v_profile; RETURN v_profile; END $$;

REVOKE ALL ON FUNCTION public.create_player_profile(uuid, jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_player_profile(uuid, jsonb) TO anonymous,authenticated;

CREATE FUNCTION public.player_claim_profile(p_device_id uuid, p_player_id text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$  BEGIN IF p_device_id IS NULL THEN RAISE EXCEPTION 'Player identity required'; END IF; PERFORM set_config('kvk.device_id',p_device_id::text,true); RETURN public.claim_player_profile(p_player_id); END $$;

REVOKE ALL ON FUNCTION public.player_claim_profile(uuid, text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.player_claim_profile(uuid, text) TO anonymous,authenticated;

CREATE FUNCTION public.player_save_profile(p_device_id uuid, p_profile_id uuid, p_player_name text, p_alliance text, p_truegold numeric, p_general_speedups numeric, p_research_speedups numeric, p_training_speedups numeric, p_construction_speedups numeric) RETURNS public.player_profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$  BEGIN IF p_device_id IS NULL THEN RAISE EXCEPTION 'Player identity required'; END IF; PERFORM set_config('kvk.device_id',p_device_id::text,true); RETURN public.save_player_profile(p_profile_id,p_player_name,p_alliance,p_truegold,p_general_speedups,p_research_speedups,p_training_speedups,p_construction_speedups); END $$;

REVOKE ALL ON FUNCTION public.player_save_profile(uuid, uuid, text, text, numeric, numeric, numeric, numeric, numeric) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.player_save_profile(uuid, uuid, text, text, numeric, numeric, numeric, numeric, numeric) TO anonymous,authenticated;

CREATE FUNCTION public.player_submit_requests(p_device_id uuid, p_event_day text, p_slot_keys text[]) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$  BEGIN IF p_device_id IS NULL THEN RAISE EXCEPTION 'Player identity required'; END IF; PERFORM set_config('kvk.device_id',p_device_id::text,true); PERFORM public.submit_slot_requests(p_event_day,p_slot_keys); END $$;

REVOKE ALL ON FUNCTION public.player_submit_requests(uuid, text, text[]) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.player_submit_requests(uuid, text, text[]) TO anonymous,authenticated;

REVOKE EXECUTE ON FUNCTION public.claim_player_profile(text) FROM anonymous;

REVOKE EXECUTE ON FUNCTION public.save_player_profile(uuid,text,text,numeric,numeric,numeric,numeric,numeric) FROM anonymous;

REVOKE EXECUTE ON FUNCTION public.submit_slot_requests(text,text[]) FROM anonymous;

REVOKE INSERT ON public.player_profiles FROM anonymous,authenticated;

NOTIFY pgrst, 'reload schema';


CREATE INDEX idx_player_profiles_user_id ON public.player_profiles USING btree (user_id);

CREATE UNIQUE INDEX player_profiles_one_profile_per_user_idx ON public.player_profiles USING btree (user_id) WHERE (user_id IS NOT NULL);

CREATE INDEX idx_rejection_log_rejected_at ON public.rejection_log USING btree (rejected_at DESC);

CREATE INDEX idx_slot_requests_day_slot_status ON public.slot_requests USING btree (event_day, slot_key, status);

CREATE INDEX idx_slot_requests_profile_day ON public.slot_requests USING btree (profile_id, event_day);

REVOKE INSERT (user_id, player_id, player_name, alliance, truegold, general_speedups, research_speedups, training_speedups, construction_speedups, resource_snapshot_required, resource_updated_at) ON public.player_profiles FROM anonymous,authenticated;

CREATE OR REPLACE FUNCTION public.get_managed_admin_user(p_admin_role text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_id uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.admin_users WHERE id=auth.uid() AND admin_role='owner') THEN
    RAISE EXCEPTION 'Owner access required';
  END IF;
  IF p_admin_role NOT IN ('king','minister') OR p_admin_role IS NULL THEN
    RAISE EXCEPTION 'Only King and Minister passwords can be managed here';
  END IF;
  SELECT id INTO STRICT v_id FROM public.admin_users WHERE admin_role=p_admin_role;
  RETURN v_id;
EXCEPTION WHEN NO_DATA_FOUND THEN
  RAISE EXCEPTION 'The selected admin account is not configured';
WHEN TOO_MANY_ROWS THEN
  RAISE EXCEPTION 'More than one account has the selected admin role';
END;
$$;
REVOKE ALL ON FUNCTION public.get_managed_admin_user(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_managed_admin_user(text) TO authenticated;
NOTIFY pgrst,'reload schema';

-- Resolve the verified JWT identity under the function owner when called from RLS.
ALTER FUNCTION public.kvk_player_actor() SECURITY DEFINER;
