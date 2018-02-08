BEGIN TRANSACTION;
CREATE FUNCTION Test.normal_case() RETURNS BOOLEAN AS
  $$
  BEGIN
    PERFORM Blockchain.addAUT('aaa123');
    PERFORM Blockchain.commitBlock();
    RETURN (SELECT Blockchain.addRUT('aaa123') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE FUNCTION Test.same_block_removal() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT Blockchain.addAUT('bbb123') AND
                   Blockchain.addRUT('bbb123') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE FUNCTION Test.same_block_removal_swapped() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT Blockchain.addRUT('ccc123') AND
                   Blockchain.addAUT('ccc123') AND
                   Blockchain.commitBlock() AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

SELECT CONCAT('===TEST REMOVE USER:===', E'\n',
              'Normal case: ', Test.normal_case(), E'\n',
              'Same block removal: ', Test.same_block_removal(), E'\n',
              'Same block removal swapped: ', Test.same_block_removal_swapped());
SELECT Blockchain.getBlockchain('GENESIS/BLOCK/==============================');
ROLLBACK;
