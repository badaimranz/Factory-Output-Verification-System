;; title: Factory-Output-Verification-System

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_BATCH_EXISTS (err u101))
(define-constant ERR_BATCH_NOT_FOUND (err u102))
(define-constant ERR_INVALID_QUANTITY (err u103))
(define-constant ERR_ALREADY_VERIFIED (err u104))
(define-constant ERR_NOT_MANUFACTURER (err u105))
(define-constant ERR_INVALID_STATUS (err u106))
(define-constant ERR_BATCH_EXPIRED (err u107))
(define-constant ERR_NOT_AUTHORIZED_VERIFIER (err u108))

(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_REJECTED u2)
(define-constant STATUS_RECALLED u3)

(define-data-var batch-counter uint u0)

(define-map manufacturers principal bool)

(define-map authorized-verifiers principal bool)

(define-map batches
  { batch-id: uint }
  {
    manufacturer: principal,
    product-name: (string-ascii 100),
    quantity: uint,
    production-date: uint,
    expiry-date: uint,
    status: uint,
    verified-by: (optional principal),
    verification-date: (optional uint),
    metadata-hash: (string-ascii 64)
  }
)

(define-map batch-history
  { batch-id: uint, sequence: uint }
  {
    action: (string-ascii 50),
    actor: principal,
    timestamp: uint,
    notes: (string-ascii 200)
  }
)

(define-map manufacturer-batches
  { manufacturer: principal, index: uint }
  { batch-id: uint }
)

(define-map manufacturer-batch-count
  { manufacturer: principal }
  { count: uint }
)

(define-map batch-scans
  { batch-id: uint }
  { scan-count: uint }
)

(map-set manufacturers CONTRACT_OWNER true)
(map-set authorized-verifiers CONTRACT_OWNER true)

(define-read-only (get-batch-info (batch-id uint))
  (map-get? batches { batch-id: batch-id })
)

(define-read-only (get-batch-history (batch-id uint) (sequence uint))
  (map-get? batch-history { batch-id: batch-id, sequence: sequence })
)

(define-read-only (get-scan-count (batch-id uint))
  (default-to { scan-count: u0 } (map-get? batch-scans { batch-id: batch-id }))
)

(define-read-only (is-manufacturer (address principal))
  (default-to false (map-get? manufacturers address))
)

(define-read-only (is-authorized-verifier (address principal))
  (default-to false (map-get? authorized-verifiers address))
)

(define-read-only (get-manufacturer-batch-count (manufacturer principal))
  (default-to { count: u0 } (map-get? manufacturer-batch-count { manufacturer: manufacturer }))
)

(define-read-only (get-manufacturer-batch (manufacturer principal) (index uint))
  (map-get? manufacturer-batches { manufacturer: manufacturer, index: index })
)

(define-read-only (get-current-batch-counter)
  (var-get batch-counter)
)

(define-read-only (is-batch-valid (batch-id uint))
  (match (get-batch-info batch-id)
    batch-data (let
      ((current-block stacks-block-height))
      (and
        (< current-block (get expiry-date batch-data))
        (or
          (is-eq (get status batch-data) STATUS_VERIFIED)
          (is-eq (get status batch-data) STATUS_PENDING)
        )
      )
    )
    false
  )
)

(define-public (register-manufacturer (address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set manufacturers address true))
  )
)

(define-public (revoke-manufacturer (address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set manufacturers address false))
  )
)

(define-public (register-verifier (address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set authorized-verifiers address true))
  )
)

(define-public (revoke-verifier (address principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set authorized-verifiers address false))
  )
)

(define-public (register-batch 
  (product-name (string-ascii 100))
  (quantity uint)
  (production-date uint)
  (expiry-date uint)
  (metadata-hash (string-ascii 64))
)
  (let
    (
      (batch-id (+ (var-get batch-counter) u1))
      (manufacturer-count (get count (get-manufacturer-batch-count tx-sender)))
    )
    (asserts! (is-manufacturer tx-sender) ERR_NOT_MANUFACTURER)
    (asserts! (> quantity u0) ERR_INVALID_QUANTITY)
    (asserts! (< production-date expiry-date) ERR_INVALID_STATUS)
    
    (map-set batches
      { batch-id: batch-id }
      {
        manufacturer: tx-sender,
        product-name: product-name,
        quantity: quantity,
        production-date: production-date,
        expiry-date: expiry-date,
        status: STATUS_PENDING,
        verified-by: none,
        verification-date: none,
        metadata-hash: metadata-hash
      }
    )
    
    (map-set manufacturer-batches
      { manufacturer: tx-sender, index: manufacturer-count }
      { batch-id: batch-id }
    )
    
    (map-set manufacturer-batch-count
      { manufacturer: tx-sender }
      { count: (+ manufacturer-count u1) }
    )
    
    (map-set batch-history
      { batch-id: batch-id, sequence: u0 }
      {
        action: "REGISTERED",
        actor: tx-sender,
        timestamp: stacks-block-height,
        notes: "Batch registered by manufacturer"
      }
    )
    
    (var-set batch-counter batch-id)
    (ok batch-id)
  )
)

(define-public (verify-batch (batch-id uint) (approved bool))
  (let
    (
      (batch-data (unwrap! (get-batch-info batch-id) ERR_BATCH_NOT_FOUND))
    )
    (asserts! (is-authorized-verifier tx-sender) ERR_NOT_AUTHORIZED_VERIFIER)
    (asserts! (is-eq (get status batch-data) STATUS_PENDING) ERR_ALREADY_VERIFIED)
    
    (map-set batches
      { batch-id: batch-id }
      (merge batch-data {
        status: (if approved STATUS_VERIFIED STATUS_REJECTED),
        verified-by: (some tx-sender),
        verification-date: (some stacks-block-height)
      })
    )
    
    (map-set batch-history
      { batch-id: batch-id, sequence: u1 }
      {
        action: (if approved "VERIFIED" "REJECTED"),
        actor: tx-sender,
        timestamp: stacks-block-height,
        notes: (if approved "Batch verified successfully" "Batch verification failed")
      }
    )
    
    (ok approved)
  )
)

(define-public (recall-batch (batch-id uint) (reason (string-ascii 200)))
  (let
    (
      (batch-data (unwrap! (get-batch-info batch-id) ERR_BATCH_NOT_FOUND))
    )
    (asserts! (or
      (is-eq tx-sender (get manufacturer batch-data))
      (is-eq tx-sender CONTRACT_OWNER)
    ) ERR_UNAUTHORIZED)
    
    (map-set batches
      { batch-id: batch-id }
      (merge batch-data { status: STATUS_RECALLED })
    )
    
    (map-set batch-history
      { batch-id: batch-id, sequence: u2 }
      {
        action: "RECALLED",
        actor: tx-sender,
        timestamp: stacks-block-height,
        notes: reason
      }
    )
    
    (ok true)
  )
)

(define-public (scan-batch (batch-id uint))
  (let
    (
      (batch-data (unwrap! (get-batch-info batch-id) ERR_BATCH_NOT_FOUND))
      (current-scans (get scan-count (get-scan-count batch-id)))
    )
    (map-set batch-scans
      { batch-id: batch-id }
      { scan-count: (+ current-scans u1) }
    )
    
    (ok {
      valid: (is-batch-valid batch-id),
      status: (get status batch-data),
      manufacturer: (get manufacturer batch-data),
      product-name: (get product-name batch-data),
      scan-number: (+ current-scans u1)
    })
  )
)
