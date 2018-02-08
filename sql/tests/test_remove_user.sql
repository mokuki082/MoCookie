
CREATE OR REPLACE FUNCTION Test.RUT_normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.commitBlock();
    SELECT Blockchain.addRUT('aaa123') AND
           Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.RUT_same_block_removal() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    SELECT Blockchain.addAUT('bbb123') AND
           Blockchain.addRUT('bbb123') AND
           Blockchain.commitBlock() AND
           NOT Blockchain.commitBlocK() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Test.RUT_same_block_removal_swapped() RETURNS BOOLEAN AS
  $$
  DECLARE
    result BOOLEAN;
  BEGIN
    SELECT Blockchain.addRUT('ccc123') AND
           Blockchain.addAUT('ccc123') AND
           Blockchain.commitBlock() AND
           Blockchain.commitBlock() INTO result;
    RAISE EXCEPTION SQLSTATE '45003';
  EXCEPTION
    WHEN SQLSTATE '45003' THEN RETURN result;
  END
  $$ LANGUAGE plpgsql;
