CREATE OR REPLACE FUNCTION Test.rct_normal_case() RETURNS BOOLEAN AS
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
                             2,
                             'Why not',
                             'signature1');
    PERFORM Blockchain.commitBlock();
    SELECT Blockchain.addRCT('bbb123',
                             extract(epoch from now()),
                             'aaa123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'butter scotch',
                             'signature2') INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.rct_receive_before_give() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT  Blockchain.addRCT('bbb123',
                             extract(epoch from now()),
                             'aaa123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'butter scotch',
                             'signature2') AND
            NOT Blockchain.commitBlock() AND -- rct fails
            Blockchain.addGCT('aaa123',
                             extract(epoch from now()),
                             'bbb123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'Why not',
                             'signature1') AND
            Blockchain.commitBlock() AND -- rct fails again, gct is committed
            Blockchain.commitBlock() AND -- rct is committed
            NOT Blockchain.commitBlock() INTO result; -- nothing left in pool
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.rct_too_many_cookies() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.addAUT('bbb123');
    PERFORM Blockchain.commitBlock();
    PERFORM Blockchain.addGCT('aaa123', extract(epoch from now()) - 100, 'bbb123',
                             'GENESIS/BLOCK/==============================',
                             3, 'why not', 'signature2');
    PERFORM Blockchain.commitBlock();
    SELECT  Blockchain.addRCT('bbb123', extract(epoch from now()), 'aaa123',
                             'GENESIS/BLOCK/==============================',
                             4, -- more than cookies A owes B
                             'Why not','signature1') AND
            NOT Blockchain.commitBlock() AND -- debt cannot be negative
            Blockchain.addGCT('aaa123', extract(epoch from now()),
                             'bbb123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'why not',
                             'signature2') AND
            Blockchain.commitBlock() AND
            Blockchain.commitBlock() AND
            NOT Blockchain.commitBlock()
            INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.RCT_user_not_exist() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    SELECT  NOT Blockchain.addRCT('bbb123', extract(epoch from now()), 'aaa123',
                             'GENESIS/BLOCK/==============================',
                             4, -- more than cookies A owes B
                             'Why not','signature1') AND
            NOT Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.RCT_invalid_invoker() RETURNS BOOLEAN AS
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
                             2,
                             'Why not',
                             'signature1');
    PERFORM Blockchain.commitBlock();
    PERFORM Blockchain.addRUT('bbb123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addRCT('bbb123',
                             extract(epoch from now()),
                             'aaa123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'butter scotch',
                             'signature2') INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.RCT_invalid_sender() RETURNS BOOLEAN AS
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
                             2,
                             'Why not',
                             'signature1');
    PERFORM Blockchain.commitBlock();
    PERFORM Blockchain.addRUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT NOT Blockchain.addRCT('bbb123',
                             extract(epoch from now()),
                             'aaa123',
                             'GENESIS/BLOCK/==============================',
                             2,
                             'butter scotch',
                             'signature2') INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION WHEN SQLSTATE '45003' THEN
    RETURN result;
  END
  $$ LANGUAGE plpgsql;
