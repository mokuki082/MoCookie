/* Insert genesis block */
INSERT INTO Blockchain.Block(curr_hash, prev_hash)
  VALUES ('00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
          NULL);
