;; Retailer Verification Contract
;; Validates legitimate merchants in the platform

(define-data-var admin principal tx-sender)

;; Retailer status: 0 = unverified, 1 = pending, 2 = verified, 3 = rejected
(define-map retailers principal
  {
    name: (string-utf8 100),
    status: uint,
    registration-time: uint,
    verification-time: uint
  }
)

(define-read-only (get-retailer (retailer-id principal))
  (default-to
    {
      name: u"",
      status: u0,
      registration-time: u0,
      verification-time: u0
    }
    (map-get? retailers retailer-id)
  )
)

(define-public (register-retailer (name (string-utf8 100)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-none (map-get? retailers tx-sender))
      (begin
        (map-set retailers tx-sender
          {
            name: name,
            status: u1, ;; pending
            registration-time: current-time,
            verification-time: u0
          }
        )
        (ok true)
      )
      (err u1) ;; already registered
    )
  )
)

(define-public (verify-retailer (retailer-id principal) (new-status uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-eq tx-sender (var-get admin))
      (begin
        (map-set retailers retailer-id
          (merge (default-to
            {
              name: u"",
              status: u0,
              registration-time: u0,
              verification-time: u0
            }
            (map-get? retailers retailer-id)
          )
          {
            status: new-status,
            verification-time: current-time
          })
        )
        (ok true)
      )
      (err u2) ;; not authorized
    )
  )
)

(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
    (begin
      (var-set admin new-admin)
      (ok true)
    )
    (err u3) ;; not authorized
  )
)

(define-read-only (is-verified-retailer (retailer-id principal))
  (is-eq (get status (get-retailer retailer-id)) u2)
)
