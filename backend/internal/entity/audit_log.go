package entity

import "time"

type AuditAction string

type AuditEntry struct {
	ID          uint        `json:"id"`
	ActorID     *uint       `json:"actor_id,omitempty"`
	ActorRole   string      `json:"actor_role"`
	Action      AuditAction `json:"action"`
	EntityType  string      `json:"entity_type,omitempty"`
	EntityID    *uint       `json:"entity_id,omitempty"`
	BeforeValue *string     `json:"before_value,omitempty"`
	AfterValue  *string     `json:"after_value,omitempty"`
	IPAddress   *string     `json:"ip_address,omitempty"`
	CreatedAt   time.Time   `json:"created_at"`
}
