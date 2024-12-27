;; SkillPulse Contract
;; Handles career development goals and mentorship matching

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-goal-not-found (err u103))
(define-constant err-invalid-status (err u104))

;; Data Variables
(define-map Users principal 
  {
    is-mentor: bool,
    reputation: uint,
    skills: (list 10 (string-ascii 64))
  }
)

(define-map Goals uint 
  {
    owner: principal,
    title: (string-ascii 64),
    description: (string-ascii 256),
    status: (string-ascii 20),
    mentor: (optional principal),
    created-at: uint
  }
)

(define-data-var goal-id-nonce uint u0)

;; Private Functions
(define-private (is-user-registered (user principal))
  (is-some (map-get? Users user))
)

;; Public Functions
(define-public (register-user (is-mentor bool) (skills (list 10 (string-ascii 64))))
  (if (is-user-registered tx-sender)
    err-already-registered
    (ok (map-set Users tx-sender {
      is-mentor: is-mentor,
      reputation: u0,
      skills: skills
    }))
  )
)

(define-public (create-goal (title (string-ascii 64)) (description (string-ascii 256)))
  (let 
    (
      (new-id (var-get goal-id-nonce))
    )
    (if (is-user-registered tx-sender)
      (begin
        (map-set Goals new-id {
          owner: tx-sender,
          title: title,
          description: description,
          status: "active",
          mentor: none,
          created-at: block-height
        })
        (var-set goal-id-nonce (+ new-id u1))
        (ok new-id)
      )
      err-not-registered
    )
  )
)

(define-public (assign-mentor (goal-id uint) (mentor principal))
  (let
    (
      (goal (unwrap! (map-get? Goals goal-id) err-goal-not-found))
      (mentor-data (unwrap! (map-get? Users mentor) err-not-registered))
    )
    (if (and
          (is-eq tx-sender (get owner goal))
          (get is-mentor mentor-data)
        )
      (ok (map-set Goals goal-id (merge goal {mentor: (some mentor)})))
      (err u105)
    )
  )
)

(define-public (update-goal-status (goal-id uint) (new-status (string-ascii 20)))
  (let
    (
      (goal (unwrap! (map-get? Goals goal-id) err-goal-not-found))
    )
    (if (is-eq tx-sender (get owner goal))
      (ok (map-set Goals goal-id (merge goal {status: new-status})))
      err-invalid-status
    )
  )
)

(define-public (award-reputation (user principal) (points uint))
  (let
    (
      (user-data (unwrap! (map-get? Users user) err-not-registered))
    )
    (if (is-eq tx-sender contract-owner)
      (ok (map-set Users 
        user 
        (merge user-data {reputation: (+ (get reputation user-data) points)})
      ))
      err-owner-only
    )
  )
)

;; Read-only Functions
(define-read-only (get-user-info (user principal))
  (map-get? Users user)
)

(define-read-only (get-goal (goal-id uint))
  (map-get? Goals goal-id)
)

(define-read-only (get-user-goals (user principal))
  (filter goals-owner-filter (map-to-list Goals))
)

(define-private (goals-owner-filter (goal {owner: principal, title: (string-ascii 64), description: (string-ascii 256), status: (string-ascii 20), mentor: (optional principal), created-at: uint}))
  (is-eq (get owner goal) tx-sender)
)