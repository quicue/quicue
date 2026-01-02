// Command Tool - Execute actions via `cue cmd`
//
// Usage:
//   cue cmd -t resource=gitlab -t action=status run ./reference/...
//   cue cmd -t resource=technitium -t action=ping run ./reference/...
//   cue cmd list ./reference/...
//   cue cmd actions -t resource=gitlab ./reference/...
//
// Dry run (show command without executing):
//   cue cmd -t resource=gitlab -t action=status dry ./reference/...

package reference

import (
	"tool/cli"
	"tool/exec"
	"strings"
)

// Run an action
command: run: {
	// Get resource and action from tags
	_resource: string @tag(resource)
	_action:   string @tag(action)

	// Look up the command
	_cmd: output[_resource].actions[_action]

	// Execute it
	do: exec.Run & {
		cmd: ["bash", "-c", _cmd]
	}
}

// Dry run - show command without executing
command: dry: {
	_resource: string @tag(resource)
	_action:   string @tag(action)
	_cmd:      output[_resource].actions[_action]

	print: cli.Print & {
		text: "Would execute: \(_cmd)"
	}
}

// List all resources
command: list: {
	_names: [for name, _ in output {name}]

	print: cli.Print & {
		text: strings.Join(_names, "\n")
	}
}

// Show actions for a resource
command: actions: {
	_resource: string @tag(resource)
	_actions: [for name, cmd in output[_resource].actions {"\(name): \(cmd)"}]

	print: cli.Print & {
		text: strings.Join(_actions, "\n")
	}
}

// Show resource details
command: show: {
	_resource: string @tag(resource)
	_r:        output[_resource]

	print: cli.Print & {
		text: """
			Resource: \(_resource)
			Type:     \(strings.Join(_r["@type"], ", "))
			IP:       \(_r.ip)
			Node:     \(_r.node)
			LXCID:    \(_r.lxcid)
			"""
	}
}
