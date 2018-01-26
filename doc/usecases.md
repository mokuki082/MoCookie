# Server API Documentation
## Use cases
### #1 Give cookie

**Brief Description**
A sends a `gc` transaction with various arguments to the server.
Server validates the transaction and add it into the pool.

**Actors** User A, User B.

**Trigger** A sends a `gc` transaction request.

**Related use cases** A is expected to call #4 before #1.

**Preconditions** A and B are both registered in the database. A has the latest block's hash.

**Postconditions** Transaction is either discarded or added to the pool.

**Normal flow**
1. Receive message from A: `encrypted_message|certificate`.
1. Decrypt the message using the server's private key.
1. Check that the message includes these attributes in the correct format:
  - `A_pubk`
  - `protocol_id`
  - `most_recent_hash`
  - `B_pubk`
  - `num_cookies`
  - `reason`
  - `timestamp`
1. Check that `A_pubk` is registered in the database.
1. Validate `certificate` using `A_pubk`.
1. Check that `timestamp` is later than A's most recent transaction timestamp.
1. Check that `B_pubk` is in the database.
1. Check that `num_cookies <= 99`.
1. Check that `reason` is of length less than 100.
1. Add transaction to the pool.
1. Notify A that transaction is added to the pool.
1. Committer adds all the transactions from the pool to a new block.
1. A's outstanding cookies to B is incremented by `num_cookies`.
1. New block is committed.

**Alternate flow**

- Decryption failure -> discard message -> notify A (with timeout).
- Validation/format failure -> discard message -> notify A (with timeout).

### #2 Receive cookie

**Brief Description**
A sends a `rc` transaction with various arguments to the server.
Server validates the transaction and add it into the pool.

**Actors** User A, User B.

**Trigger** A sends a `rc` transaction request.

**Related use cases** A is expected to call #4 before #1.

**Preconditions** A and B are both registered in the database. A has the latest block's hash. B has previously owed A more than or equal to the cookies involved in this request.

**Postconditions** Transaction is either discarded or added to the pool.

**Normal flow**
1. Receive message from A: `encrypted_message|certificate`.
1. Decrypt the message using the server's private key.
1. Check that the message includes these attributes in the correct format:
  - `A_pubk`
  - `protocol_id`
  - `most_recent_hash`
  - `B_pubk`
  - `num_cookies`
  - `cookie_type`
  - `timestamp`
1. Check that `A_pubk` is registered in the database.
1. Validate `certificate` using `A_pubk`.
1. Check that `timestamp` is later than A's most recent transaction timestamp.
1. Check that `B_pubk` is in the database.
1. Check that `num_cookies <= 99`.
1. Check that `cookie_type` is of length less than 100.
1. Add transaction to the pool.
1. Notify A that the transaction is added to the pool.
1. Committer adds all transactions from the pool to a new block.
1. Check that A's outstanding cookies to B >= `num_cookies`.
1. A's outstanding cookies to B is decremented by `num_cookies`.
1. New block is committed.

**Alternate flow**
- Decryption failure -> discard message -> notify A (with timeout).
- Validation/format failure -> discard message -> notify A (with timeout)
-  A's outstanding cookies < `num_cookies`
  - If the transaction happened more than 24 hours ago:
    1. Put the transaction into `InvalidTransaction` category.
    1. Delete transaction from the pool.
  - Otherwise, put the transaction back to the pool.

### #3 Collapse a chain


### #4 Get latest blockchain (up to a certain hash)


### #5 Get Invalid Transactions


### #6 Validate blockchain
