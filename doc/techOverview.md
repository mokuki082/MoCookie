# MoCookie Technical Overview

## Goal

The goal of moCookie is to provide a centralised blockchain for a small
exclusive group to keep track of how many cookies the members owe each other.
It does not guarantee that the cookies are delivered. Blockchain and encrpytion
are used to minimise the amount of trust placed on the server, client software,
and to keep participation and knowledge of the network private. Since different
pairs in the group will place different values on cookies, each pair is
considered seperately and no net counters are used.

## Cryptographic Trust

The server will have a set private key, and the blockchain will contain the
public keys of all members of the group. Physically or through a secure
connection, users will give the server administrator their public key and
receive the server's public key, and are free to exchange public keys with
other members of the group to verify they hold the correct ones, or to attach
nicknames to the key.

Every message received by the server will be encrypted with the server's public
key and signed with a user's private key, and every message sent by the server
will be encrypted with the user's public key and signed with the server's
private key. This prevents the network from being viewed or altered by
outsiders.

Furthermore, the blockchain will be accessible by all members of the group to
verify. This prevents the server's administrators from having any more control
over the network than any other user, as any changes made to the blockchain
they make or any transactions made by outsiders will be obvious to users.

## The Blockchain

The blockchain consists of blocks containing transactions. Blocks are uniquely
identified by their hash, and contain the hash of the previous block and a
series of transactions from within a twelve hour window.

In general, a transaction will contain details specific to the transaction,
as well as the hash of a block verified by the user, a timestamp, and a
signature. By including the hash of a recent block, we guarantee that the
transaction is only used on the blockchain that user is familiar with. By
including a timestamp, transactions cannot be used in the blockchain twice
or delayed to the point that the user re-sends the transaction resulting in
doubling up.

The signature will be the concatenation of all transaction details the signing
user has access to, with tab seperators, hashed, and then encrypted with the
user's private key. This allows the transaction to be verified as being from
that user, as the transaction can be hashed and the signature decrypted with
the user's public key, resulting in the same hash for genuine transactions.

### Transaction: Give Cookie

If Alice believes she owes Bob a cookie but cannot give him one immediately,
she can submit a transaction to the server to record this. The transaction
will contain

- An identifier that this transaction is to give cookies
- Alice's public key as the person owing cookies
- Bob's public key as the person owed cookies
- The hash of a block that Alice has verified
- A number of cookies, an integer between 1 and 99 inclusive
- An ascii string of at most 100 characters, possibly stating why the cookie
is owed
- A timestamp, the current unix time (GMT) as a decimal integer
- A signature, the result of concatenating the above with tab seperators,
hashing that, and encrpyting the hash with Alice's private key

After the transaction has entered the blockchain, the amount of cookies Alice
owes Bob will increase by the number stated in the transaction.

### Transaction: Receive Cookie

If the blockchain owes that Alice owes Bob some number of cookies and is
giving him cookies, Bob should submit a transaction to the server to record
this. The transaction will contain

- An identifier that this transaction is to receive cookies
- Alice's public key as the person giving cookies
- Bob's public key as the person receiving cookies
- The hash of a block that Bob has verified
- A number of cookies, an integer between 1 and 99 inclusive, which is less
than or equal to the number of cookies Alice owes Bob
- An ascii string of at most 100 characters, possibly the type of cookie given
- A timestamp, the current unix time (GMT) as a decimal integer
- A signature, the result of concatenating the above with tab seperators,
hashing that, and encrypting the hash with Bob's private key

After the transaction has entered the blockchain, the amount of cookies Alice
owes Bob will decrease by the number stated in the transaction, and will not
be negative otherwise the transaction was invalid.

### Transaction: Chain Collapse

If Alice owes Bob some cookies and Bob owes Charlie some cookies, and it is
for some reason inconvenient to actually exchange cookies with Bob, the three
may all submit details to create a transaction so that instead Alice owes
Charlie cookies. The transactions will contain

- An identifier that this transaction is to collapse a chain
- A number of cookies, an integer between 1 and 99 inclusive, which is less
than or equal ot the number of cookies Alice owes Bob and less than or equal
to the number of cookies Bob owes Charlie
- For each user Alice, Bob and Charlie:
  - The public key of that user
  - The hash of a block that user has verified
  - The time that user signed, as a decimal integer of unix time (GMT)
  - A signature, the result of concatenating the above, including the public
  keys of other users and not their block hashes nor timestamps, with tab
  seperators, hashed, and encrypted with the user's private key

