# Server API Documentation
## Notations
|Notation|Definition|
|:--:|:--:|
|`O(A,B)`|The number of cookies A owes B in the database|

## Use cases
### #1 Give cookie
**Brief Description**
A sends a `gc` transaction with various arguments to the server.
Server validates the transaction and adds it into the pool, then updates user status upon block commit.

**Actors** User A, User B.

**Actor interests** User A wishes to give User B some cookies and wants to record this.

**Trigger** A sends a `gc` transaction request.

**Related use cases** A is expected to call #5 before #1.

**Preconditions** A and B are both registered in the database. A has the latest block's hash.

**Postconditions** Transaction is either discarded, or added to the pool and committed at the next commit.

**Normal flow**
1. Receive message from A: `A_pubk|encrypted_message|certificate`.
1. Validate `certificate` using `A_pubk` and `encrypted_message`
1. Decrypt the message using the server's private key.
1. Check that the message includes these attributes in the correct format:
  - `protocol_id`: A 2 character protocol id. `gc` in this case.
  - `most_recent_hash`: Most recent block hash.
  - `B_pubk`: B's public key.
  - `num_cookies`: Number of cookies involved in the tranasaction.
  - `reason`: Reason of transaction (optional)
  - `timestamp`: Current unix time (GMT) as a decimal integer.
  - `signature`: Concatenate the above with `|` and signed by A.
1. Check that `A_pubk` is registered in the database.
1. Validate `certificate` using `A_pubk`.
1. Check that `timestamp` is later than A's most recent transaction timestamp.
1. Check that `B_pubk` is in the database.
1. Check that `O(A,C) + num_cookies <= 99`.
1. Check that `reason` is of length less than 100.
1. Add transaction to the pool.
1. Notify A that transaction is added to the pool.
1. Committer adds all the transactions from the pool to a new block.
1. A's outstanding cookies to B is incremented by `num_cookies`.
1. New block is committed.

**Alternate flow**

- Decryption failure -> discard message -> notify A (with timeout).
- Validation/format failure -> discard message -> notify A (with timeout).

---
### #2 Receive cookie
**Brief Description**
A sends a `rc` transaction with various arguments to the server.
Server validates the transaction and add it into the pool, update user status upon block commit.

**Actors** User A, User B.

**Actor interests** User A has received some real cookies from User B and wants to record this.

**Trigger** A sends a `rc` transaction request.

**Related use cases** A is expected to call #5 before #2.

**Preconditions** A and B are both registered in the database. A has the latest block's hash. B has previously owed A more than or equal to the cookies involved in this request.

**Postconditions** Invalid transactions will be discarded immediately.
A seemingly valid transaction will be added to the pool and
committed at the next commit if it is valid, otherwise it will be left in the pool for 24 hours and taken out if it is still not committed.

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
-  A's outstanding cookies to B < `num_cookies`
  - If the transaction happened more than 24 hours ago:
    1. Put the transaction into `InvalidTransaction` category.
    1. Delete transaction from the pool.
  - Otherwise, put the transaction back to the pool.

---
### #3 Chain collapse
**Brief Description**
A, B and C each sends a `bc` (big collapse) transaction with various arguments to the server.
Server validates the transactions and merge them into one.
The combined transaction `mc` (multiple collapse) will be committed if all three individuals have signed a valid `bc` transaction.

**Actors** User A, User B, User C.

**Actor Interests** User A owes user B some cookies, and user B owes user C some cookies. They wish to collapse the chain such that user A can give cookies to user C on user B's behalf.

**Trigger** A, B or C sends a `bc` transaction request.

**Related use cases** All users are expected to call #5 before #3.

**Preconditions** A, B and C are registered in the database and have the latest block's hash upon their transaction time. A owes B more than or equal to `num_cookies` and B owes C more than or equal to `num_cookies`.

**Postconditions** Invalid transactions will be discarded immediately.
A seemingly valid transaction will be added to the pool and
committed at the next commit if it is valid, otherwise it will be left in the pool for 24 hours and taken out if it is still not committed.

**Normal flow**
1. Receive message from A: `encrypted_message|certificate`.
1. Decrypt the message using the server's private key.
1. Check that the message includes these attributes in the correct format:
  - `A_pubk`
  - `protocol_id`
  - `most_recent_hash`
  - `"self"`
  - `B_pubk` (or replaced by `"self"` if transaction is sent by B)
  - `C_pubk` (or replaced by `"self"` if transaction is sent by C)
  - `num_cookies`
  - `timestamp`
