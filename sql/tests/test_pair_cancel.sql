CREATE OR REPLACE FUNCTION Test.pct_normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.addGCT('aaa123',
                             extract(epoch from now()),
                             'bbb123',
                             'GENESIS/BLOCK/==============================',
                             10,
                             'Why not',
                             'signature1');
    PERFORM Blockchain.addGCT('bbb123',
                              extract(epoch from now()),
                              'aaa123',
                              'GENESIS/BLOCK/==============================',
                              20,
                              'Why not',
                              'signature1');
    PERFORM Blockchain.addPCT('bbb123',
                              extract(epoch from now()),
                              'aaa123',
                              'GENESIS/BLOCK/==============================',
                              20,
                              'Why not',
                              'signature1');
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
