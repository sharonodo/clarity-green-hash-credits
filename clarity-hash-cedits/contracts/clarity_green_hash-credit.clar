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
(define-constant TOKEN_NAME "Green Hash Credits")
(define-constant TOKEN_SYMBOL "GHC")
(define-constant TOKEN_DECIMALS u6)
(define-constant MAX_SUPPLY u1000000000000) ;; 1 million GHC with 6 decimals

;; data vars
(define-data-var total-supply uint u0)
(define-data-var contract-paused bool false)

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

;; Read-only functions
(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

;; Initialize contract
(begin
    (print {
        event: "contract-deployed",
        owner: CONTRACT_OWNER,
        token-name: TOKEN_NAME,
        token-symbol: TOKEN_SYMBOL,
        max-supply: MAX_SUPPLY,
    })
)
