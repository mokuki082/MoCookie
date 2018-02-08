CREATE OR REPLACE FUNCTION Test.GCT_normal_case() RETURNS BOOLEAN AS
  $$
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    RETURN (SELECT Blockchain.addGCT('aaa123',
                                     1234567,
                                     'bbb123',
                                     'GENESIS/BLOCK/==============================',
                                     2,
                                     'Why not',
                                     'signature1') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_negative_cookies() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT NOT Blockchain.addGCT('aaa123',
                                     1234568,
                                     'bbb123',
                                     'GENESIS/BLOCK/==============================',
                                     -1,
                                     'Why not',
                                     'signature1') AND
                   NOT Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_zero_cookies() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT NOT Blockchain.addGCT('aaa123',
                                     1234569,
                                     'bbb123',
                                     'GENESIS/BLOCK/==============================',
                                     0,
                                     'Why not',
                                     'signature1') AND
                   NOT Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_user_not_exist() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT NOT Blockchain.addGCT('ccc123',
                                         1234570,
                                         'bbb123',
                                         'GENESIS/BLOCK/==============================',
                                         1,
                                         'Why not',
                                         'signature1') AND
                   NOT Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_invalid_user() RETURNS BOOLEAN AS
  $$
  BEGIN
    PERFORM Blockchain.addRUT('aaa123');
    RETURN (SELECT Blockchain.addGCT('aaa123',
                                      1234572,
                                      'bbb123',
                                      'GENESIS/BLOCK/==============================',
                                      1,
                                      'Why not',
                                      'signature1') AND
                    Blockchain.commitBlock() AND -- RUT committed, GCT discarded.
                    NOT Blockchain.commitBlock()); -- no transaction in pool.
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_same_user() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT NOT Blockchain.addGCT('bbb123',
                                      1234572,
                                      'bbb123',
                                      'GENESIS/BLOCK/==============================',
                                      1,
                                      'Why not',
                                      'signature1') AND
                    NOT Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_invalid_block() RETURNS BOOLEAN AS
  $$
  BEGIN
    PERFORM Blockchain.addAUT('ccc123');
    PERFORM Blockchain.commitBlock();
    RETURN (SELECT NOT Blockchain.addGCT('ccc123',
                                      1234572,
                                      'bbb123',
                                      'INVALID/BLOCK/==============================',
                                      1,
                                      'Why not',
                                      'signature1') AND
                    NOT Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.GCT_repeated_invoker_timestamp() RETURNS BOOLEAN AS
  $$
  BEGIN
    PERFORM Blockchain.addAUT('ccc123');
    PERFORM Blockchain.commitBlock();
    RETURN (SELECT NOT Blockchain.addGCT('aaa123',
                                     1234567,
                                      'bbb123',
                                      'INVALID/BLOCK/==============================',
                                      1,
                                      'Why not',
                                      'signature1') AND
                    NOT Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;
