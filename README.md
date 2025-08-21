🛡️ DexGuardEngine 🛡️
======================

A comprehensive, on-chain fraud detection system for decentralized exchanges built on Clarity. DexGuardEngine monitors trading patterns, detects suspicious activities, and implements security measures to protect against common DeFi exploits such as wash trading, price manipulation, and front-running. This contract is designed to be integrated directly into DEX smart contracts, providing a real-time, decentralized security layer.

* * * * *

🚀 Features
-----------

DexGuardEngine provides a multi-faceted approach to fraud detection, including:

-   **Rate Limiting:** Prevents a single address from overwhelming the network with an excessive number of transactions in a short period.

-   **Large Transaction Monitoring:** Flags unusually large transactions that could indicate a market manipulation attempt or a potential exploit.

-   **Wash Trading Detection:** Analyzes trading patterns between addresses, assigning a risk score based on suspicious behaviors like self-trading.

-   **Price Manipulation Analysis:** Compares current trade prices against historical data, flagging significant price deviations, especially in high-volume trades.

-   **Suspicious Frequency Analysis:** Identifies a pattern of multiple small trades from a single user that could be used to manipulate data or front-run other transactions.

-   **Dynamic Risk Scoring:** Aggregates various risk factors into a single, quantifiable risk score, providing a clear assessment of a transaction's legitimacy.

-   **Administrative Controls:** Provides a contract owner with the ability to enable/disable the engine and manually flag or unflag addresses.

* * * * *

🛠️ Getting Started
-------------------

### Prerequisites

To interact with this contract, you will need:

-   A Stacks wallet (e.g., Leather, Xverse).

-   The `clarity-cli` for local testing.

-   The Stacks blockchain development environment.

### Deployment

This contract can be deployed to the Stacks network. You will need to use a contract deployment tool like `clarity-cli` or a web-based IDE that supports Clarity.

Bash

```
# Example using clarity-cli
clarity-cli deploy <path_to_contract>/dex-fraud-detection.clar

```

### Integration

To integrate `DexGuardEngine` into your DEX, call the `record-trade` and `analyze-fraud-risk` public functions from your core trading logic.

#### Example Integration

Code snippet

```
(define-public (my-dex-swap (token-a principal) (token-b principal) (amount-in uint))
  (begin
    ;; First, perform the core swap logic
    ;; ...

    ;; Then, record the trade with the fraud engine
    (ok (contract-call? 'SPX...DexGuardEngine.record-trade
      token-a
      token-b
      (get 'price my-trade-data)
      (get 'volume my-trade-data)
      (get 'counterparty my-trade-data)
    ))

    ;; Finally, analyze the risk for the transaction
    (let ((risk-analysis (try! (contract-call? 'SPX...DexGuardEngine.analyze-fraud-risk
      tx-sender
      token-a
      token-b
      (get 'volume my-trade-data)
      (get 'price my-trade-data)
    ))))
      (if (is-eq (get 'recommendation risk-analysis) "BLOCK_TRANSACTION")
        (err ERR-BLOCKED-BY-FRAUD-ENGINE)
        (ok true)))
  )
)

```

* * * * *

📄 API Reference
----------------

### Public Functions

#### `set-contract-owner`

**Signature:** `(set-contract-owner (new-owner principal))` **Description:** Sets the new contract owner. Only callable by the current owner. **Returns:** `(ok true)` on success, `ERR-NOT-AUTHORIZED` on failure.

#### `toggle-fraud-detection`

**Signature:** `(toggle-fraud-detection)` **Description:** Toggles the `fraud-detection-enabled` flag, turning the engine on or off. **Returns:** `(ok true)` on success, `ERR-NOT-AUTHORIZED` on failure.

#### `flag-address`

**Signature:** `(flag-address (address principal) (risk-score uint) (reason (string-ascii 50)))` **Description:** Manually flags a suspicious address with a risk score and reason. **Returns:** `(ok true)` on success, `ERR-NOT-AUTHORIZED` on failure.

#### `unflag-address`

**Signature:** `(unflag-address (address principal))` **Description:** Removes an address from the flagged list. **Returns:** `(ok true)` on success, `ERR-NOT-AUTHORIZED` on failure.

#### `record-trade`

**Signature:** `(record-trade (token-a principal) (token-b principal) (price uint) (volume uint) (counterparty principal))` **Description:** Records a trade event, updating user activity, price history, and wash trading scores. This function should be called with every successful trade. **Returns:** `(ok true)` on success, `ERR-ADDRESS-FLAGGED` if the sender is flagged.

#### `analyze-fraud-risk`

**Signature:** `(analyze-fraud-risk (user principal) (token-a principal) (token-b principal) (trade-volume uint) (trade-price uint))` **Description:** Performs a comprehensive analysis of a user's trading activity and returns a detailed fraud assessment. **Returns:** `(ok { ... })` with a detailed risk report.

* * * * *

### Private Functions

#### `calculate-percentage-change`

**Signature:** `(calculate-percentage-change (old-value uint) (new-value uint))` **Description:** A helper function to compute the percentage change between two values. **Returns:** `uint` representing the change in basis points.

#### `is-address-flagged`

**Signature:** `(is-address-flagged (address principal))` **Description:** Checks if a given address is present in the `flagged-addresses` map. **Returns:** `bool` (`true` if flagged, `false` otherwise).

#### `get-user-block-activity`

**Signature:** `(get-user-block-activity (user principal))` **Description:** Retrieves a user's transaction count and total volume for the current block. **Returns:** `(tuple { tx-count: uint, total-volume: uint })`

#### `update-wash-trading-score`

**Signature:** `(update-wash-trading-score (user principal) (counterparty principal) (volume uint))` **Description:** Adjusts the wash trading score for a user based on their counterparty. Self-trading increases the score significantly. **Returns:** `(ok true)`.

* * * * *

📊 Data Structures
------------------

-   `user-block-activity` (map): Tracks the number of transactions and total volume per user per block.

-   `flagged-addresses` (map): Stores a list of addresses that have been flagged, along with their risk scores and reasons.

-   `price-history` (map): Maintains a history of prices and volumes for trading pairs, used for price manipulation detection.

-   `wash-trading-scores` (map): Assigns and updates a wash trading score for each address based on trading patterns.

* * * * *

🚧 Error Codes
--------------

-   `u100`: `ERR-NOT-AUTHORIZED` - The transaction sender is not the contract owner.

-   `u101`: `ERR-ADDRESS-FLAGGED` - The transaction sender has been flagged for suspicious activity.

-   `u102`: `ERR-RATE-LIMIT-EXCEEDED` - The user has exceeded the transaction rate limit.

-   `u103`: `ERR-SUSPICIOUS-ACTIVITY` - The transaction exhibits suspicious patterns.

-   `u104`: `ERR-PRICE-MANIPULATION` - The transaction is suspected of attempting price manipulation.

* * * * *

📝 Contribution
---------------

We welcome contributions! If you have suggestions for improvements, bug fixes, or new features, please submit a pull request or open an issue on the GitHub repository.

* * * * *

⚖️ License
----------

This project is licensed under the MIT License. See the `LICENSE` file for details.

![profile picture](https://lh3.googleusercontent.com/a/ACg8ocJ_vsw7TaCCeMuQ9lczLCzqs47IOD2H_aUfBxy6CgG3iFhEGtMA=s64-c)
