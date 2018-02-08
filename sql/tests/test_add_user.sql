/* Use mc_admin to run this file */

BEGIN;
CREATE FUNCTION Test.normal_case() RETURNS BOOLEAN AS
  $$
  DECLARE
    partial_result BOOLEAN;
  BEGIN
    RETURN (SELECT Blockchain.addAUT('aaa123') AND
                   Blockchain.addAUT('bbb123') AND
                   Blockchain.addAUT('ccc123') AND
                   Blockchain.addAUT('ddd123') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE FUNCTION Test.duplicate_user() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT Blockchain.addAUT('eee123') AND
                   NOT Blockchain.addAUT('eee123') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

CREATE FUNCTION Test.add_after_del() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT Blockchain.addRUT('eee123') AND
                   NOT Blockchain.addAUT('eee123') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

SELECT CONCAT('===TEST ADD USER:===', E'\n',
              'Normal case: ', Test.normal_case(), E'\n',
              'Duplicate user: ', Test.duplicate_user(), E'\n',
              'Add after del: ', Test.add_after_del());
SELECT Blockchain.getBlockchain('GENESIS/BLOCK/==============================');
ROLLBACK;
