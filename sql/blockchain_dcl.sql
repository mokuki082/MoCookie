BEGIN TRANSACTION;
CREATE OR REPLACE FUNCTION Blockchain.getFormattedAUT(tid INT)
  RETURNS TEXT AS
  /* get all information associated to a AUT.

  Returns:
  A string in the format that the protocol is signed.
  */
  $$
  BEGIN
    RETURN (SELECT FORMAT(E'aut\t%s',user_pubk)
            FROM Blockchain.AddUserTransaction
            WHERE id = tid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getFormattedRUT(tid INT)
  RETURNS TEXT AS
  /* get all information associated to a RUT.

  Returns:
  A string in the format that the protocol is signed.
  */
  $$
  BEGIN
    RETURN (SELECT FORMAT(E'rut\t%s',user_pubk)
            FROM Blockchain.RemoveUserTransaction
            WHERE id = tid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getFormattedGCT(tid INT)
  RETURNS TEXT AS
  /* get all information associated to a CCT.

  Returns:
  A string in the format that the protocol is signed
  */
  $$
  BEGIN
    RETURN (SELECT FORMAT(E'gct\t%s\t%s\t%s\t%s\t%s\t%s\t%s',
                          invoker,
                          extract(epoch FROM transaction_time),
                          receiver,
                          b.curr_hash,
                          num_cookies,
                          reason,
                          signature)
            FROM Blockchain.GiveCookieTransaction gct
            JOIN Blockchain.Block b ON (gct.recent_block = b.id)
            WHERE gct.id = tid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getFormattedRCT(tid INT)
  RETURNS TEXT AS
  /* get all information associated to a RCT.

  Returns:
  A string in the format that the protocol is signed.
  */
  $$
  BEGIN
    RETURN (SELECT FORMAT(E'rct\t%s\t%s\t%s\t%s\t%s\t%s\t%s',
                          invoker,
                          extract(epoch FROM transaction_time),
                          sender,
                          b.curr_hash,
                          num_cookies,
                          cookie_type,
                          signature)
            FROM Blockchain.ReceiveCookieTransaction rct
            JOIN Blockchain.Block b ON (rct.recent_block = b.id)
            WHERE rct.id = tid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getFormattedCCT(tid INT)
  RETURNS TEXT AS
  /* get all information associated to a CCT.

  Returns:
  A string in the format that the protocol is signed.
  */
  $$
  BEGIN
    RETURN (SELECT FORMAT(E'cct\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s',
                          invoker,
                          extract(epoch FROM transaction_time),
                          b.curr_hash,
                          start_user,
                          mid_user,
                          end_user,
                          num_cookies,
                          signature)
            FROM Blockchain.ChainCollapseTransaction cct
            JOIN Blockchain.CombinedChainCollapseTransaction ccct
              ON (cct.id = ccct.start_user_transaction OR
                  cct.id = ccct.mid_user_transaction OR
                  cct.id = ccct.end_user_transaction)
            JOIN Blockchain.Block b ON (cct.recent_block = b.id)
            WHERE cct.id = tid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getFormattedPCT(tid INT)
  RETURNS TEXT AS
  /* get all information associated to a PCT.

  Returns:
  A string in the format that the protocol is signed.
  */
  $$
  BEGIN
    RETURN (SELECT FORMAT(E'pct\t%s\t%s\t%s\t%s\t%s',
                          invoker,
                          extract(epoch FROM transaction_time),
                          CASE WHEN pct.id = cpct.user_a_transaction
                            THEN cpct.user_b
                            ELSE cpct.user_a
                          END, -- other
                          num_cookies,
                          signature)
            FROM Blockchain.PairCancelTransaction pct
            JOIN Blockchain.CombinedPairCancelTransaction cpct
              ON (pct.id = cpct.user_a_transaction OR
                  pct.id = cpct.user_b_transaction)
            JOIN Blockchain.Block b ON (pct.recent_block = b.id)
            WHERE pct.id = tid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getFormattedBlock(bid INT)
  RETURNS TEXT AS
  /* Generate a string in this format:

  prev\t<hash>\t
  t1\t
  t2\t
  ...
  tn\t
  */
  $$
  DECLARE
    plaintext TEXT := '';
    partial_plaintext TEXT;
    tid INT;
    protocol VARCHAR(4);
  BEGIN
  SELECT CONCAT(E'prev\t', curr_hash, E'\n') INTO plaintext
    FROM Blockchain.Block
    WHERE id < bid
    ORDER BY id DESC
    LIMIT 1;
  FOR tid, protocol IN SELECT transaction_id, t.protocol
                       FROM Blockchain.IncludeTransaction
                       JOIN Blockchain.Transaction t ON (id = transaction_id)
                       WHERE block = bid
                       ORDER BY transaction_id LOOP
    IF (protocol = 'aut') THEN
      SELECT Blockchain.getFormattedAUT(tid) INTO partial_plaintext;
      SELECT CONCAT(plaintext, partial_plaintext, E'\n') INTO plaintext;
    ELSEIF (protocol = 'rut') THEN
      SELECT Blockchain.getFormattedRUT(tid) INTO partial_plaintext;
      SELECT CONCAT(plaintext, partial_plaintext, E'\n') INTO plaintext;
    ELSEIF (protocol = 'gct') THEN
      SELECT Blockchain.getFormattedGCT(tid) INTO partial_plaintext;
      SELECT CONCAT(plaintext, partial_plaintext, E'\n') INTO plaintext;
    ELSEIF (protocol = 'rct') THEN
      SELECT Blockchain.getFormattedRCT(tid) INTO partial_plaintext;
      SELECT CONCAT(plaintext, partial_plaintext, E'\n') INTO plaintext;
    ELSEIF (protocol = 'ccct') THEN
      SELECT string_agg(Blockchain.getFormattedCCT(cct.id), E'\n')
      INTO partial_plaintext
      FROM Blockchain.CombinedChainCollapseTransaction ccct
      JOIN Blockchain.ChainCollapseTransaction cct ON
        (start_user = invoker OR
         mid_user = invoker OR
         end_user = invoker)
      WHERE ccct.id = tid
      GROUP BY ccct.start_user, ccct.mid_user, ccct.end_user, cct.invoker
      ORDER BY CASE WHEN invoker = start_user THEN 1
                    WHEN invoker = mid_user THEN 2
                    WHEN invoker = end_user THEN 3
               END;
      SELECT CONCAT(plaintext, partial_plaintext, E'\n') INTO plaintext;
    ELSEIF (protocol = 'cpct') THEN
      SELECT string_agg(Blockchain.getFormattedPCT(pct.id), E'\n')
      INTO partial_plaintext
      FROM Blockchain.CombinedPairCancelTransaction cpct
      JOIN Blockchain.PairCancelTransaction pct ON
        (user_a = invoker OR user_b = invoker)
      WHERE cpct.id = tid
      GROUP BY cpct.user_a, cpct.user_b, pct.invoker
      ORDER BY CASE WHEN invoker = user_a THEN 1
                    WHEN invoker = user_b THEN 2
               END;
      SELECT CONCAT(plaintext, partial_plaintext, E'\n') INTO plaintext;
    END IF;
  END LOOP;
  RETURN plaintext;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.generateCurrHash(bid INT)
  RETURNS TEXT AS
  /* Generate the hash for a block*/
  $$
  BEGIN
    RETURN encode(Blockchain.digest(Blockchain.getFormattedBlock(bid),
                                    TEXT 'SHA256'),
                  'base64');
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.createTransaction(protocol VARCHAR(4))
  RETURNS INT AS
  /* Create a generic transaction

  Returns:
  The transaction_id of the newly created transaction.

  Arguments:
  protocol -- a 3-4 character protocol

  Exception:
  transaction_protocol_check
  */
  $$
  BEGIN
  INSERT INTO Blockchain.Transaction(protocol) VALUES (protocol);
  -- Obtain transaction_id
  RETURN (SELECT id FROM Blockchain.Transaction
          ORDER BY id DESC LIMIT 1);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.addAUT(new_pubk TEXT)
  RETURNS BOOLEAN AS
  /* Add a AddUserTransaction and put it into the pool.

  Arguments:
  new_pubk: public key of the user.

  Returns:
  TRUE if the transaction is added, FALSE otherwise.
  */
  $$
  DECLARE
    tid INT;
  BEGIN
    SELECT Blockchain.createTransaction('aut') INTO tid;
    INSERT INTO Blockchain.AddUserTransaction(id, join_time, user_pubk)
      VALUES (tid, NOW(), new_pubk);
    INSERT INTO Blockchain.Pool(transaction_id) VALUES (tid);
    RETURN TRUE;
  EXCEPTION
    WHEN unique_violation THEN RETURN FALSE;
    WHEN SQLSTATE '45000' THEN RETURN FALSE;
    WHEN SQLSTATE '45001' THEN RETURN FALSE;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.addRUT(user_pubk TEXT)
  RETURNS BOOLEAN AS
  /* Add a RemoveUserTransaction and put it into the pool.

  Arguments:
  user_pubk: public key of the user.

  Returns:
  TRUE if the transaction is added, FALSE otherwise.
  */
  $$
  DECLARE
    tid INT;
    _c TEXT;
  BEGIN
    SELECT Blockchain.createTransaction('rut') INTO tid;
    INSERT INTO Blockchain.RemoveUserTransaction(id, remove_time, user_pubk)
      VALUES (tid, NOW(), user_pubk);
    INSERT INTO Blockchain.Pool(transaction_id) VALUES (tid);
    RETURN TRUE;
  EXCEPTION
    WHEN unique_violation THEN RETURN FALSE;
    WHEN check_violation THEN RETURN FALSE;
    WHEN SQLSTATE '45000' THEN RETURN FALSE;
    WHEN SQLSTATE '45001' THEN RETURN FALSE;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.addGCT(
      invoker TEXT,
      transaction_time DOUBLE PRECISION, -- unix time
      receiver TEXT,
      recent_hash TEXT,
      num_cookies INT,
      reason VARCHAR(100),
      signature TEXT)
  RETURNS BOOLEAN AS
  $$
    DECLARE
      tid INT;
      bid INT;
      ttime TIMESTAMPTZ;
    BEGIN
      -- Create a generic transaction
      SELECT Blockchain.CreateTransaction('gct') INTO tid;
      -- Obtain block_id
      SELECT id INTO bid
        FROM Blockchain.Block
        WHERE curr_hash = recent_hash;
      IF (bid IS NULL) THEN RETURN FALSE;
      END IF;
      -- Convert unix time into TIMESTAMPTZ format
      SELECT to_timestamp(transaction_time) INTO ttime;
      -- Create GiveCookieTransaction
      INSERT INTO Blockchain.GiveCookieTransaction(
        id, invoker, transaction_time, receiver, recent_block,
        num_cookies, reason, signature
        ) VALUES (tid, invoker, ttime, receiver, bid, num_cookies, reason,
                  signature);
      -- Add transaction into pool
      INSERT INTO Blockchain.Pool VALUES (tid);
      RETURN TRUE;
    EXCEPTION WHEN unique_violation THEN RETURN FALSE;
              WHEN check_violation THEN RETURN FALSE;
              WHEN SQLSTATE '45000' THEN RETURN FALSE;
              WHEN SQLSTATE '45001' THEN RETURN FALSE;

  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.addRCT(
      invoker TEXT,
      transaction_time DOUBLE PRECISION,
      sender TEXT,
      recent_hash TEXT,
      num_cookies INT,
      cookie_type VARCHAR(100),
      signature TEXT)
  RETURNS BOOLEAN AS
  $$
  DECLARE
    tid INT;
    bid INT;
    ttime TIMESTAMPTZ;
  BEGIN
    -- Create a generic transaction
    SELECT Blockchain.CreateTransaction('rct') INTO tid;
    -- Obtain block_id
    SELECT id INTO bid
      FROM Blockchain.Block
      WHERE curr_hash = recent_hash;
    IF (bid IS NULL) THEN
      RETURN FALSE;
    END IF;
    -- Convert unix time into TIMESTAMPTZ format
    SELECT to_timestamp(transaction_time) INTO ttime;
    -- Create GiveCookieTransaction
    INSERT INTO Blockchain.ReceiveCookieTransaction(
      id, invoker, transaction_time, sender, recent_block,
      num_cookies, cookie_type, signature
      ) VALUES (tid, invoker, ttime, sender, bid, num_cookies, cookie_type,
                signature);
    -- Add transaction to Pool
    INSERT INTO Blockchain.Pool VALUES (tid);
    RETURN TRUE;
  EXCEPTION WHEN unique_violation THEN RETURN FALSE;
            WHEN check_violation THEN RETURN FALSE;
            WHEN SQLSTATE '45000' THEN RETURN FALSE;
            WHEN SQLSTATE '45001' THEN RETURN FALSE;

  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.addCCT(
      param_invoker TEXT,
      param_transaction_time DOUBLE PRECISION,
      param_recent_hash TEXT,
      param_start_user TEXT,
      param_mid_user TEXT,
      param_end_user TEXT,
      param_num_cookies INT,
      param_signature TEXT)
  RETURNS BOOLEAN AS
  $$
    DECLARE
      tid INT;
      bid INT;
      ttime TIMESTAMPTZ;
      ccct_id INT;
    BEGIN
      -- Create a generic transaction
      SELECT Blockchain.CreateTransaction('cct') INTO tid;
      -- Obtain block_id
      SELECT id INTO bid
        FROM Blockchain.Block
        WHERE curr_hash = param_recent_hash;
      IF (bid IS NULL) THEN
        RETURN FALSE;
      END IF;
      -- Obtain ttime in TIMESTAMPTZ format
      SELECT to_timestamp(param_transaction_time) INTO ttime;
      -- Create ChainCollapseTransaction
      INSERT INTO Blockchain.ChainCollapseTransaction(
        id, invoker, transaction_time, recent_block, signature
      ) VALUES (tid, param_invoker, ttime, bid, param_signature);
      -- Check if CombinedChainCollapseTransaction exists
      SELECT id INTO ccct_id
        FROM Blockchain.CombinedChainCollapseTransaction ccct
        JOIN Blockchain.Pool p ON (ccct.id = p.transaction_id)
        WHERE ccct.start_user = param_start_user AND
              ccct.mid_user = param_mid_user AND
              ccct.end_user = param_end_user AND
              ccct.num_cookies = param_num_cookies;
      IF (ccct_id IS NULL) THEN
        -- Create a new ccct
        SELECT Blockchain.CreateTransaction('ccct') INTO ccct_id;
        INSERT INTO Blockchain.CombinedChainCollapseTransaction (
          id, start_user, mid_user, end_user, start_user_transaction,
          mid_user_transaction, end_user_transaction, num_cookies
        ) VALUES (ccct_id, param_start_user, param_mid_user, param_end_user,
                  NULL, NULL, NULL, param_num_cookies);
        -- Insert ccct into pool
        INSERT INTO Blockchain.Pool VALUES (ccct_id);
      END IF;
      -- Update ccct
      IF (param_invoker = param_start_user) THEN
        UPDATE Blockchain.CombinedChainCollapseTransaction ccct
        SET start_user_transaction = tid
        WHERE ccct.id = ccct_id;
      ELSEIF (param_invoker = param_mid_user) THEN
        UPDATE Blockchain.CombinedChainCollapseTransaction ccct
        SET mid_user_transaction = tid
        WHERE ccct.id = ccct_id;
      ELSE
        UPDATE Blockchain.CombinedChainCollapseTransaction ccct
        SET end_user_transaction = tid
        WHERE ccct.id = ccct_id;
      END IF;
      RETURN TRUE;
    EXCEPTION
      WHEN unique_violation THEN RETURN FALSE;
      WHEN check_violation THEN RETURN FALSE;
      WHEN SQLSTATE '45000' THEN RETURN FALSE;
      WHEN SQLSTATE '45001' THEN RETURN FALSE;

    END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.addPCT(
  param_invoker TEXT,
  param_other TEXT,
  param_transaction_time DOUBLE PRECISION,
  param_recent_hash TEXT,
  param_num_cookies INT,
  param_signature TEXT)
  RETURNS BOOLEAN AS
  $$
  DECLARE
    tid INT;
    bid INT;
    ttime TIMESTAMPTZ;
    cpct_id INT;
  BEGIN
    -- Create a generic transaction
    SELECT Blockchain.createTransaction('pct') INTO tid;
    -- Obtain block_id
    SELECT id INTO bid
      FROM Blockchain.Block
      WHERE curr_hash = param_recent_hash;
    IF (bid IS NULL) THEN
      RETURN FALSE;
    END IF;
    -- Obtain ttime in TIMESTAMPTZ format
    SELECT to_timestamp(param_transaction_time) INTO ttime;
    -- Create PCT
    -- Create ChainCollapseTransaction
    INSERT INTO Blockchain.PairCancelTransaction(
      id, invoker, transaction_time, recent_block, signature
    ) VALUES (tid, param_invoker, ttime, bid, param_signature);
    -- Obtain cpct
    SELECT id INTO cpct_id
      FROM Blockchain.CombinedPairCancelTransaction cpct
      JOIN Blockchain.Pool p ON (cpct.id = p.transaction_id)
      WHERE cpct.user_a = param_other AND
            cpct.user_b = param_invoker AND
            cpct.num_cookies = param_num_cookies;
    IF (cpct_id IS NULL) THEN
      -- Create a new cpct
      SELECT Blockchain.CreateTransaction('cpct') INTO cpct_id;
      INSERT INTO Blockchain.CombinedPairCancelTransaction (
        id, user_a_transaction, user_b_transaction, user_a, user_b,
        num_cookies
      ) VALUES (cpct_id, tid, NULL, param_invoker, param_other,
                param_num_cookies);
      -- Insert cpct into the pool
      INSERT INTO Blockchain.Pool VALUES (cpct_id);
    ELSE
      -- Update the cpct
      UPDATE Blockchain.CombinedPairCancelTransaction cpct
      SET user_b_transaction = tid
      WHERE cpct.id = cpct_id;
    END IF;
    RETURN TRUE;
  EXCEPTION
    WHEN unique_violation THEN RETURN FALSE;
    WHEN check_violation THEN RETURN FALSE;
    WHEN SQLSTATE '45000' THEN RETURN FALSE;
    WHEN SQLSTATE '45001' THEN RETURN FALSE;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.executeGCT(tid INT)
  RETURNS VOID AS
  $$
  DECLARE
    invoker TEXT;
    receiver TEXT;
    num_cookies INT;
  BEGIN
    SELECT gct.invoker, gct.receiver, gct.num_cookies
      INTO invoker, receiver, num_cookies
      FROM Blockchain.GiveCookieTransaction gct
     WHERE gct.id = tid;
    -- Check again to see if the user is still valid
    IF ((SELECT Blockchain.isValidUser(invoker)) AND
        (SELECT Blockchain.IsValidUser(receiver))) THEN
      UPDATE Blockchain.Debt
         SET cookies_owed = cookies_owed + num_cookies
       WHERE sender_pubk = invoker AND receiver_pubk = receiver;
    ELSE
      RAISE EXCEPTION SQLSTATE '45001' USING
        MESSAGE = 'Users are no longer valid.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.executeRCT(tid INT)
  RETURNS VOID AS
  $$
  DECLARE
    invoker TEXT;
    sender TEXT;
    num_cookies INT;
  BEGIN
    SELECT rct.invoker, rct.sender, rct.num_cookies
      INTO invoker, sender, num_cookies
      FROM Blockchain.ReceiveCookieTransaction rct
     WHERE rct.id = tid;
    IF ((SELECT Blockchain.isValidUser(invoker)) AND
        (SELECT Blockchain.isValidUser(sender))) THEN
      IF (num_cookies <= (SELECT cookies_owed
                          FROM Blockchain.Debt
                          WHERE sender_pubk = sender AND
                          receiver_pubk = invoker)) THEN
        UPDATE Blockchain.Debt
        SET cookies_owed = cookies_owed - num_cookies
        WHERE sender_pubk = sender AND receiver_pubk = invoker;
      ELSE
        RAISE EXCEPTION SQLSTATE '45000' USING
          MESSAGE = 'Number of cookies owed is less than cookies received.';
      END IF;
    ELSE
      RAISE EXCEPTION SQLSTATE '45001' USING
        MESSAGE = 'Users no longer valid';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.executeCCCT(tid INT)
  RETURNS VOID AS
  $$
  DECLARE
    start_user TEXT;
    mid_user TEXT;
    end_user TEXT;
    num_cookies INT;
  BEGIN
    -- Check if all three candidates have signed the contract
    IF ((SELECT True
           FROM Blockchain.CombinedChainCollapseTransaction ccct
          WHERE ccct.id = tid AND
               start_user_transaction IS NOT NULL AND
               mid_user_transaction IS NOT NULL AND
               end_user_transaction IS NOT NULL)) THEN
      -- Obtain transaction information
      SELECT ccct.start_user, ccct.mid_user, ccct.end_user, ccct.num_cookies
        INTO start_user, mid_user, end_user, num_cookies
        FROM Blockchain.CombinedChainCollapseTransaction ccct
       WHERE ccct.id = tid;
      IF ((SELECT Blockchain.isValidUser(start_user)) AND
          (SELECT Blockchain.isValidUser(mid_user)) AND
          (SELECT Blockchain.isValidUser(end_user))) THEN
        -- Check that A owes B (and B owes C) enough cookies
        IF ((SELECT d1.cookies_owed >= num_cookies AND
                   d2.cookies_owed >= num_cookies
            FROM Blockchain.Debt d1, Blockchain.Debt d2
            WHERE d1.sender_pubk = start_user AND
                  d1.receiver_pubk = mid_user AND
                  d2.sender_pubk = mid_user AND
                  d2.receiver_pubk = end_user)) THEN
          -- Decrement the number of cookies A owes B
          UPDATE Blockchain.Debt
          SET cookies_owed = cookies_owed - num_cookies
          WHERE sender_pubk = start_user AND
                receiver_pubk = mid_user;
          -- Decrement the number of cookies B owes C
          UPDATE Blockchain.Debt
          SET cookies_owed = cookies_owed - num_cookies
          WHERE sender_pubk = mid_user AND
                receiver_pubk = end_user;
          -- Increment the number of cookies A owes C
          UPDATE Blockchain.Debt
          SET cookies_owed = cookies_owed + num_cookies
          WHERE sender_pubk = start_user AND
                receiver_pubk = end_user;
        ELSE
          RAISE EXCEPTION SQLSTATE '45000' USING
            MESSAGE = 'User(s) does not have enough debt.';
        END IF;
      ELSE
        RAISE EXCEPTION SQLSTATE '45001' USING
          MESSAGE = 'Users are no longer valid.';
      END IF;
    ELSE
      RAISE EXCEPTION SQLSTATE '45000' USING
        MESSAGE = 'Transaction incomplete.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.executeCPCT(tid INT)
  RETURNS VOID AS
  $$
  DECLARE
    user_a TEXT;
    user_b TEXT;
    num_cookies INT;
  BEGIN
    -- Check if both candidates have signed the contract
    IF ((SELECT True
         FROM Blockchain.CombinedPairCancelTransaction cpct
         WHERE cpct.id = tid AND
               user_a_transaction IS NOT NULL AND
               user_b_transaction IS NOT NULL)) THEN
      -- Obtain transaction information
      SELECT cpct.user_a, cpct.user_b, cpct.num_cookies
      INTO user_a, user_b, num_cookies
      FROM Blockchain.CombinedPairCancelTransaction cpct
      WHERE cpct.id = tid;
      IF ((SELECT Blockchain.isValidUser(user_a)) AND
          (SELECT Blockchain.isValidUser(user_b))) THEN
        -- Check that A owes B (and B owes A) enough cookies
        IF (SELECT d1.cookies_owed >= num_cookies AND
                   d2.cookies_owed >= num_cookies
            FROM Blockchain.Debt d1, Blockchain.Debt d2
            WHERE d1.sender_pubk = user_a AND
                  d1.receiver_pubk = user_b AND
                  d2.sender_pubk = user_b AND
                  d2.receiver_pubk = user_a) THEN
          -- Decrement the number of cookies A owes B
          UPDATE Blockchain.Debt
          SET cookies_owed = cookies_owed - num_cookies
          WHERE sender_pubk = user_a AND
                receiver_pubk = user_b;
          -- Decrement the number of cookies B owes C
          UPDATE Blockchain.Debt
          SET cookies_owed = cookies_owed - num_cookies
          WHERE sender_pubk = user_b AND
                receiver_pubk = user_a;
        ELSE
          RAISE EXCEPTION SQLSTATE '45000' USING
            MESSAGE = 'User(s) does not have enough debt.';
        END IF;
      ELSE
        RAISE EXCEPTION SQLSTATE '45001' USING
          MESSAGE = 'Users are not longer valid.';
      END IF;
    ELSE
      RAISE EXCEPTION SQLSTATE '45000' USING
        MESSAGE = 'Transaction incomplete.';
    END IF;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.executeAUT(tid INT)
  RETURNS VOID AS
  /* Add a user into the database, then add a debt record for this user
  and every other users.

  Arguments:
  tid: transaction id of the tid.
  */
  $$
  DECLARE
    new_pubk TEXT;
    other_pubk TEXT;
  BEGIN
    SELECT aut.user_pubk INTO new_pubk
      FROM Blockchain.AddUserTransaction aut
      WHERE aut.id = tid;
    -- Create User
    INSERT INTO Blockchain.CookieUser(pubk) VALUES (new_pubk);
    -- Create debts
    FOR other_pubk IN SELECT u.pubk
                      FROM Blockchain.CookieUser u
                      WHERE u.pubk != new_pubk AND u.valid LOOP
      INSERT INTO Blockchain.Debt(sender_pubk, receiver_pubk, cookies_owed)
        VALUES (other_pubk, new_pubk, 0);
      INSERT INTO Blockchain.Debt(sender_pubk, receiver_pubk, cookies_owed)
        VALUES (new_pubk, other_pubk, 0);
    END LOOP;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.executeRUT(tid INT)
  RETURNS VOID AS
  /* Remove a user from the database.

  Arguments:
  tid: transaction id of the RUT.
  */
  $$
  DECLARE
    del_user TEXT;
  BEGIN
    SELECT user_pubk INTO del_user
      FROM Blockchain.RemoveUserTransaction rut
      WHERE rut.id = tid;
    IF (del_user IN (SELECT pubk FROM Blockchain.CookieUser)) THEN
      UPDATE Blockchain.CookieUser u
        SET valid = FALSE
      WHERE u.pubk = del_user;
    ELSE
      RAISE EXCEPTION SQLSTATE '45000' USING
        MESSAGE = 'User does not exist.';
    END IF;

  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.commitBlock()
  RETURNS BOOLEAN AS
  $$
  /* Commit every transaction in the pool

  Returns:
  TRUE if a block is committed successfully, FALSE otherwise.
  */
  DECLARE
    last_hash TEXT;
    bid INT;
    protocol VARCHAR(4);
    insert_time TIMESTAMPTZ;
    tid INT;
    timeout INTERVAL := INTERVAL '12 hours';
  BEGIN

    SELECT curr_hash INTO last_hash
      FROM Blockchain.Block ORDER BY id DESC LIMIT 1;
    -- Create a new block
    INSERT INTO Blockchain.Block(prev_hash) VALUES (last_hash);
    SELECT id INTO bid
      FROM Blockchain.Block
      ORDER BY id DESC
      LIMIT 1;
    -- Add transactions to the new block if successful
    FOR insert_time, tid IN SELECT p.insert_time, transaction_id
                            FROM Blockchain.Pool p
                            ORDER BY p.insert_time LOOP
      -- Check how long the transaction has been in the pool
      IF (NOW() - insert_time > timeout) THEN
        DELETE FROM Blockchain.Pool WHERE transaction_id = tid;
        CONTINUE;
      END IF;
      -- Obtain protocol
      SELECT t.protocol INTO protocol
        FROM Blockchain.Transaction t
        WHERE t.id = tid;
      BEGIN -- Execute code based on protocol
        IF (protocol = 'gct') THEN
          PERFORM Blockchain.executeGCT(tid);
        ELSEIF (protocol = 'rct') THEN
          PERFORM Blockchain.executeRCT(tid);
        ELSEIF (protocol = 'ccct') THEN
          PERFORM Blockchain.executeCCCT(tid);
        ELSEIF (protocol = 'cpct') THEN
          PERFORM Blockchain.executeCPCT(tid);
        ELSEIF (protocol = 'aut') THEN
          PERFORM Blockchain.executeAUT(tid);
        ELSEIF (protocol = 'rut') THEN
          PERFORM Blockchain.executeRUT(tid);
        END IF;
        -- Insert transaction into the block
        INSERT INTO Blockchain.IncludeTransaction(block, transaction_id)
          VALUES (bid, tid);
        -- Remove transaction from pool
        DELETE FROM Blockchain.Pool WHERE transaction_id = tid;
      EXCEPTION
        WHEN SQLSTATE '45000' THEN
          IF (INTERVAL '12 hours' < (SELECT NOW() - p.insert_time
                                     FROM Blockchain.Pool p
                                     WHERE p.transaction_id = tid)) THEN
            DELETE FROM Blockchain.Transaction WHERE id = tid;
          END IF;
        WHEN SQLSTATE '45001' THEN -- Discard transaction
          DELETE FROM Blockchain.Transaction WHERE id = tid;
      END;
    END LOOP;
    -- Check if any transaction is submitted, rollback if none.
    IF (NOT EXISTS (SELECT * FROM Blockchain.IncludeTransaction
                WHERE block = bid)) THEN
      -- Delete created block
      DELETE FROM Blockchain.Block WHERE id = bid;
      RETURN FALSE;
    END IF;
    -- Calculate block's curr_hash
    UPDATE Blockchain.Block
      SET curr_hash = Blockchain.generateCurrHash(bid)
    WHERE id = bid;
    RETURN TRUE;
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION Blockchain.getBlockchain(last_hash TEXT)
  RETURNS TEXT AS
  /* Return all transaction ids and protocols up to "hash"

  Arguments:
  last_hash: Return blockchain information from this hash onwards.

  Returns: A string in the following format
  prev\t<prev_hash>
  t1\t
  t2\t
  ...
  tn\t
  prev\t<prev_hash>
  t1\t
  ...
  */
  $$
  DECLARE
    last_bid INT;
  BEGIN
    SELECT id INTO last_bid
      FROM Blockchain.Block
      WHERE curr_hash = last_hash;
    RETURN (SELECT string_agg(TRIM(trailing E'\n' FROM
                              Blockchain.getFormattedBlock(id)),
                              E'\n') ||
                   (SELECT E'\n' || E'head\t' || curr_hash FROM Blockchain.Block
                   ORDER BY id desc LIMIT 1)
            FROM Blockchain.Block
            WHERE id > last_bid);
  END
  $$ LANGUAGE plpgsql SECURITY DEFINER;
COMMIT;
BEGIN;
/*Revoke all privileges for MoCookie from Public*/
REVOKE ALL PRIVILEGES ON DATABASE MoCookie FROM PUBLIC;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA Blockchain FROM PUBLIC;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA Blockchain FROM PUBLIC;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA Blockchain FROM PUBLIC;

/* Grant permission on stored procedure to admin*/
GRANT CONNECT ON DATABASE MoCookie TO mc_admin;
GRANT USAGE ON SCHEMA Blockchain TO mc_admin;
GRANT EXECUTE ON FUNCTION Blockchain.addAUT(new_pubk TEXT),
                          Blockchain.addRUT(user_pubk TEXT)
              TO mc_admin;

/* Grant permission on stored procedure to server*/
GRANT CONNECT ON DATABASE MoCookie TO mc_server;
GRANT USAGE ON SCHEMA Blockchain TO mc_server;
GRANT EXECUTE ON FUNCTION Blockchain.addGCT(invoker TEXT,
                                            transaction_time DOUBLE PRECISION,
                                            receiver TEXT,
                                            recent_hash TEXT,
                                            num_cookies INT,
                                            reason VARCHAR(100),
                                            signature TEXT),
                          Blockchain.addRCT(invoker TEXT,
                                            transaction_time DOUBLE PRECISION,
                                            sender TEXT,
                                            recent_hash TEXT,
                                            num_cookies INT,
                                            cookie_type VARCHAR(100),
                                            signature TEXT),
                          Blockchain.addCCT(invoker TEXT,
                                            transaction_time DOUBLE PRECISION,
                                            recent_hash TEXT,
                                            start_user TEXT,
                                            mid_user TEXT,
                                            end_user TEXT,
                                            num_cookies INT,
                                            signature TEXT),
                          Blockchain.addPCT(invoker TEXT,
                                            other TEXT,
                                            transaction_time DOUBLE PRECISION,
                                            recent_hash TEXT,
                                            num_cookies INT,
                                            signature TEXT),
                          Blockchain.commitBlock(),
                          Blockchain.getBlockchain(last_hash TEXT)
              TO mc_server;
COMMIT;
