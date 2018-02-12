CREATE OR REPLACE FUNCTION Test.pct_normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
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
    SELECT Blockchain.addPCT('aaa123',
                             'bbb123',
                              extract(epoch from now()),
                              'GENESIS/BLOCK/==============================',
                              10,
                              'signature1') AND
            Blockchain.addPCT('bbb123',
                               'aaa123',
                                extract(epoch from now()),
                                'GENESIS/BLOCK/==============================',
                                10,
                                'signature1') AND
            Blockchain.commitBlock() INTO result;
    SELECT result AND cookies_owed = 0
     INTO result
      FROM Blockchain.Debt
    WHERE sender_pubk = 'aaa123' AND receiver_pubk = 'bbb123';
    SELECT result AND cookies_owed = 10
     INTO result
      FROM Blockchain.Debt
    WHERE sender_pubk = 'bbb123' AND receiver_pubk = 'aaa123';
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
