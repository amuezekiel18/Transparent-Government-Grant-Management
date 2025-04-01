;; Applicant Verification Contract
;; This contract validates eligible grant recipients

(define-data-var admin principal tx-sender)

;; Map to store verified applicants
(define-map verified-applicants principal bool)

;; Map to store applicant details
(define-map applicant-details
  principal
  {
    name: (string-ascii 100),
    organization: (string-ascii 100),
    tax-id: (string-ascii 20),
    verified-at: uint
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-NOT-FOUND u102)

;; Get the admin
(define-read-only (get-admin)
  (var-get admin)
)

;; Check if an applicant is verified
(define-read-only (is-verified (applicant principal))
  (default-to false (map-get? verified-applicants applicant))
)

;; Get applicant details
(define-read-only (get-applicant-details (applicant principal))
  (map-get? applicant-details applicant)
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (ok (var-set admin new-admin))
  )
)

;; Verify an applicant
(define-public (verify-applicant
    (applicant principal)
    (name (string-ascii 100))
    (organization (string-ascii 100))
    (tax-id (string-ascii 20))
  )
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (not (is-verified applicant)) (err ERR-ALREADY-VERIFIED))

    (map-set verified-applicants applicant true)
    (map-set applicant-details applicant {
      name: name,
      organization: organization,
      tax-id: tax-id,
      verified-at: block-height
    })

    (ok true)
  )
)

;; Revoke verification
(define-public (revoke-verification (applicant principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-verified applicant) (err ERR-NOT-FOUND))

    (map-delete verified-applicants applicant)
    (map-delete applicant-details applicant)

    (ok true)
  )
)
