# Server Documentation
This documentation includes a list of protocols clients may use to communicate with the server.

## Protocols
Tab `\t` is used as the separator between protocol variables. For the sake of readability, all tabs shown here are replaced by space.

### Give Cookie Transaction
`gct invoker ttime receiver recent_hash num_cookies reason signature`
- `invoker`: invoker public key.
- `ttime`: timestamp in unix time format (integer)
- `receiver`: receiver public key.
- `recent_hash`: Any committed block's hash, preferably recent ones.
- `num_cookies`: number of cookies invoker wishes to give.
- `reason`: reason for this transaction, optional. (max-len:100)
- `signature`: `gct invoker ttime receiver recent_hash num_cookies reason` hashed by SHA512 then signed using invoker's private key.

### Receive Cookie Transaction
`rct invoker ttime receiver recent_hash num_cookies cookie_type signature`
- `invoker`: invoker public key.
- `ttime`: timestamp in unix time format (integer)
- `sender`: Sender's public key
- `recent_hash`: Any committed block's hash, preferably recent ones.
- `num_cookies`: number of cookies invoker wishes to give.
- `cookie_type`: Type of cookies received, optional. (max-len:100)
- `signature`: `rct invoker ttime receiver recent_hash num_cookies cookie_type signature` hashed by SHA512 then signed using invoker's private key.

### Chain Collapse Transaction
`cct invoker ttime recent_hash start_user mid_user end_user num_cookies signature`
- `invoker`: invoker public key.
- `ttime`: timestamp in unix time format (integer)
- `recent_hash`: Any committed block's hash, preferably recent ones.
- `start_user`: start user's public key
- `mid_user`: Middle user's public key
- `end_user`: End user's public key
- `num_cookies`: number of cookies involvers wish to collapse.
- `signature`: `cct invoker ttime recent_hash start_user mid_user end_user num_cookies` hashed by SHA512 then signed using invoker's private key.

### Pair Cancel Transaction
`pct invoker other ttime recent_hash num_cookies signature`
- `invoker`: invoker public key.
- `other`: other user's public key
- `ttime`: timestamp in unix time format (integer)
- `recent_hash`: Any committed block's hash, preferably recent ones.
- `num_cookies`: number of cookies involvers wish to collapse.
- `signature`: `pct invoker other ttime recent_hash num_cookies` hashed by SHA512 then signed using invoker's private key.

### Get Blockchain
`gbc hash`
- `hash`: The most recent block hash that the client already have.
