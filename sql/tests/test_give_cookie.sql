CREATE OR REPLACE FUNCTION Test.GCT_normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT Blockchain.addGCT('aaa123',
                             1234567,
                             'bbb123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'Why not',
                             'signature1') AND
                   Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_negative_cookies() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('aaa123',
                                 1234568,
                                 'bbb123',
                                 'GENESIS/BLOCK/==============================',
                                 -1,
                                 'Why not',
                                 'signature1') AND
           NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_zero_cookies() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('aaa123',
                                 1234569,
                                 'bbb123',
                                 'GENESIS/BLOCK/==============================',
                                 0,
                                 'Why not',
                                 'signature1') AND
                   NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_invoker_not_exist() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('ccc123',
                                         1234570,
                                         'bbb123',
                                         'GENESIS/BLOCK/==============================',
                                         1,
                                         'Why not',
                                         'signature1') AND
                   NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_receiver_not_exist() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('aaa123',
                                         1234570,
                                         'ccc123',
                                         'GENESIS/BLOCK/==============================',
                                         1,
                                         'Why not',
                                         'signature1') AND
                   NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_invalid_invoker() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.addRUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('aaa123',
                              1234572,
                              'bbb123',
                              'GENESIS/BLOCK/==============================',
                              1,
                              'Why not',
                              'signature1') AND
           NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_invalid_receiver() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.addRUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('bbb123',
                              1234572,
                              'aaa123',
                              'GENESIS/BLOCK/==============================',
                              1,
                              'Why not',
                              'signature1') AND
           NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_same_user() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('aaa123',
                                  1234572,
                                  'aaa123',
                                  'GENESIS/BLOCK/==============================',
                                  1,
                                  'Why not',
                                  'signature1') AND
           NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_invalid_block() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('ccc123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('ccc123',
                                  1234572,
                                  'bbb123',
                                  'INVALID/BLOCK/==============================',
                                  1,
                                  'Why not',
                                  'signature1') AND
           NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_repeated_invoker_timestamp() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('ccc123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    PERFORM Blockchain.addGCT(
                        'aaa123',
                        1234567,
                        'bbb123',
                        'INVALID/BLOCK/==============================',
                        1,
                        'Why not',
                        'signature1');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addGCT('aaa123',
                         1234567,
                         'bbb123',
                         'INVALID/BLOCK/==============================',
                         1,
                         'Why not',
                         'signature1') INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;
