;; title: Green Hash Credits - Sustainable Bitcoin Mining Token
;; version: 1.0.0
;; summary: Tokenized green Bitcoin mining credits representing verified renewable energy hash power
;; description: A fungible token that represents verified green Bitcoin mining capacity,
;;              allowing trading and redemption of sustainable mining services

;; traits
;; SIP-010 compliant fungible token

;; token definitions
(define-fungible-token green-hash-credits)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_MINER_NOT_VERIFIED (err u103))
(define-constant ERR_ALREADY_VERIFIED (err u104))
(define-constant ERR_INVALID_HASH_POWER (err u105))
(define-constant ERR_CREDIT_NOT_FOUND (err u106))
(define-constant ERR_ALREADY_REDEEMED (err u107))
(define-constant ERR_CREDIT_EXPIRED (err u108))
(define-constant TOKEN_NAME "Green Hash Credits")
(define-constant TOKEN_SYMBOL "GHC")
(define-constant TOKEN_DECIMALS u6)
(define-constant MAX_SUPPLY u1000000000000) ;; 1 million GHC with 6 decimals
(define-constant DEFAULT_CREDIT_EXPIRY_BLOCKS u144) ;; ~24 hours in blocks (assuming 10min blocks)

;; data vars
(define-data-var total-supply uint u0)
(define-data-var contract-paused bool false)
(define-data-var credit-expiry-blocks uint DEFAULT_CREDIT_EXPIRY_BLOCKS)

;; data maps
(define-map verified-miners
    principal
    {
        hash-power: uint,
        renewable-energy-source: (string-ascii 100),
        verification-date: uint,
        verified: bool,
    }
)

(define-map verifiers
    principal
    bool
)

(define-map mining-credits
    uint
    {
        miner: principal,
        hash-power: uint,
        energy-source: (string-ascii 100),
        issued-date: uint,
        expiry-date: uint,
        redeemed: bool,
        redeemed-by: (optional principal),
        redemption-date: (optional uint),
    }
)

(define-data-var next-credit-id uint u1)
(define-data-var next-history-id uint u1)

;; Miner history tracking
(define-map miner-verification-history
    uint
    {
        miner: principal,
        verifier: principal,
        hash-power: uint,
        energy-source: (string-ascii 100),
        verification-date: uint,
        action: (string-ascii 50), ;; "verified" or "updated"
    }
)

(define-map miner-redemption-history
    uint
    {
        miner: principal,
        redeemer: principal,
        credit-id: uint,
        amount: uint,
        redemption-date: uint,
    }
)

;; Dynamic energy sources
(define-map approved-energy-sources
    (string-ascii 100)
    bool
)

;; SIP-010 Standard Functions
(define-public (transfer
        (amount uint)
        (from principal)
        (to principal)
        (memo (optional (buff 34)))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (is-eq tx-sender from) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq to 'SP000000000000000000002Q6VF78)) ERR_UNAUTHORIZED) ;; prevent burn address transfers
        (try! (ft-transfer? green-hash-credits amount from to))
        (match memo
            to-print (print to-print)
            0x
        )
        (ok true)
    )
)

(define-read-only (get-name)
    (ok TOKEN_NAME)
)

(define-read-only (get-symbol)
    (ok TOKEN_SYMBOL)
)

(define-read-only (get-decimals)
    (ok TOKEN_DECIMALS)
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance green-hash-credits who))
)

(define-read-only (get-total-supply)
    (ok (var-get total-supply))
)

(define-read-only (get-token-uri)
    (ok (some u"https://greenbitcoin.org/token-metadata.json"))
)

;; Administrative Functions
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq verifier 'SP000000000000000000002Q6VF78)) ERR_UNAUTHORIZED) ;; prevent burn address
        (asserts! (not (is-eq verifier CONTRACT_OWNER)) ERR_UNAUTHORIZED) ;; prevent duplicate owner
        (map-set verifiers verifier true)
        (ok true)
    )
)

(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq verifier CONTRACT_OWNER)) ERR_UNAUTHORIZED) ;; prevent removing owner
        (asserts! (is-some (map-get? verifiers verifier)) ERR_MINER_NOT_VERIFIED) ;; ensure verifier exists
        (map-delete verifiers verifier)
        (ok true)
    )
)

(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set contract-paused false)
        (ok true)
    )
)

