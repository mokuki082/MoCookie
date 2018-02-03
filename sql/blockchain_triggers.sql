CREATE OR REPLACE FUNCTION Blockchain.checkPreviousHashFKey()
  RETURNS trigger AS
  /* Check that the previous_hash is valid. */
  $$
    DECLARE
      genesis_hash CONSTANT TEXT := '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
    BEGIN
      IF (NEW.ordering = 1 AND NEW.prev_hash = gensis_hash) THEN
        -- Genesis block must have a all 0 prev_hash
        RETURN NEW;
      ELSEIF (NEW.prev_hash = (SELECT curr_hash
                               FROM Blockchain.Block
                               WHERE NEW.id - 1 = id)) THEN
        -- Non-genesis block must have previuos block's hash as prev_hash
        RETURN NEW;
      ELSE
        RAISE EXCEPTION 'Invalid prev_hash.';
      END IF;
    END
  $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS block_prev_hash_fkey ON Blockchain.Block;
CREATE TRIGGER block_prev_hash_fkey
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF curr_hash, prev_hash ON Blockchain.Block
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkPreviousHashFKey();


CREATE OR REPLACE FUNCTION Blockchain.checkTransactionMutualExcl()
  RETURNS trigger AS
  /* Check that all transaction subclasses are mutually exclusive. */
  $$
    DECLARE
      occ INT;
    BEGIN
      occ := (SELECT COUNT(*)
              FROM Blockchain.GiveCookieTransaction as gct
              CROSS JOIN Blockchain.ReceiveCookieTransaction as rct
              CROSS JOIN Blockchain.ChainCollapseTransaction as cct
              CROSS JOIN Blockchain.CombinedChainCollapseTransaction as ccct
              CROSS JOIN Blockchain.PairCancelTransaction as pct
              CROSS JOIN Blockchain.CombinedPairCancelTransaction as cpct
              CROSS JOIN Blockchain.AddUserTransaction as aut
              CROSS JOIN Blockchain.RemoveUserTransaction as rut
              WHERE gct.id = NEW.id OR rct.id = NEW.id OR
                    cct.id = NEW.id OR cpct.id = NEW.id OR
                    pct.id = NEW.id OR cpct.id = NEW.id OR
                    aut.id = NEW.id OR rut.id = NEW.id);
      IF (occ > 1) THEN
        RAISE EXCEPTION 'Transaction is not mutually exclusive.';
      ELSEIF (occ == 1) THEN
        RETURN NEW;
      ELSE
        RAISE EXCEPTION 'Transaction does not exist.';
      END IF;
    END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS gct_mutualexcl_check
  ON Blockchain.GiveCookieTransaction;
CREATE TRIGGER gct_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.GiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS rct_mutualexcl_check
  ON Blockchain.ReceiveCookieTransaction;
CREATE TRIGGER rct_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.ReceiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS cct_mutualexcl_check
  ON Blockchain.ChainCollapseTransaction;
CREATE TRIGGER cct_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.ChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS ccct_mutualexcl_check
  ON Blockchain.CombinedChainCollapseTransaction;
CREATE TRIGGER ccct_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.CombinedChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS pct_mutualexcl_check
  ON Blockchain.PairCancelTransaction;
CREATE TRIGGER pct_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.PairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS cpct_mutualexcl_check
  ON Blockchain.CombinedPairCancelTransaction;
CREATE TRIGGER cpct_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.CombinedPairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS aut_mutualexcl_check
  ON Blockchain.AddUserTransaction;
CREATE TRIGGER aut_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.AddUserTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS rut_mutualexcl_check
  ON Blockchain.RemoveUserTransaction;
CREATE TRIGGER rut_mutualexcl_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF id ON Blockchain.RemoveUserTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();
