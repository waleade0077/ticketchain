;; ---------------------------------------------
;; Contract: TicketChain
;; On-Chain Ticketing with Resale and Royalties
;; ---------------------------------------------

(define-data-var next-event-id uint u1)
(define-data-var next-ticket-id uint u1)

(define-map events
  uint ;; event-id
  {
    organizer: principal,
    name: (string-ascii 100),
    date: uint,
    royalty: uint, ;; percentage (0-100)
    resale-cap: uint, ;; max % cap on resale (e.g. 200 for 2x original)
  }
)

(define-map tickets
  uint ;; ticket-id
  {
    event-id: uint,
    owner: principal,
    used: bool,
    price: uint,
    resale: bool,
  }
)

;; ---------------------------------------------
;; EVENTS
;; ---------------------------------------------

(define-public (create-event
    (name (string-ascii 100))
    (date uint)
    (royalty uint)
    (resale-cap uint)
  )
  (let ((event-id (var-get next-event-id)))
    (begin
      (map-insert events event-id {
        organizer: tx-sender,
        name: name,
        date: date,
        royalty: royalty,
        resale-cap: resale-cap,
      })
      (var-set next-event-id (+ event-id u1))
      (ok event-id)
    )
  )
)

;; ---------------------------------------------
;; TICKET MINTING AND PRIMARY SALE
;; ---------------------------------------------

(define-public (mint-ticket
    (event-id uint)
    (price uint)
  )
  (match (map-get? events event-id)
    event
    (if (is-eq (get organizer event) tx-sender)
      (let ((ticket-id (var-get next-ticket-id)))
        (begin
          (map-insert tickets ticket-id {
            event-id: event-id,
            owner: tx-sender,
            used: false,
            price: price,
            resale: false,
          })
          (var-set next-ticket-id (+ ticket-id u1))
          (ok ticket-id)
        )
      )
      (err u100) ;; not organizer
    )
    (err u107) ;; event not found
  )
)

(define-public (buy-ticket (ticket-id uint))
  (match (map-get? tickets ticket-id)
    ticket
    (if (is-eq (get resale ticket) false)
      (match (stx-transfer? (get price ticket) tx-sender (get owner ticket))
        transfer-ok
        (begin
          (map-set tickets ticket-id (merge ticket { owner: tx-sender }))
          (ok true)
        )
        transfer-err
        (err u108) ;; transfer failed
      )
      (err u101) ;; resale ticket, use resale function
    )
    (err u107) ;; ticket not found
  )
)

;; ---------------------------------------------
;; TICKET RESALE AND SECONDARY PURCHASE
;; ---------------------------------------------

(define-public (resell-ticket
    (ticket-id uint)
    (new-price uint)
  )
  (match (map-get? tickets ticket-id)
    ticket
    (let ((event-id (get event-id ticket)))
      (match (map-get? events event-id)
        event
        (if (and (is-eq (get owner ticket) tx-sender) (<= new-price (/ (* (get price ticket) (get resale-cap event)) u100)))
          (begin
            (map-set tickets ticket-id
              (merge ticket {
                price: new-price,
                resale: true,
              })
            )
            (ok true)
          )
          (err u102) ;; unauthorized or price cap exceeded
        )
        (err u107) ;; event not found
      )
    )
    (err u107) ;; ticket not found
  )
)

(define-public (buy-resale-ticket (ticket-id uint))
  (match (map-get? tickets ticket-id)
    ticket
    (match (map-get? events (get event-id ticket))
      event
      (if (is-eq (get resale ticket) true)
        (let (
            (royalty (/ (* (get price ticket) (get royalty event)) u100))
            (seller (- (get price ticket)
              (/ (* (get price ticket) (get royalty event)) u100)
            ))
          )
          (match (stx-transfer? royalty tx-sender (get organizer event))
            transfer-royalty-ok
            (match (stx-transfer? seller tx-sender (get owner ticket))
              transfer-seller-ok
              (begin
                (map-set tickets ticket-id
                  (merge ticket {
                    owner: tx-sender,
                    resale: false,
                  })
                )
                (ok true)
              )
              transfer-seller-err
              (err u108) ;; transfer to seller failed
            )
            transfer-royalty-err
            (err u109) ;; transfer to organizer failed
          )
        )
        (err u103) ;; not for resale
      )
      (err u107) ;; event not found
    )
    (err u107) ;; ticket not found
  )
)

;; ---------------------------------------------
;; VALIDATION & UTILITY
;; ---------------------------------------------

(define-public (validate-ticket (ticket-id uint))
  (match (map-get? tickets ticket-id)
    ticket
    (match (map-get? events (get event-id ticket))
      event
      (if (and (is-eq (get organizer event) tx-sender) (is-eq (get used ticket) false))
        (begin
          (map-set tickets ticket-id (merge ticket { used: true }))
          (ok true)
        )
        (err u104)
      )
      (err u107) ;; event not found
    )
    (err u107) ;; ticket not found
  )
)

(define-read-only (get-ticket (ticket-id uint))
  (map-get? tickets ticket-id)
)

(define-read-only (get-event (event-id uint))
  (map-get? events event-id)
)

(define-public (burn-ticket (ticket-id uint))
  (match (map-get? tickets ticket-id)
    ticket
    (if (and (is-eq (get owner ticket) tx-sender) (is-eq (get used ticket) false))
      (begin
        (map-delete tickets ticket-id)
        (ok true)
      )
      (err u105)
    )
    (err u107) ;; ticket not found
  )
)

(define-public (transfer-ticket
    (ticket-id uint)
    (to principal)
  )
  (match (map-get? tickets ticket-id)
    ticket
    (if (is-eq (get owner ticket) tx-sender)
      (begin
        (map-set tickets ticket-id (merge ticket { owner: to }))
        (ok true)
      )
      (err u106)
    )
    (err u107) ;; ticket not found
  )
)