;; Miner Verification Functions
(define-public (verify-miner
        (miner principal)
        (hash-power uint)
        (energy-source (string-ascii 100))
    )
    (begin
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (default-to false (map-get? verifiers tx-sender))
            ERR_UNAUTHORIZED
        )
        (asserts! (> hash-power u0) ERR_INVALID_HASH_POWER)
        (asserts! (is-none (map-get? verified-miners miner)) ERR_ALREADY_VERIFIED)
        (asserts! (is-valid-energy-source energy-source) ERR_INVALID_AMOUNT)

        (map-set verified-miners miner {
            hash-power: hash-power,
            renewable-energy-source: energy-source,
            verification-date: stacks-block-height,
            verified: true,
        })

        ;; Record verification history
        (let ((history-id (var-get next-history-id)))
            (map-set miner-verification-history history-id {
                miner: miner,
                verifier: tx-sender,
                hash-power: hash-power,
                energy-source: energy-source,
                verification-date: stacks-block-height,
                action: "verified",
            })
            (var-set next-history-id (+ history-id u1))
        )

        (print {
            event: "miner-verified",
            miner: miner,
            hash-power: hash-power,
            energy-source: energy-source,
            block-height: stacks-block-height,
        })

        (ok true)
    )
)

(define-public (update-miner-hash-power
        (miner principal)
        (new-hash-power uint)
    )
    (let ((miner-data (unwrap! (map-get? verified-miners miner) ERR_MINER_NOT_VERIFIED)))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (default-to false (map-get? verifiers tx-sender))
            ERR_UNAUTHORIZED
        )
        (asserts! (> new-hash-power u0) ERR_INVALID_HASH_POWER)
        (asserts! (not (is-eq miner 'SP000000000000000000002Q6VF78)) ERR_UNAUTHORIZED) ;; prevent burn address

        (map-set verified-miners miner
            (merge miner-data { hash-power: new-hash-power })
        )

        ;; Record hash power update history
        (let ((history-id (var-get next-history-id)))
            (map-set miner-verification-history history-id {
                miner: miner,
                verifier: tx-sender,
                hash-power: new-hash-power,
                energy-source: (get renewable-energy-source miner-data),
                verification-date: stacks-block-height,
                action: "updated",
            })
            (var-set next-history-id (+ history-id u1))
        )

        (print {
            event: "hash-power-updated",
            miner: miner,
            new-hash-power: new-hash-power,
            block-height: stacks-block-height,
        })

        (ok true)
    )
)

;; Credit Issuance Functions
(define-public (issue-credits
        (miner principal)
        (credit-amount uint)
    )
    (let (
            (miner-data (unwrap! (map-get? verified-miners miner) ERR_MINER_NOT_VERIFIED))
            (credit-id (var-get next-credit-id))
            (new-total-supply (+ (var-get total-supply) credit-amount))
        )
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (default-to false (map-get? verifiers tx-sender))
            ERR_UNAUTHORIZED
        )
        (asserts! (> credit-amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= new-total-supply MAX_SUPPLY) ERR_INVALID_AMOUNT)
        (asserts! (not (is-eq miner 'SP000000000000000000002Q6VF78)) ERR_UNAUTHORIZED) ;; prevent burn address

        (try! (ft-mint? green-hash-credits credit-amount miner))
        (var-set total-supply new-total-supply)

        (map-set mining-credits credit-id {
            miner: miner,
            hash-power: (get hash-power miner-data),
            energy-source: (get renewable-energy-source miner-data),
            issued-date: stacks-block-height,
            expiry-date: (+ stacks-block-height (var-get credit-expiry-blocks)),
            redeemed: false,
            redeemed-by: none,
            redemption-date: none,
        })

        (var-set next-credit-id (+ credit-id u1))

        (print {
            event: "credits-issued",
            miner: miner,
            amount: credit-amount,
            credit-id: credit-id,
            block-height: stacks-block-height,
        })

        (ok credit-id)
    )
)

;; Credit Redemption Functions
(define-public (redeem-credits
        (credit-id uint)
        (amount uint)
    )
    (let ((credit-data (unwrap! (map-get? mining-credits credit-id) ERR_CREDIT_NOT_FOUND)))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (not (get redeemed credit-data)) ERR_ALREADY_REDEEMED)
        (asserts! (<= stacks-block-height (get expiry-date credit-data)) ERR_CREDIT_EXPIRED)
        (asserts! (>= (ft-get-balance green-hash-credits tx-sender) amount)
            ERR_INSUFFICIENT_BALANCE
        )

        (try! (ft-burn? green-hash-credits amount tx-sender))
        (var-set total-supply (- (var-get total-supply) amount))

        (map-set mining-credits credit-id
            (merge credit-data {
                redeemed: true,
                redeemed-by: (some tx-sender),
                redemption-date: (some stacks-block-height),
            })
        )

        ;; Record redemption history
        (let ((history-id (var-get next-history-id)))
            (map-set miner-redemption-history history-id {
                miner: (get miner credit-data),
                redeemer: tx-sender,
                credit-id: credit-id,
                amount: amount,
                redemption-date: stacks-block-height,
            })
            (var-set next-history-id (+ history-id u1))
        )

        (print {
            event: "credits-redeemed",
            redeemer: tx-sender,
            amount: amount,
            credit-id: credit-id,
            original-miner: (get miner credit-data),
            block-height: stacks-block-height,
        })

        (ok true)
    )
)

;; Read-only functions
(define-read-only (is-verified-miner (miner principal))
    (default-to false (get verified (map-get? verified-miners miner)))
)

(define-read-only (get-miner-info (miner principal))
    (map-get? verified-miners miner)
)

(define-read-only (is-verifier (account principal))
    (default-to false (map-get? verifiers account))
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

(define-read-only (get-credit-info (credit-id uint))
    (map-get? mining-credits credit-id)
)

(define-read-only (get-next-credit-id)
    (var-get next-credit-id)
)

(define-read-only (calculate-mining-reward
        (hash-power uint)
        (duration uint)
    )
    (* hash-power duration)
)

(define-read-only (is-credit-expired (credit-id uint))
    (match (map-get? mining-credits credit-id)
        credit-data (> stacks-block-height (get expiry-date credit-data))
        false
    )
)

(define-read-only (get-credit-expiry-blocks)
    (var-get credit-expiry-blocks)
)

;; History query functions
(define-read-only (get-verification-history (history-id uint))
    (map-get? miner-verification-history history-id)
)

(define-read-only (get-redemption-history (history-id uint))
    (map-get? miner-redemption-history history-id)
)

(define-read-only (get-next-history-id)
    (var-get next-history-id)
)

(define-read-only (is-energy-source-approved (energy-source (string-ascii 100)))
    (default-to false (map-get? approved-energy-sources energy-source))
)

(define-public (set-credit-expiry-blocks (new-expiry-blocks uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (> new-expiry-blocks u0) ERR_INVALID_AMOUNT)
        (var-set credit-expiry-blocks new-expiry-blocks)
        (print {
            event: "expiry-blocks-updated",
            new-expiry-blocks: new-expiry-blocks,
            block-height: stacks-block-height,
        })
        (ok true)
    )
)

(define-public (cleanup-expired-credit (credit-id uint))
    (let ((credit-data (unwrap! (map-get? mining-credits credit-id) ERR_CREDIT_NOT_FOUND)))
        (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
        (asserts! (> stacks-block-height (get expiry-date credit-data)) ERR_INVALID_AMOUNT)
        (asserts! (not (get redeemed credit-data)) ERR_ALREADY_REDEEMED)
        
        (map-delete mining-credits credit-id)
        
        (print {
            event: "expired-credit-cleaned",
            credit-id: credit-id,
            original-miner: (get miner credit-data),
            expired-at: (get expiry-date credit-data),
            block-height: stacks-block-height,
        })
        
        (ok true)
    )
)

;; Energy Source Management Functions
(define-public (add-energy-source (energy-source (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-valid-string energy-source) ERR_INVALID_AMOUNT)
        (asserts! (is-none (map-get? approved-energy-sources energy-source)) ERR_ALREADY_VERIFIED) ;; prevent duplicates
        (map-set approved-energy-sources energy-source true)
        (print {
            event: "energy-source-added",
            energy-source: energy-source,
            block-height: stacks-block-height,
        })
        (ok true)
    )
)

(define-public (remove-energy-source (energy-source (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-valid-string energy-source) ERR_INVALID_AMOUNT)
        (asserts! (is-some (map-get? approved-energy-sources energy-source)) ERR_MINER_NOT_VERIFIED) ;; ensure source exists
        (map-delete approved-energy-sources energy-source)
        (print {
            event: "energy-source-removed",
            energy-source: energy-source,
            block-height: stacks-block-height,
        })
        (ok true)
    )
)

;; private functions
(define-private (is-valid-energy-source (source (string-ascii 100)))
    (default-to false (map-get? approved-energy-sources source))
)

(define-private (is-valid-principal (principal-to-check principal))
    (and 
        (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78)) ;; not burn address
        (not (is-eq principal-to-check CONTRACT_OWNER)) ;; additional safety check
        true
    )
)

(define-private (is-valid-string (input (string-ascii 100)))
    (and 
        (> (len input) u0)
        (<= (len input) u100)
    )
)

;; Initialize contract
(begin
    (map-set verifiers CONTRACT_OWNER true)
    ;; Initialize default energy sources
    (map-set approved-energy-sources "solar" true)
    (map-set approved-energy-sources "wind" true)
    (map-set approved-energy-sources "hydro" true)
    (map-set approved-energy-sources "geothermal" true)
    (map-set approved-energy-sources "nuclear" true)
    (print {
        event: "contract-deployed",
        owner: CONTRACT_OWNER,
        token-name: TOKEN_NAME,
        token-symbol: TOKEN_SYMBOL,
        max-supply: MAX_SUPPLY,
    })
)
