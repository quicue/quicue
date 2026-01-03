// Action Schema
//
// Usage:
//   import "quicue.ca/vocab@v0"
//
//   myAction: vocab.#Action & {
//       name: "Ping"
//       description: "Test connectivity"
//       command: "ping -c3 \(IP)"
//   }
//
// PARAMETER CONVENTIONS:
// - Use UPPERCASE for template parameters (NODE, VMID, IP, USER)
// - Parameters are interpolated into command strings
//
// SECURITY WARNING:
// - Command strings use direct interpolation without escaping
// - Do NOT pass untrusted user input as parameters
// - Validate/sanitize at the provider or CLI layer

package vocab

// #Action - Base schema for all actions
#Action: {
	name:         string
	description?: string
	command?:     string
	icon?:        string
	category?:    string // connect|info|monitor|admin (for UI grouping)

	// Operational metadata
	timeout_seconds?:       int  // Expected max duration (0 = no timeout)
	requires_confirmation?: bool // Prompt before executing?
	idempotent?:            bool // Safe to retry?
	destructive?:           bool // Modifies state permanently?
	requires?: [...string] // Prerequisites (e.g., ["ssh_access", "guest_agent"])
	...
}