1. Check that `A_pubk` is registered in the database.
1. Validate `certificate` using `A_pubk`.
1. Check that `timestamp` is later than A's most recent transaction timestamp.
1. Check that `B_pubk` and `C_pubk` are in the database.
1. Check that `num_cookies <= 99`.
1. Check that `cookie_type` is of length less than 100.
1. Check that `A_pubk` != `B_pubk` != `C_pubk`
1. Add transaction to the pool.
1. Notify A that the transaction is added to the pool.
1. Committer adds all transactions into a new block.
1. Check that A's outstanding cookies to B >= `num_cookies`.
1. Check that B's outstanding cookies to C >= `num_cookies`
1. Check whether there is a `mc` transaction in the new block with matching information.
  - If there exists such transaction:
    1. add A's signature into the transaction.
    1. If not all three users have signed, put the block back into the pool.
    1. If all three users have signed:
      1. Decrement A's outstanding cookies to B by `num_cookies`.
      2. Decrement B's outstanding cookies to C by `num_cookies`.
      3. Increment A's outstanding cookies to C by `num_cookies`.
  - Otherwise, create a `mc` transaction with all above information and A's signature, and put it back into the pool.
1. New block is committed.

**Alternate flow**
- Decryption failure -> discard message -> notify A (with timeout).
- Validation/format failure -> discard message -> notify A (with timeout)
- A's outstanding cookies to B < `num_cookies`
  - If the transaction happened more than 24 hours ago:
    1. Put the transaction into `InvalidTransaction` category.
    1. Delete transaction from the pool.
  - Otherwise, put the transaction back to the pool.
- B's outstanding cookies to C < `num_cookies`
  - If the transaction happened more than 24 hours ago:
    1. Put the transaction into `InvalidTransaction` category.
    1. Delete transaction from the pool.
  - Otherwise, put the transaction back to the pool.

___
### #4 Pair collapse
**Brief Description**
User A and B each sends a `sc` (small collapse) transaction with various arguments to the server.
Server validates the transactions and merge them into one.
The combined transaction `pc` (pair collapse) will be committed if both individuals have signed a valid `sc` transaction.

**Actors** User A, User B, User C.

**Actors Interests** User A and B wish to cancelling out the cookies they owed from each other.

**Trigger** A or B sends a `ic` transaction request.

**Related use cases** All users are expected to call #5 before #4.

**Preconditions** A and B are registered in the database and have the latest block's hash upon their transaction time. A owes B more than or equal to `num_cookies` and B owes A more than or equal to `num_cookies`.

**Postconditions** Invalid transactions will be discarded immediately.
A seemingly valid transaction will be added to the pool and
committed at the next commit if it is valid, otherwise it will be left in the pool for 24 hours and taken out if it is still not committed.

**Normal flow**
1. Receive message from A: `encrypted_message|certificate`.
1. Decrypt the message using the server's private key.
1. Check that the message includes these attributes in the correct format:
  - `A_pubk`
  - `protocol_id`
  - `most_recent_hash`
  - `"self"`
  - `B_pubk`
  - `num_cookies`
  - `timestamp`
1. Check that `A_pubk` is registered in the database.
1. Validate `certificate` using `A_pubk`.
1. Check that `timestamp` is later than A's most recent transaction timestamp.
1. Check that `B_pubk` is in the database.
1. Check that `num_cookies <= 99`.
1. Check that `cookie_type` is of length less than 100.
1. Check that `A_pubk` != `B_pubk`
1. Add transaction to the pool.
1. Notify A that the transaction is added to the pool.
1. Committer adds all transactions into a new block.
1. Check that A's outstanding cookies to B >= `num_cookies`.
1. Check that B's outstanding cookies to A >= `num_cookies`
1. Check whether there is a `pc` transaction in the new block with matching information.
  - If there exists such transaction:
    1. add A's signature into the transaction.
    1. Decrement A's outstanding cookies to B by `num_cookies`.
    1. Decrement B's outstanding cookies to C by `num_cookies`.
    1. Increment A's outstanding cookies to C by `num_cookies`.
  - Otherwise, create a `pc` transaction with all above information and A's signature, and put it back into the pool.
1. New block is committed.

**Alternate flow**
___
### #5 Get latest blockchain (up to a certain hash)
**Brief Description**


**Actors** User

**Actor Interests** User wish to validate the blockchain by themselves.

**Trigger** User sends a `lb` request to the server.

**Related use cases** None

**Preconditions** User must be registered in the database.

**Postconditions** User will receive a snapshot of the blockchain.

**Normal flow**
1. Receive a `lb` request from the user in the format `encrypted_message|certificate`
1. Decrypt the message with its private key
1. Check that the message includes:
  - `user_pubk`: User's public key
  - `protocol_id`: A 2 character protocol ID. `lb` in this case.
  - `latest_hash`: The latest hash the user has obtained previously.
1. Check that `user_pubk` is registered in the database.
1. Validate the certificate using `user_pubk`.
1.

**Alternate flow**
___
### #6 Get Invalid Transactions
___
### #7 Validate blockchain
