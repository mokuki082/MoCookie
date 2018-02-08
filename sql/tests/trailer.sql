SELECT n.nspname as "Schema", p.proname as "Name"
FROM pg_catalog.pg_proc p
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname ~ '^(test)$';

COMMIT;
