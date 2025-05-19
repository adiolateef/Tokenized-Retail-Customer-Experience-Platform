;; Consumer Identity Contract
;; Manages shopper profiles

(define-data-var admin principal tx-sender)

;; Consumer profile data
(define-map consumers principal
  {
    username: (string-utf8 50),
    email-hash: (buff 32),
    registration-time: uint,
    active: bool
  }
)

;; Privacy settings: 0 = private, 1 = retailers only, 2 = public
(define-map privacy-settings principal
  {
    preference-sharing: uint,
    loyalty-sharing: uint
  }
)

(define-read-only (get-consumer (consumer-id principal))
  (default-to
    {
      username: u"",
      email-hash: 0x,
      registration-time: u0,
      active: false
    }
    (map-get? consumers consumer-id)
  )
)

(define-read-only (get-privacy-settings (consumer-id principal))
  (default-to
    {
      preference-sharing: u0,
      loyalty-sharing: u0
    }
    (map-get? privacy-settings consumer-id)
  )
)

(define-public (register-consumer (username (string-utf8 50)) (email-hash (buff 32)))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (if (is-none (map-get? consumers tx-sender))
      (begin
        (map-set consumers tx-sender
          {
            username: username,
            email-hash: email-hash,
            registration-time: current-time,
            active: true
          }
        )
        (map-set privacy-settings tx-sender
          {
            preference-sharing: u0,
            loyalty-sharing: u0
          }
        )
        (ok true)
      )
      (err u1) ;; already registered
    )
  )
)

(define-public (update-profile (username (string-utf8 50)) (email-hash (buff 32)))
  (if (is-some (map-get? consumers tx-sender))
    (begin
      (map-set consumers tx-sender
        (merge (get-consumer tx-sender)
          {
            username: username,
            email-hash: email-hash
          }
        )
      )
      (ok true)
    )
    (err u2) ;; not registered
  )
)

(define-public (update-privacy-settings (preference-sharing uint) (loyalty-sharing uint))
  (if (is-some (map-get? consumers tx-sender))
    (begin
      (map-set privacy-settings tx-sender
        {
          preference-sharing: preference-sharing,
          loyalty-sharing: loyalty-sharing
        }
      )
      (ok true)
    )
    (err u2) ;; not registered
  )
)

(define-public (deactivate-account)
  (if (is-some (map-get? consumers tx-sender))
    (begin
      (map-set consumers tx-sender
        (merge (get-consumer tx-sender)
          {
            active: false
          }
        )
      )
      (ok true)
    )
    (err u2) ;; not registered
  )
)

(define-read-only (is-active-consumer (consumer-id principal))
  (get active (get-consumer consumer-id))
)
