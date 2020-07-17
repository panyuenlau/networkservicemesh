package converter

import "go.ligato.io/vpp-agent/v3/proto/ligato/configurator"

type Converter interface {
	ToDataRequest(rv *configurator.Config, connect bool) (*configurator.Config, error)
}

type CrossConnectConversionParameters struct {
	BaseDir              string
	BaseMTU              uint32 // base MTU to be applied = MTU of the egress interface
	MechanismMTUOverhead uint32 // maximum MTU overhead of all the supported mechanism types
	MTUOverride          uint32 // specific MTU that overrides automatic MTU calculation
}

type ConnectionContextSide int

const (
	NEITHER ConnectionContextSide = iota + 1
	SOURCE
	DESTINATION
)

type ConnectionConversionParameters struct {
	Terminate bool
	Side      ConnectionContextSide
	Name      string
	BaseDir   string
	MTU       uint32
}
