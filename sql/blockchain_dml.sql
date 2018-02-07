BEGIN TRANSACTION;
/* Insert genesis block */
INSERT INTO Blockchain.Block(curr_hash, prev_hash)
  VALUES ('GENESIS/BLOCK/==============================',
          NULL);
COMMIT;
