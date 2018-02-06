CREATE OR REPLACE FUNCTION Blockchain.blockPrevHashFkey()
  RETURNS trigger AS
  /* Check that the previous_hash is valid. */
  $$
    DECLARE
      genesis_hash CONSTANT TEXT := '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
      searched_hash TEXT;
    BEGIN
      IF (NEW.id = 1) THEN
        IF (NEW.prev_hash IS NULL AND NEW.curr_hash = genesis_hash) THEN
          -- Genesis block must have a all 0 curr_hash and NULL prev_hash
          RETURN NEW;
        ELSE
          RAISE EXCEPTION 'Genesis block must have NULL prev_hash and all 0 curr_hash.';
        END IF;
      ELSEIF (NEW.id > 1) THEN
        IF (NEW.prev_hash IS NOT NULL AND
            NEW.prev_hash = (SELECT curr_hash FROM Blockchain.Block
                             WHERE id = NEW.id - 1)) THEN
          -- Non-genesis block must have previous block's hash as prev_hash
          RETURN NEW;
        ELSE
          RAISE EXCEPTION 'Block''s prev_hash does not match.';
        END IF;
      ELSE
        RAISE EXCEPTION 'Block id cannot be 0 or negative.';
      END IF;
    END
  $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS block_prev_hash_fkey ON Blockchain.Block;
CREATE TRIGGER block_prev_hash_fkey
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF curr_hash, prev_hash ON Blockchain.Block
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.blockPrevHashFkey();


CREATE OR REPLACE FUNCTION Blockchain.transactionMutualExclCheck()
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
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS rct_mutualexcl_check
  ON Blockchain.ReceiveCookieTransaction;
CREATE TRIGGER rct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.ReceiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS cct_mutualexcl_check
  ON Blockchain.ChainCollapseTransaction;
CREATE TRIGGER cct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.ChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS ccct_mutualexcl_check
  ON Blockchain.CombinedChainCollapseTransaction;
CREATE TRIGGER ccct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.CombinedChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS pct_mutualexcl_check
  ON Blockchain.PairCancelTransaction;
CREATE TRIGGER pct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.PairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS cpct_mutualexcl_check
  ON Blockchain.CombinedPairCancelTransaction;
CREATE TRIGGER cpct_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.CombinedPairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS aut_mutualexcl_check
  ON Blockchain.AddUserTransaction;
CREATE TRIGGER aut_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.AddUserTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();

DROP TRIGGER IF EXISTS rut_mutualexcl_check
  ON Blockchain.RemoveUserTransaction;
CREATE TRIGGER rut_mutualexcl_check
  /* Check that transactions are mutually exclusive. */
  AFTER INSERT OR UPDATE OF id ON Blockchain.RemoveUserTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.transactionMutualExclCheck();


CREATE OR REPLACE FUNCTION Blockchain.isValidUser(k TEXT)
  RETURNS BOOLEAN AS
  /* Returns whether user is valid or not

  Argument:
  k -- User's public key

  Returns:
  TRUE -- User is valid
  FALSE -- User is invalid
  */
  $$
  BEGIN
    RETURN (SELECT valid FROM CookieUser WHERE pubk = k);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.GCTUserCheck()
  RETURNS trigger AS
  /* Check that all users are valid */
  $$
  BEGIN
    IF ((SELECT Blockchain.isValidUser(NEW.invoker)) AND
        (SELECT Blockchain.isValidUser(NEW.receiver))) THEN
      RETURN NEW;
    ELSE RAISE EXCEPTION 'User is invalid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS gct_user_check ON Blockchain.GiveCookieTransaction;
CREATE TRIGGER gct_user_check
  /* Check that all users are valid */
  BEFORE INSERT OR UPDATE OF invoker, receiver
    ON Blockchain.GiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.GCTUserCheck();

CREATE OR REPLACE FUNCTION Blockchain.RCTUserCheck()
  RETURNS trigger AS
  /* Check that all users are valid */
  $$
  BEGIN
    IF ((SELECT Blockchain.isValidUser(NEW.invoker)) AND
        (SELECT Blockchain.isValidUser(NEW.sender))) THEN
      RETURN NEW;
    ELSE RAISE EXCEPTION 'User is invalid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS rct_user_check ON Blockchain.ReceiveCookieTransaction;
CREATE TRIGGER rct_user_check
  /* Check that all users are valid */
  BEFORE INSERT OR UPDATE OF invoker, sender
    ON Blockchain.ReceiveCookieTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.RCTUserCheck();

CREATE OR REPLACE FUNCTION Blockchain.CCTUserCheck()
  RETURNS trigger AS
  /* Check that all users are valid */
  $$
  BEGIN
    IF ((SELECT Blockchain.isValidUser(NEW.invoker))) THEN
      RETURN NEW;
    ELSE RAISE EXCEPTION 'User is invalid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS cct_user_check ON Blockchain.ChainCollapseTransaction;
CREATE TRIGGER block_prev_hash_fkey
  /* Check that all users are valid */
  BEFORE INSERT OR UPDATE OF invoker ON Blockchain.ChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.CCTUserCheck();

CREATE OR REPLACE FUNCTION Blockchain.CCCTUserCheck()
  RETURNS trigger AS
  /* Check that all users are valid */
  $$
  BEGIN
    IF ((SELECT Blockchain.isValidUser(NEW.start_user)) AND
        (SELECT Blockchain.isValidUser(NEW.mid_user)) AND
        (SELECT Blockchain.isValidUser(NEW.end_user))) THEN
      RETURN NEW;
    ELSE RAISE EXCEPTION 'User is invalid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS ccct_user_check
  ON Blockchain.CombinedChainCollapseTransaction;
