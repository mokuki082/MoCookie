/* Use mc_admin to run this file */

BEGIN;
CREATE FUNCTION Blockchain.normal_case() RETURNS BOOLEAN AS
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

CREATE FUNCTION Blockchain.duplicate_user() RETURNS BOOLEAN AS
  $$
  BEGIN
    RETURN (SELECT Blockchain.addAUT('eee123') AND
                   NOT Blockchain.addAUT('eee123') AND
                   Blockchain.commitBlock());
  END
  $$ LANGUAGE plpgsql;

SELECT Blockchain.normal_case();
SELECT Blockchain.duplicate_user();
SELECT Blockchain.getBlockchain('GENESIS/BLOCK/==============================');
ROLLBACK;