This transaction includes three timestamps, and all three must be within the
same 12 hour window as every other transaction in the same block. Once all
three users have submitted details to the server the transaction can be
completed. Once the complete transaction has entered the blockchain, the
amount of cookies Alice owes Bob will decrease by the number stated in the
transaction, the amount Bob owes Charlie will decrease similarly, and the
amount Alice owes Charlie will increase by the number stated in the
transaction. No person will owe anyone else negative cookies, otherwise the
transaction was invalid. Note that all three people sign slightly different
details, so the hashes are different.

### Transaction: Pair Cancel

If Alice and Bob both owe each other some cookies and would like to easily
cancel this out, they can both submit transactions to achieve this. The
transactions will contain

- An identifier that this transaction is to cancel a pair's cookies
- A number of cookies, an integer between 1 and 99 inclusive, which is less
than or equal to the amount of cookies Alice owes Bob and less than or equal to
the amount Bob owes Alice
- For each user Alice and Bob:
  - The public key of that user
  - The hash of a block that user has verified
  - The time that user signed, as a decimal integer of unix time (GMT)
  - A signature, the result of concatenating the above, including the public
  keys of other users and not their block hashes nor timestamps, with tab
  seperators, hashed, and encrypted with the user's private key

This transaction includes two timestamps, and both must be within the same 12
hour window as every other transaction in the same block. Once both users have
submitted details to the server the transaction can be completed. Once the
complete transaction has entered the blockchain, the amount of cookies Alice
owes Bob will decrease by the number stated in the transaction, and the number
Bob owes Alice will decrease similarly. No person will owe anyone else negative
cookies, otherwise the transaction was invalid. Note that both people sign
slightly different details, so the hashes are different.

### Transaction: Add User

At the start of the blockchain, or when any user joins the group, their public
key will be included in a transaction. This transaction contains

- An identifier that this transaction is to add a user
- A timestamp, the current unix time (GMT) as a decimal integer
- The public key of the new user

After the transaction enters the blockchain, the user can be involved in
transactions later than the included timestamp. Users verifying the blockchain
should be prompted to either confirm the key included in the transaction seems
correct, or wait for another user to use the hash from this or a later block
in a transaction showing they have verified the user.

### Transaction: Remove User

When a user chooses to leave the network, or if their private key is leaked,
this transaction is included to cease their activity in the group. This
transaction contains

- An identifier that this transaction is to remove a user
- A timestamp, the current unix time (GMT) as a decimal integer
- The public key of the leaving user

After the transaction enters the blockchain, any cookie debt involving the user
is irrelevant, and no future transactions may involve this user. Users
verifying the blockchain should be prompted to either confirm the transaction
is appropriate, or wait for another user to use the hash from this or a later
block in a transaction showing they deem it appropriate.

<!-- ### Building the Blockchain

As the server receives transactions from users, it will check if each is
legitimate. This involves

- Checking the transaction identifier and number of provided values match
- Checking the public keys match authorised users
- Verifying the signature
- Checking the timestamp is from the last 12 hours
- Checking this combination of sender and timestamp is not in the blockchain or
pool, which only requires checking transactions from the last 12 hours
- Checking the included hash is from this blockchain
- Checking the values are within the allowed range
- Checking exactly one public key in a chain collapse transaction was replaced
with the word self

A legitimate transaction can then be added to the pool of all legitimate
transactions from the last 12 hours.

Whenever new transactions are added to the pool, the server will check which in
the pool are valid. A subset of transactions in the pool are valid if

- They are all legitimate, which should have been checked already
- Their timestamps span at most 12 hours
- All Chain Collapse and Pair Cancel transactions have exactly one matching
transaction in this subset for each involved member
- The result of putting the entire subset into a block will result in a person
owing person negative cookies

Once a non-empty subset of transactions in the pool is valid, those
transactions can be put into a block. The block will consist of the hash of
the previous block, a list of transactions, and will be uniquely identified by
its hash.

If two transactions cannot be put into the same block, the earlier transaction
will be preferred.

## Communication

All communication will be using TCP, to prevent amplification attacks, and be
in the form of requests from clients and responses from the server, all
encrypted and the encrypted message signed. This allows the message to be
verified before it is decrypted, as decryption takes time.

### Requests

Every request the user sends will consist of the user's public key, to identify
them, a message encrypted using the server's public key, and the hash of the
encrypted message encrypted using the user's private key. When the server
receives a request, it can check the public key matches one of its users,
check the message is signed by decrypting the hash and hashing the encrypted
message to see if they match, and then decrypt the message.
-->
