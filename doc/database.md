# Database Documentation
This documentation includes a list of functions that are available to servers. The database is still in progress, test cases are needed.
## Admin Functions
### Blockchain.addAUT
Add a `AddUserTransaction` into the pool. The user will be added in the next block commit.

**Keyword Arguments**
- `new_pubk` *TEXT*: public key of the new user.

**Returns** `TRUE` if transaction is added successfully, `FALSE` otherwise.

### Blockchain.addRUT
Add a `RemoveUserTransaction` into the pool. The user will be marked as invalid after the next block commit.

**Keyword Arguments**
- `user_pubk` *TEXT*: public key of the new user.

**Returns** `TRUE` if transaction is added successfully, `FALSE` otherwise.

## Server Functions

### Blockchain.addGCT
Add a `GiveCookieTransaction` into the pool. The debt table will be updated in the next block commit.

**Keyword Arugments**
- `invoker` *TEXT*: The user who wish to give cookies.
- `transaction_time` *DOUBLE PRECISION*: The time that the user sends the transaction
- `receiver` *TEXT*: The user who will receive the cookies.
- `recent_hash` *TEXT*: The hash of any committed block (preferably recently).
- `num_cookies` *INT*: Number of cookies invoker wishes to give.
- `reason` *VARCHAR(100)*: Reason of giving the cookie (optional).
- `signature` *TEXT*: The entire transaction hashed then encrypted by the invoker's private key.

**Returns** `TRUE` if transaction is added successfully, `FALSE` otherwise.

### Blockchain.addRCT
Add a `GiveCookieTransaction` into the pool. The debt table will be updated in the next block commit.

**Keyword Arugments**
- `invoker` *TEXT*: The user who received cookies.
- `transaction_time` *DOUBLE PRECISION*: The time that the user sends the transaction
- `sender` *TEXT*: The user who gave the cookies.
- `recent_hash` *TEXT*: The hash of any committed block (preferably recently).
- `num_cookies` *INT*: Number of cookies invoker wishes to give.
- `cookie_type` *VARCHAR(100)*: Type of cookie received (optional).
- `signature` *TEXT*: The entire transaction hashed then encrypted by the invoker's private key.

**Returns** `TRUE` if transaction is added successfully, `FALSE` otherwise.

### Blockchain.addCCT
Add a `ChainCollapseTransaction` into the pool. The debt table will be updated in the next block commit.

**Keyword Arugments**
- `invoker` *TEXT*: The user who wish to give cookies.
- `transaction_time` *DOUBLE PRECISION*: The time that the user sends the transaction.
- `recent_hash` *TEXT*: The hash of any committed block (preferably recently).
- `start_user` *TEXT*: The first user in the chain.
- `mid_user` *TEXT*: The middle user in the chain.
- `end_user` *TEXT*: The end user in the chain.
- `num_cookies` *INT*: Number of cookies all three users wish to collapse.
- `signature` *TEXT*: The entire transaction hashed then encrypted by the invoker's private key.

**Returns** `TRUE` if transaction is added successfully, `FALSE` otherwise.

### Blockchain.addPCT
Add a `PairCancelTransaction` into the pool. The debt table will be updated in the next block commit.

**Keyword Arguments**
- `invoker` *TEXT*: The user who wish to give cookies.
- `other` *TEXT*: The other user whose debt to invoker will be cancelled by `num_cookies`.
- `transaction_time` *DOUBLE PRECISION*: The time that the user sends the transaction
- `recent_hash` *TEXT*: The hash of any committed block (preferably recently).
- `num_cookies` *INT*: Number of cookies all three users wish to collapse.
- `signature` *TEXT*: The entire transaction hashed then encrypted by the invoker's private key.

**Returns** `TRUE` if transaction is added successfully, `FALSE` otherwise.

### Blockchain.commitBlock
Commit all transactions from the pool into a new block. Note that unsuccessful transactions may be postponed or discarded depending on the exception. If there are no transactions in the pool, a block will not be committed.

**Returns** `TRUE` if a block is committed successfully, `FALSE` otherwise.

### Blockchain.getBlockchain
Get the blockchain information up to a certain hash.

- `last_hash` *TEXT*: Hash of a block of which the information will stop at.