CREATE TRIGGER ccct_user_check
  /* Check that the previous_hash is valid. */
  BEFORE INSERT OR UPDATE OF start_user, mid_user, end_user
    ON Blockchain.CombinedChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.CCCTUserCheck();

CREATE OR REPLACE FUNCTION Blockchain.PCTUserCheck()
  RETURNS trigger AS
  /* Check that all users are valid */
  $$
  BEGIN
    IF ((SELECT Blockchain.isValidUser(NEW.invoker))) THEN
      RETURN NEW;
    ELSE RAISE EXCEPTION 'User is invalid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS pct_user_check ON Blockchain.PairCancelTransaction;
CREATE TRIGGER pct_user_check
  /* Check that all users are valid */
  BEFORE INSERT OR UPDATE OF invoker ON Blockchain.PairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.PCTUserCheck();

CREATE OR REPLACE FUNCTION Blockchain.CPCTUserCheck()
  RETURNS trigger AS
  /* Check that all users are valid */
  $$
  BEGIN
    IF ((SELECT Blockchain.isValidUser(NEW.user_a)) AND
        (SELECT Blockchain.isValidUser(NEW.user_b))) THEN
      RETURN NEW;
    ELSE RAISE EXCEPTION 'User is invalid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS cpct_user_check
  ON Blockchain.CombiendPairCancelTransaction;
CREATE TRIGGER cpct_user_check
  /* Check that all users are valid */
  BEFORE INSERT OR UPDATE OF user_a, user_b
    ON Blockchain.CombinedPairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.CPCTUsercheck();

CREATE OR REPLACE FUNCTION Blockchain.cookieUserValidCheck()
  RETURNS trigger AS
  /* Once a user is invalid they cannot be valid again */
  $$
  BEGIN
    IF (NOT OLD.valid AND NEW.valid) THEN
      -- If the user is changed from invalid -> valid
      RAISE EXCEPTION 'User cannot be changed to valid';
    ELSE
      RETURN NEW;
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS cookieuser_valid_check ON Blockchain.CookieUser;
CREATE TRIGGER cookieuser_valid_check
  /* Once a user is invalid they cannot be valid again */
  BEFORE UPDATE OF valid ON Blockchain.CookieUser
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.cookieUserValidCheck();


CREATE OR REPLACE FUNCTION Blockchain.CCCTIndividualTransactionCheck()
  RETURNS trigger AS
  /* Make sure candidates in Combined transaction are the ones in the actual
  sub-transactions.
  */
  $$
  BEGIN
    IF (NEW.start_user_transaction IS NOT NULL) THEN
      IF (NOT NEW.start_user = (SELECT invoker
                                FROM Blockchain.ChainCollapseTransaction
                                WHERE id = NEW.start_user_transaction)) THEN
        RAISE EXCEPTION 'Incorrect start_user.';
      END IF;
    END IF;
    IF (NEW.mid_user_transaction IS NOT NULL) THEN
      IF (NOT NEW.mid_user = (SELECT invoker
                              FROM Blockchain.ChainCollapseTransaction
                              WHERE id = NEW.mid_user_transaction)) THEN
        RAISE EXCEPTION 'Incorrect mid_user.';
      END IF;
    END IF;
    IF (NEW.end_user_transaction IS NOT NULL) THEN
      IF (NOT NEW.end_user = (SELECT invoker
                              FROM Blockchain.ChainCollapseTransaction
                              WHERE id = NEW.end_user_transaction)) THEN
        RAISE EXCEPTION 'Incorrect end_user.';
      END IF;
    END IF;
    RETURN NEW;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

DROP TRIGGER IF EXISTS ccct_individual_transaction_check
  ON Blockchain.CombinedChainCollapseTransaction;
CREATE TRIGGER ccct_individual_transaction_check
  /* Make sure candidates in Combined transaction are the ones in the actual
  sub-transactions.
  */
  BEFORE UPDATE OF start_user_transaction,
                   mid_user_transaction,
                   end_user_transaction
                   ON Blockchain.CombinedChainCollapseTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.CCCTIndividualTransactionCheck();


CREATE OR REPLACE FUNCTION Blockchain.CPCTIndividualTransactionCheck()
  RETURNS trigger AS
  /* Make sure candidates in Combined transaction are the ones in the actual
  sub-transactions.
  */
  $$
  BEGIN
    IF (NEW.user_a_transaction IS NOT NULL) THEN
      IF (NOT NEW.user_a = (SELECT invoker
                            FROM Blockchain.PairCancelTransaction
                            WHERE id = NEW.user_a_transaction)) THEN
        RAISE EXCEPTION 'Incorrect user A.';
      END IF;
    END IF;
    IF (NEW.user_b_transaction IS NOT NULL) THEN
      IF (NOT NEW.user_b = (SELECT invoker
                            FROM Blockchain.PairCancelTransaction
                            WHERE id = NEW.user_b_transaction)) THEN
        RAISE EXCEPTION 'Incorrect user B.';
      END IF;
    END IF;
    RETURN NEW;
  END
  $$ LANGUAGE plpgsql SECURITY INVOKER;

DROP TRIGGER IF EXISTS cpct_individual_transaction_check
  ON Blockchain.CombinedPairCancelTransaction;
CREATE TRIGGER cpct_individual_transaction_check
  /* Make sure candidates in Combined transaction are the ones in the actual
  sub-transactions.
  */
  BEFORE UPDATE OF user_a_transaction, user_b_transaction
                   ON Blockchain.CombinedPairCancelTransaction
  FOR EACH ROW
  EXECUTE PROCEDURE Blockchain.CPCTIndividualTransactionCheck();
