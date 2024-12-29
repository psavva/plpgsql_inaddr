CREATE OR REPLACE FUNCTION from_inaddr( ptr character varying )
  RETURNS inet
  LANGUAGE 'plpgsql'
  STRICT
AS $BODY$
DECLARE
	ip inet;
	ndots integer;
BEGIN
	-- ptr contains the "x.x.x.x.in-addr.arpa" or "x.[...].x.x.ip6.arpa" string
	ndots := regexp_count(ptr,'\.');
	RAISE DEBUG 'ndots=%', ndots;
	
	CASE ndots
	WHEN 5 THEN
		-- IPv4 format
		ptr := regexp_replace( ptr, '([0-9a-fA-F]{1,3})\.([0-9a-fA-F]{1,3})\.([0-9a-fA-F]{1,3})\.([0-9a-fA-F]{1,3})\.in-addr\.arpa\.*$', '\4.\3.\2.\1', '' );
		RAISE DEBUG 'ptr=%', ptr;
		ip := inet( ptr );
	WHEN 33 THEN
    -- IPv6 format, this could be simplified but stepwise is much clearer
    -- trim the ip6.arpa suffic
		ptr := regexp_replace( ptr, '\.ip6\.arpa\.*$', '', '' );
		-- now remove the dots
		ptr := regexp_replace( ptr, '\.', '', 'g');
		-- now flip it round to normal order
		ptr := reverse( ptr );
		-- add a colon every 4 digits (this is valid because PTR format is always fully-expanded
		ptr := regexp_replace( ptr, '([0-9a-fA-F]{4})', '\1:', 'g');
		-- get rid of the trailing colon we just did, the regex to handle that case is insane
		ptr := regexp_replace( ptr, ':$', '' );
		ip := inet( ptr );
	ELSE
		RAISE EXCEPTION 'Invalid PTR';
	END CASE;
	RETURN ip;
END;
$BODY$;
