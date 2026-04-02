package deliveryrequest

import "context"

type UseCase struct {
}

func New() *UseCase {
	return &UseCase{}
}

func (u *UseCase) RequestDelivery(ctx context.Context)
