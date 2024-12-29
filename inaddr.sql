CREATE OR REPLACE FUNCTION public.inaddr( ip inet )
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE STRICT PARALLEL UNSAFE
AS $BODY$
DECLARE
    t varchar;      -- Holds the initial host address
    ex varchar;     -- Used for expanded IPv6 address
    rev varchar;    -- Holds reversed final form
    l varchar;      -- Left part of IPv6 address (before ::)
    r varchar;      -- Right part of IPv6 address (after ::)
    lparts integer; -- Number of colon-separated parts on left
    rparts integer; -- Number of colon-separated parts on right
    i integer;      -- Loop counter for padding
BEGIN
    t := host(ip);
    
    CASE family(ip)
    WHEN 4 THEN
        -- Simple IPv4 handling: just reverse the octets and append .in-addr.arpa
        RETURN 
            split_part(t,'.',4) || '.' ||
            split_part(t,'.',3) || '.' ||
            split_part(t,'.',2) || '.' || 
            split_part(t,'.',1) || '.in-addr.arpa';
            
    WHEN 6 THEN
        -- Handle double :: case (invalid IPv6)
        IF regexp_count(t,'::') > 1 THEN
            RAISE EXCEPTION 'Invalid IPv6 address: multiple :: found';
        END IF;
        
        -- If we have :: expansion needed
        IF regexp_count(t,'::') = 1 THEN
            -- Split address into parts before and after '::'
            l := regexp_replace(t, '^([0-9a-fA-F:]*)::[0-9a-fA-F:]*$', '\1');
            r := regexp_replace(t, '^[0-9a-fA-F:]*::([0-9a-fA-F:]*)$', '\1');
            
            -- Handle empty left or right parts
            IF l = '' THEN 
                l := '0';
            END IF;
            IF r = '' THEN
                r := '0';
            END IF;
            
            -- Count parts on each side (adding 1 because n colons = n+1 parts)
            lparts := regexp_count(l,':') + 1;
            rparts := regexp_count(r,':') + 1;
            
            -- Start with left part
            ex := l;
            -- Add the correct number of zero segments
            FOR i IN 1 .. 8-lparts-rparts LOOP
                ex := ex || ':0';
            END LOOP;
            -- Add the right part
            ex := ex || ':' || r;
        ELSE
            -- No :: to expand, just use the address as is
            ex := t;
        END IF;
        
        -- Pad all segments to 4 digits
        ex :=
            lpad(split_part(ex,':',1),4,'0') || ':' ||
            lpad(split_part(ex,':',2),4,'0') || ':' ||
            lpad(split_part(ex,':',3),4,'0') || ':' ||
            lpad(split_part(ex,':',4),4,'0') || ':' ||
            lpad(split_part(ex,':',5),4,'0') || ':' ||
            lpad(split_part(ex,':',6),4,'0') || ':' ||
            lpad(split_part(ex,':',7),4,'0') || ':' ||
            lpad(split_part(ex,':',8),4,'0');
        
        -- Remove colons to get continuous hex string
        ex := replace(ex,':','');
        -- Reverse the string and add dots after each character
        rev := reverse(ex);
        rev := regexp_replace(rev, '([0-9a-fA-F])', '\1.', 'g');
        RETURN rev || 'ip6.arpa';
    END CASE;
END;
$BODY$;
