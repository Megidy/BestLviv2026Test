package entity

const (
	PriorityNormal   DeliveryPriority = "normal"
	PriorityElevated DeliveryPriority = "elevated"
	PriorityCritical DeliveryPriority = "critical"
)

const (
	StatusPending   DeliveryStatus = "pending"
	StatusAllocated DeliveryStatus = "allocated"
	StatusInTransit DeliveryStatus = "in_transit"
	StatusDelivered DeliveryStatus = "delivered"
	StatusCancelled DeliveryStatus = "cancelled"
)

const (
	UserRoleWorker UserRole = "worker"
)

const (
	LimitKey  string = "limit"
	OffsetKey string = "offset"
	UserKey   string = "user"
)
