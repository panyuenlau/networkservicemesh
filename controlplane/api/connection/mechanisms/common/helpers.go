package common

import (
	"net"
	"strconv"

	"github.com/pkg/errors"

	"github.com/networkservicemesh/networkservicemesh/controlplane/api/connection"
)

// SrcIP returns the source IP parameter of the Mechanism
func GetSrcIP(m *connection.Mechanism) (string, error) {
	return getIPParameter(m, SrcIP)
}

// DstIP returns the destination IP parameter of the Mechanism
func GetDstIP(m *connection.Mechanism) (string, error) {
	return getIPParameter(m, DstIP)
}

func getIPParameter(m *connection.Mechanism, name string) (string, error) {
	if m == nil {
		return "", errors.New("mechanism cannot be nil")
	}

	if m.GetParameters() == nil {
		return "", errors.Errorf("mechanism.Parameters cannot be nil: %v", m)
	}

	ip, ok := m.Parameters[name]
	if !ok {
		return "", errors.Errorf("mechanism.Type %s requires mechanism.Parameters[%s]", m.GetType(), name)
	}

	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return "", errors.Errorf("mechanism.Parameters[%s] must be a valid IPv4 or IPv6 address, instead was: %s: %v", name, ip, m)
	}

	return ip, nil
}

// SetMTUOverhead sets the MTU overhead parameter in the parameter map
func SetMTUOverhead(parameters map[string]string, mtu uint32) error {
	if parameters == nil {
		return errors.Errorf("mechanism parameters cannot be nil")
	}
	parameters[MTUOverhead] = strconv.FormatUint(uint64(mtu), 10)
	return nil
}

// GetMTUOverhead returns the MTU overhead parameter value from the parameter map
func GetMTUOverhead(parameters map[string]string) (uint32, error) {
	if parameters == nil {
		return 0, errors.Errorf("mechanism parameters cannot be nil")
	}
	overheadParam, ok := parameters[MTUOverhead]
	if !ok {
		return 0, nil // parameter not found - return 0
	}
	overhead, err := strconv.Atoi(overheadParam)
	if err != nil {
		return 0, errors.Errorf("cannot convert mechanism.Parameters[%s] to number: %v", MTUOverhead, err)
	}
	return uint32(overhead), nil
}
