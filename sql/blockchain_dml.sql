/* Insert genesis block */
INSERT INTO Blockchain.Block(curr_hash, prev_hash)
  VALUES ('00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
          NULL);


/* Tests */
SELECT Blockchain.AddUser('a');
SELECT Blockchain.AddUser('b');
select Blockchain.addGiveCookieTransaction('a',1517649799,'b','00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',12,'love','abc');
