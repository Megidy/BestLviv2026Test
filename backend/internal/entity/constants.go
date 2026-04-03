package entity

const (
	PriorityNormal   DeliveryPriority = "normal"
	PriorityElevated DeliveryPriority = "elevated"
	PriorityCritical DeliveryPriority = "critical"
	PriorityUrgent   DeliveryPriority = "urgent"
)

const (
	StatusPending   DeliveryStatus = "pending"
	StatusAllocated DeliveryStatus = "allocated"
	StatusInTransit DeliveryStatus = "in_transit"
	StatusDelivered DeliveryStatus = "delivered"
	StatusCancelled DeliveryStatus = "cancelled"
)

const (
	AllocationStatusPlanned   AllocationStatus = "planned"
	AllocationStatusApproved  AllocationStatus = "approved"
	AllocationStatusInTransit AllocationStatus = "in_transit"
	AllocationStatusDelivered AllocationStatus = "delivered"
	AllocationStatusCancelled AllocationStatus = "cancelled"
)

const (
	UserRoleWorker     UserRole = "worker"
	UserRoleDispatcher UserRole = "dispatcher"
	UserRoleAdmin      UserRole = "admin"
)

const (
	DemandSourceManual    DemandSource = "manual"
	DemandSourceSensor    DemandSource = "sensor"
	DemandSourcePredicted DemandSource = "predicted"
)

const (
	AlertStatusOpen      AlertStatus = "open"
	AlertStatusDismissed AlertStatus = "dismissed"
	AlertStatusResolved  AlertStatus = "resolved"
)

const (
	ProposalStatusPending   ProposalStatus = "pending"
	ProposalStatusApproved  ProposalStatus = "approved"
	ProposalStatusDismissed ProposalStatus = "dismissed"
)

const (
	AuditDeliveryRequestCreated  AuditAction = "DELIVERY_REQUEST_CREATED"
	AuditDeliveryRequestCancelled AuditAction = "DELIVERY_REQUEST_CANCELLED"
	AuditDemandUpdated           AuditAction = "DEMAND_UPDATED"
	AuditPriorityEscalated       AuditAction = "PRIORITY_ESCALATED"
	AuditAllocationCreated       AuditAction = "ALLOCATION_CREATED"
	AuditAllocationApproved      AuditAction = "ALLOCATION_APPROVED"
	AuditAllocationRejected      AuditAction = "ALLOCATION_REJECTED"
	AuditGoodsDispatched         AuditAction = "GOODS_DISPATCHED"
	AuditDeliveryConfirmed       AuditAction = "DELIVERY_CONFIRMED"
	AuditUrgentRequestProcessed  AuditAction = "URGENT_REQUEST_PROCESSED"
	AuditStockAdjusted           AuditAction = "STOCK_ADJUSTED"
	AuditAlertDismissed          AuditAction = "ALERT_DISMISSED"
	AuditProposalApproved        AuditAction = "PROPOSAL_APPROVED"
	AuditProposalDismissed       AuditAction = "PROPOSAL_DISMISSED"
)

const (
	LimitKey  string = "limit"
	OffsetKey string = "offset"
	UserKey   string = "user"
)
