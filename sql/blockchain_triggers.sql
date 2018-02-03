CREATE OR REPLACE FUNCTION Blockchain.checkPreviousHashFKey()
  RETURNS trigger AS
  /* Check that the previous_hash is valid. */
  $$
    DECLARE
      genesis_hash CONSTANT TEXT := '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
      searched_hash TEXT;
    BEGIN
      IF (NEW.id = 1 AND NEW.prev_hash IS NULL) THEN
        -- Genesis block must have a all 0 prev_hash
        RETURN NEW;
      searched_hash := (SELECT curr_hash FROM Blockchain.Block
                        WHERE NEW.id - 1 = id);
      ELSEIF (searched_hash IS NOT NULL AND
              NEW.prev_hash = searched_hash) THEN
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
      occ INT := 0;
    BEGIN
      IF (EXISTS (SELECT 1
                  FROM Blockchain.GiveCookieTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.ReceiveCookieTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.ChainCollapseTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.CombinedChainCollapseTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.PairCancelTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.CombinedPairCancelTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.AddUserTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (EXISTS (SELECT 1
                  FROM Blockchain.RemoveUserTransaction AS t
                  WHERE t.id = NEW.id)) THEN
        occ := occ + 1;
      END IF;
      IF (occ = 1) THEN
        RETURN NULL;
      ELSE
        RAISE EXCEPTION 'Transaction is not mutually exclusive.';
      END IF;
    END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS gct_mutualexcl_check
  ON Blockchain.GiveCookieTransaction;
CREATE TRIGGER gct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.GiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS rct_mutualexcl_check
  ON Blockchain.ReceiveCookieTransaction;
CREATE TRIGGER rct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.ReceiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS cct_mutualexcl_check
  ON Blockchain.ChainCollapseTransaction;
CREATE TRIGGER cct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.ChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS ccct_mutualexcl_check
  ON Blockchain.CombinedChainCollapseTransaction;
CREATE TRIGGER ccct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.CombinedChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS pct_mutualexcl_check
  ON Blockchain.PairCancelTransaction;
CREATE TRIGGER pct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.PairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS cpct_mutualexcl_check
  ON Blockchain.CombinedPairCancelTransaction;
CREATE TRIGGER cpct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.CombinedPairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS aut_mutualexcl_check
  ON Blockchain.AddUserTransaction;
CREATE TRIGGER aut_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.AddUserTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

DROP TRIGGER IF EXISTS rut_mutualexcl_check
  ON Blockchain.RemoveUserTransaction;
CREATE TRIGGER rut_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.RemoveUserTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.checkTransactionMutualExcl();

CREATE OR REPLACE FUNCTION Blockchain.addToInvalidUser()
  RETURNS trigger AS
  /* Insert user into InvalidUser upon deletion */
  $$
  BEGIN
    INSERT INTO Blockchain.InvalidUser(pubk) VALUES (OLD.pubk);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS validuser_pubk_trig
  ON Blockchain.ValidUser;
CREATE TRIGGER validuser_pubk_trig
  /* Insert user into InvalidUser upon deletion */
  AFTER DELETE ON Blockchain.ValidUser
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.addToInvalidUser();
