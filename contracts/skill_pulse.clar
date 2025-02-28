;; SkillPulse Contract
;; Handles career development goals and mentorship matching

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-goal-not-found (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-milestone-not-found (err u105))
(define-constant err-invalid-reward (err u106))
(define-constant err-invalid-milestone (err u107))
(define-constant err-empty-description (err u108))

;; Configuration Constants
(define-constant MAX-REWARD-AMOUNT u10000)
(define-constant MIN-REWARD-AMOUNT u1)

;; Data Variables
(define-map Users principal 
  {
    is-mentor: bool,
    reputation: uint,
    skills: (list 10 (string-ascii 64)),
    rewards-balance: uint
  }
)

(define-map Goals uint 
  {
    owner: principal,
    title: (string-ascii 64),
    description: (string-ascii 256),
    status: (string-ascii 20),
    mentor: (optional principal),
    created-at: uint,
    milestones: (list 5 uint)
  }
)

(define-map Milestones uint
  {
    goal-id: uint,
    description: (string-ascii 256),
    reward-amount: uint,
    completed: bool
  }
)

(define-data-var goal-id-nonce uint u0)
(define-data-var milestone-id-nonce uint u0)

;; Private Functions
(define-private (is-user-registered (user principal))
  (is-some (map-get? Users user))
)

(define-private (validate-reward-amount (amount uint))
  (and 
    (>= amount MIN-REWARD-AMOUNT)
    (<= amount MAX-REWARD-AMOUNT)
  )
)

(define-private (validate-description (description (string-ascii 256)))
  (not (is-eq description ""))
)

;; Public Functions
(define-read-only (get-milestone (milestone-id uint))
  (map-get? Milestones milestone-id)
)

(define-read-only (get-goal (goal-id uint))
  (map-get? Goals goal-id)
)

(define-public (register-user (is-mentor bool) (skills (list 10 (string-ascii 64))))
  (if (is-user-registered tx-sender)
    err-already-registered
    (ok (map-set Users tx-sender {
      is-mentor: is-mentor,
      reputation: u0,
      skills: skills,
      rewards-balance: u0
    }))
  )
)

(define-public (create-goal (title (string-ascii 64)) (description (string-ascii 256)))
  (let 
    (
      (new-id (var-get goal-id-nonce))
    )
    (if (and (is-user-registered tx-sender) (validate-description description))
      (begin
        (map-set Goals new-id {
          owner: tx-sender,
          title: title,
          description: description,
          status: "active",
          mentor: none,
          created-at: block-height,
          milestones: (list)
        })
        (var-set goal-id-nonce (+ new-id u1))
        (print { type: "goal-created", goal-id: new-id, owner: tx-sender })
        (ok new-id)
      )
      err-not-registered
    )
  )
)

(define-public (add-milestone (goal-id uint) (description (string-ascii 256)) (reward-amount uint))
  (let
    (
      (goal (unwrap! (map-get? Goals goal-id) err-goal-not-found))
      (new-milestone-id (var-get milestone-id-nonce))
    )
    (if (not (validate-description description))
      err-empty-description
      (if (not (validate-reward-amount reward-amount))
        err-invalid-milestone
        (if (is-eq tx-sender (get owner goal))
          (begin
            (map-set Milestones new-milestone-id {
              goal-id: goal-id,
              description: description,
              reward-amount: reward-amount,
              completed: false
            })
            (map-set Goals goal-id (merge goal {
              milestones: (unwrap! (as-max-len? 
                (append (get milestones goal) new-milestone-id) u5) 
                err-invalid-status)
            }))
            (var-set milestone-id-nonce (+ new-milestone-id u1))
            (print { type: "milestone-added", milestone-id: new-milestone-id, goal-id: goal-id })
            (ok new-milestone-id)
          )
          err-owner-only
        )
      )
    )
  )
)
