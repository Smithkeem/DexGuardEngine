;; DEX Fraud Detection Engine
;; A comprehensive fraud detection system for decentralized exchanges that monitors
;; trading patterns, detects suspicious activities, and implements security measures
;; to protect against manipulation, wash trading, and other fraudulent behaviors.

;; ===================================
;; CONSTANTS
;; ===================================

;; Maximum allowed transactions per block per address
(define-constant MAX-TXS-PER-BLOCK u10)

;; Minimum time between large transactions (in blocks)
(define-constant LARGE-TX-COOLDOWN u6)

;; Large transaction threshold (in microSTX)
(define-constant LARGE-TX-THRESHOLD u1000000000)

;; Maximum price deviation percentage (basis points: 500 = 5%)
(define-constant MAX-PRICE-DEVIATION u500)

;; Minimum trading volume for price manipulation check
(define-constant MIN-VOLUME-THRESHOLD u100000000)

;; Maximum wash trading score before flagging
(define-constant WASH-TRADING-THRESHOLD u75)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ADDRESS-FLAGGED (err u101))
(define-constant ERR-RATE-LIMIT-EXCEEDED (err u102))
(define-constant ERR-SUSPICIOUS-ACTIVITY (err u103))
(define-constant ERR-PRICE-MANIPULATION (err u104))

;; ===================================
;; DATA MAPS AND VARIABLES
;; ===================================

;; Contract owner for administrative functions
(define-data-var contract-owner principal tx-sender)

;; Global fraud detection status
(define-data-var fraud-detection-enabled bool true)

;; Track user transaction counts per block
(define-map user-block-activity 
    { user: principal, block-height: uint }
    { tx-count: uint, total-volume: uint }
)

;; Flagged addresses with risk scores
(define-map flagged-addresses 
    principal 
    { risk-score: uint, flagged-at: uint, reason: (string-ascii 50) }
)

;; Trading pair price history for manipulation detection
(define-map price-history 
    { token-a: principal, token-b: principal, block-height: uint }
    { price: uint, volume: uint }
)

;; Wash trading detection patterns
(define-map wash-trading-scores
    principal
    { score: uint, last-updated: uint, suspicious-pairs: uint }
)

;; ===================================
;; PRIVATE FUNCTIONS
;; ===================================

;; Calculate percentage change between two values
(define-private (calculate-percentage-change (old-value uint) (new-value uint))
    (if (is-eq old-value u0)
        u0
        (/ (* (if (> new-value old-value) 
                  (- new-value old-value)
                  (- old-value new-value)) 
              u10000) 
           old-value)
    )
)

;; Check if address is flagged
(define-private (is-address-flagged (address principal))
    (is-some (map-get? flagged-addresses address))
)

;; Get user activity for current block
(define-private (get-user-block-activity (user principal))
    (default-to 
        { tx-count: u0, total-volume: u0 }
        (map-get? user-block-activity { user: user, block-height: block-height })
    )
)

;; Update wash trading score based on trading patterns
(define-private (update-wash-trading-score (user principal) (counterparty principal) (volume uint))
    (let ((current-score (default-to { score: u0, last-updated: u0, suspicious-pairs: u0 } 
                                   (map-get? wash-trading-scores user))))
        (if (is-eq user counterparty)
            ;; Self-trading detected - high penalty
            (map-set wash-trading-scores user 
                { score: (+ (get score current-score) u50),
                  last-updated: block-height,
                  suspicious-pairs: (+ (get suspicious-pairs current-score) u1) })
            ;; Regular trading - minor score adjustment
            (map-set wash-trading-scores user 
                { score: (if (> (get score current-score) u0) 
                            (- (get score current-score) u1) 
                            u0),
                  last-updated: block-height,
                  suspicious-pairs: (get suspicious-pairs current-score) })
        )
    )
)

;; ===================================
;; PUBLIC FUNCTIONS
;; ===================================

;; Administrative function to update contract owner
(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-owner new-owner))
    )
)

;; Toggle fraud detection system
(define-public (toggle-fraud-detection)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (var-set fraud-detection-enabled (not (var-get fraud-detection-enabled))))
    )
)

;; Flag an address for suspicious activity
(define-public (flag-address (address principal) (risk-score uint) (reason (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (map-set flagged-addresses address 
            { risk-score: risk-score, flagged-at: block-height, reason: reason }))
    )
)

;; Remove address from flagged list
(define-public (unflag-address (address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (map-delete flagged-addresses address))
    )
)

;; Record trading activity and update price history
(define-public (record-trade (token-a principal) (token-b principal) 
                           (price uint) (volume uint) (counterparty principal))
    (begin
        ;; Check if fraud detection is enabled
        (asserts! (var-get fraud-detection-enabled) (ok true))
        
        ;; Check if user is flagged
        (asserts! (not (is-address-flagged tx-sender)) ERR-ADDRESS-FLAGGED)
        
        ;; Update price history
        (map-set price-history 
            { token-a: token-a, token-b: token-b, block-height: block-height }
            { price: price, volume: volume })
        
        ;; Update user block activity
        (let ((current-activity (get-user-block-activity tx-sender)))
            (map-set user-block-activity 
                { user: tx-sender, block-height: block-height }
                { tx-count: (+ (get tx-count current-activity) u1),
                  total-volume: (+ (get total-volume current-activity) volume) }))
        
        ;; Update wash trading scores
        (update-wash-trading-score tx-sender counterparty volume)
        
        (ok true)
    )
)


