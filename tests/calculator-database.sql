DO $test$
DECLARE r public.player_profiles; first_row public.player_profiles; other_device uuid='a3333333-3333-4333-8333-333333333333'; device uuid='a2222222-2222-4222-8222-222222222222';
BEGIN
 BEGIN
 INSERT INTO public.player_profiles(id,user_id,player_id,player_name,alliance,truegold,general_speedups,construction_speedups,research_speedups,training_speedups)
 VALUES('a1111111-1111-4111-8111-111111111111',device,'CALC-TEST-20261011','Calculator test','CRN',120,100,100,45,77) RETURNING * INTO r;
 first_row=r;
 BEGIN
 PERFORM public.save_calculator_profile(other_device,r.id,0,r.updated_at,'{"resources":{"bread":10}}');
 RAISE EXCEPTION 'ownership check failed';
 EXCEPTION WHEN OTHERS THEN IF SQLERRM NOT LIKE '%not linked%' THEN RAISE; END IF; END;
 r=public.save_calculator_profile(device,r.id,0,r.updated_at,'{"resources":{"bread":1000000000,"wood":1000000000,"stone":1000000000,"iron":1000000000,"tempered_truegold":0},"booking":{"truegold":158},"resources_checked_at":"ignored"}');
 IF r.truegold<>158 OR r.research_speedups<>45 OR r.training_speedups<>77 OR r.calculator_revision<>1 THEN RAISE EXCEPTION 'resource preservation failed'; END IF;
 BEGIN
 PERFORM public.save_calculator_profile(device,r.id,0,first_row.updated_at,'{"booking":{"truegold":0}}');
 RAISE EXCEPTION 'stale save check failed';
 EXCEPTION WHEN OTHERS THEN IF SQLERRM NOT LIKE '%changed%' THEN RAISE; END IF; END;
 r=public.save_calculator_profile(device,r.id,r.calculator_revision,r.updated_at,'{"stats":{"construction_speed":100,"saul_level":5,"wolf_rank":5,"pan_level":0},"city":{"town_center":39,"embassy":35,"stable":35,"academy":30},"plan":[{"building":"town_center","target":40}]}');
 IF r.calculator_profile->'resources'->>'bread'<>'1000000000' THEN RAISE EXCEPTION 'partial merge failed'; END IF;
 BEGIN
 PERFORM public.save_calculator_profile(device,r.id,r.calculator_revision,r.updated_at,'{"stats":{"saul_level":6}}');
 RAISE EXCEPTION 'validation check failed';
 EXCEPTION WHEN OTHERS THEN IF SQLERRM NOT LIKE '%out of range%' THEN RAISE; END IF; END;
 UPDATE public.player_profiles SET resources_locked=true WHERE id=r.id RETURNING * INTO r;
 BEGIN
 PERFORM public.save_calculator_profile(device,r.id,r.calculator_revision,r.updated_at,'{"booking":{"truegold":0}}');
 RAISE EXCEPTION 'lock check failed';
 EXCEPTION WHEN OTHERS THEN IF SQLERRM NOT LIKE '%locked%' THEN RAISE; END IF; END;
 UPDATE public.player_profiles SET resource_snapshot_required=true WHERE id=r.id RETURNING * INTO r;
 BEGIN
 PERFORM public.save_calculator_profile(device,r.id,r.calculator_revision,r.updated_at,'{"city":{"town_center":40}}');
 RAISE EXCEPTION 'snapshot check failed';
 EXCEPTION WHEN OTHERS THEN IF SQLERRM NOT LIKE '%booking profile%' THEN RAISE; END IF; END;
 RAISE SQLSTATE 'P0002' USING MESSAGE='rollback successful test fixture';
 EXCEPTION WHEN NO_DATA_FOUND THEN NULL; END;
 IF EXISTS(SELECT 1 FROM public.player_profiles WHERE id='a1111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'fixture was not rolled back'; END IF;
END $test$;
