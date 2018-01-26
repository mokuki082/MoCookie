# Server API Documentation
## Use cases
### #1 Owe cookie

**Brief Description**
A sends a transaction with the newest block hash, B's public key, the amount of cookies A wishes to give, and the current timestamp to the server. The entire message should be encrypted and signed.

**Actors** User A, User B

**Trigger** A sends a request to the server for a give cookie transaction

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
  - `timestamp`
1. Check that `A_pubk` is registered in the database.
1. Validate `certificate` using `A_pubk`.
1. Check that `timestamp` is later than A's most recent transaction timestamp.
1. Give the arguments to a thread according to `protocol_id`.
1. Check that `B_pubk` is in the database, and `num_cookies <= 99`.
1. Add transaction to the pool.

**Alternate flow**
- Message is not in the correct format -> discard message -> notify client
- Validation failure -> discard message -> notify client

### #2 Receive cookie


### #3 Collapse a chain


### #4 Get latest blockchain (up to a certain hash)


### #5 Get Invalid Transactions


### #6 Validate blockchain
