-- Test Case 1: Normal IPv4 Input
DO $$
DECLARE
  result inet;
BEGIN
  result := from_inaddr('1.2.3.4.in-addr.arpa');
  RAISE NOTICE 'Test Case 1: %', result; -- Expected: 1.2.3.4
END $$;

-- Test Case 2: Normal IPv6 Input
DO $$
DECLARE
  result inet;
BEGIN
  result := from_inaddr('d.c.b.a.9.8.7.6.5.4.3.2.1.0.f.f.e.e.d.c.b.a.9.8.7.6.5.4.3.2.1.0.f.f.e.e.ip6.arpa');
  RAISE NOTICE 'Test Case 2: %', result; -- Expected: fe80:12:34:56:789a:bcde:ff0:dcba
END $$;

-- Test Case 3: Invalid Input (Not a PTR)
DO $$
BEGIN
  PERFORM from_inaddr('invalid.ptr');
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Test Case 3: Invalid PTR';
END $$;

-- Test Case 4: Invalid Input (Incorrect IPv4 Format)
DO $$
BEGIN
  PERFORM from_inaddr('1.2.3.in-addr.arpa');
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Test Case 4: Invalid PTR';
END $$;
