CREATE OR REPLACE FUNCTION Test.cct_normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.addAUT('ccc123');
    PERFORM Blockchain.commitBlock();
    PERFORM Blockchain.addGCT('aaa123',
                              1234567,
                              'bbb123',
                              'GENESIS/BLOCK/==============================',
                              12,
                              'Why not',
                              'signature1');
    PERFORM Blockchain.addGCT('bbb123',
                              1234567,
                              'ccc123',
                              'GENESIS/BLOCK/==============================',
                              30,
                              'Why not',
                              'signature1');
    PERFORM Blockchain.commitBlock();
    SELECT Blockchain.addCCT('aaa123',
                             1234568,
                             'GENESIS/BLOCK/==============================',
                             'aaa123',
                             'bbb123',
                             'ccc123',
                             12,
                             'signature123') AND
           Blockchain.addCCT('bbb123',
                              1234568,
                              'GENESIS/BLOCK/==============================',
                              'aaa123',
                              'bbb123',
                              'ccc123',
                              12,
                              'signature123') AND
           Blockchain.addCCT('ccc123',
                             1234568,
                             'GENESIS/BLOCK/==============================',
                             'aaa123',
                             'bbb123',
                             'ccc123',
                             12,
                             'signature123') AND
           Blockchain.commitBlock() AND
           NOT Blockchain.commitBlock() INTO result;
    SELECT result AND cookies_owed = 0
     INTO result
     FROM Blockchain.Debt
     WHERE sender_pubk = 'aaa123' AND
           receiver_pubk = 'bbb123';
    SELECT result AND cookies_owed = 18
    INTO result
    FROM Blockchain.Debt
    WHERE sender_pubk = 'bbb123' AND
          receiver_pubk = 'ccc123';
    SELECT result AND cookies_owed = 12
    INTO result
    FROM Blockchain.Debt
    WHERE sender_pubk = 'aaa123' AND
          receiver_pubk = 'ccc123';
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
