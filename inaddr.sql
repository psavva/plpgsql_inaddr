CREATE OR REPLACE FUNCTION public.inaddr(	ip inet )
    RETURNS character varying
    LANGUAGE 'plpgsql'
    VOLATILE STRICT PARALLEL UNSAFE
AS $BODY$
DECLARE
	t varchar;
  ex varchar;
  rev varchar;
  l varchar;
  r varchar;
	lparts integer;
	rparts integer;
	i integer;
BEGIN
	t := host( ip );
    
	CASE family(ip)
	WHEN 4 THEN
	    -- this is simple, return it as an expression straightaway
		RETURN 
			split_part(t,'.',4) || '.' ||
			split_part(t,'.',3) || '.' ||
			split_part(t,'.',2) || '.' || 
			split_part(t,'.',1) || '.in-addr.arpa' 
			;
	WHEN 6 THEN
		IF regexp_count(t,'::') = 1 THEN -- only expand if needed
			l := regexp_replace(t, '^([0-9a-fA-F:]*)::[0-9a-fA-F:]*$', '\1');
			r := regexp_replace(t, '^[0-9a-fA-F:]*::([0-9a-fA-F:]*)$', '\1');
			lparts := regexp_count(l,':') + 1;
			rparts := regexp_count(r,':') + 1;
			-- we need enough lparts and missing parts and rparts to make up 8 parts in total
			ex := l;
			FOR i IN 1 .. 8-lparts-rparts LOOP
				ex := ex || ':0';
			END LOOP;
			ex := ex || ':' || r;
			-- pad out all 8 2-byte segments with text instead of worrying about format strings
			ex :=
				lpad( split_part(ex,':',1) ,4, '0') || ':' ||
				lpad( split_part(ex,':',2) ,4, '0') || ':' ||
				lpad( split_part(ex,':',3) ,4, '0') || ':' ||
				lpad( split_part(ex,':',4) ,4, '0') || ':' ||
				lpad( split_part(ex,':',5) ,4, '0') || ':' ||
				lpad( split_part(ex,':',6) ,4, '0') || ':' ||
				lpad( split_part(ex,':',7) ,4, '0') || ':' ||
				lpad( split_part(ex,':',8) ,4, '0');
		END IF;
		-- ex now contains a fully expanded v6 address with punctuation,
    -- either because the input wasn't compressed, or because we expanded it.
		ex := replace(ex,':','');
		-- ex now contains a fully expanded v6 address without punctuation
		rev := reverse(ex);
		rev := regexp_replace( rev,
							'([0-9a-fA-F])',
							'\1.',
							'g');
		RETURN rev;
	END CASE;
END;
$BODY$;
