// Docker Provider - Action implementations for Docker containers
//
// Provides actions for Docker containers and Compose stacks.
// Uses docker/docker-compose CLI commands.
//
// PARAMETER CONVENTIONS (see vocab/actions.cue):
// - NAME: container name or ID
// - PROJECT: docker-compose project name
// - DIR: directory containing docker-compose.yml
// - IMAGE, TAG: for image operations
//
// Usage:
//   import "quicue.ca/reference/providers/docker"
//
//   myContainer: docker.#ContainerActions & {
//       NAME: "nginx"
//   }

package docker

import "quicue.ca/vocab"

// #ContainerActions - Docker container management
#ContainerActions: vocab.#ContainerActions & {
	NAME: string

	status: {
		name:        "Container Status"
		description: "Get container status"
		command:     "docker inspect --format='{{.State.Status}}' \(NAME)"
		idempotent:  true
	}

	console: {
		name:        "Container Console"
		description: "Attach to container console"
		command:     "docker attach \(NAME)"
	}

	logs: {
		name:        "Container Logs"
		description: "View container logs (last 100 lines)"
		command:     "docker logs --tail 100 \(NAME)"
		idempotent:  true
	}

	start: {
		name:        "Start Container"
		description: "Start the container"
		command:     "docker start \(NAME)"
		idempotent:  true
	}

	stop: {
		name:        "Stop Container"
		description: "Stop the container gracefully"
		command:     "docker stop \(NAME)"
		destructive: true
	}

	restart: {
		name:        "Restart Container"
		description: "Restart the container"
		command:     "docker restart \(NAME)"
		destructive: true
	}

	exec: {
		name:        "Execute Command"
		description: "Run command in container (append command)"
		command:     "docker exec -it \(NAME)"
	}

	shell: {
		name:        "Open Shell"
		description: "Open interactive shell"
		command:     "docker exec -it \(NAME) /bin/sh"
	}

	config: {
		name:        "Container Config"
		description: "Show container configuration"
		command:     "docker inspect \(NAME)"
		idempotent:  true
	}
}

// #ComposeActions - Docker Compose stack management
#ComposeActions: vocab.#ServiceActions & {
	PROJECT: string
	DIR:     string | *"."

	status: {
		name:        "Stack Status"
		description: "Show compose stack status"
		command:     "docker compose -p \(PROJECT) ps"
		idempotent:  true
	}

	health: {
		name:        "Stack Health"
		description: "Check health of all services"
		command:     "docker compose -p \(PROJECT) ps --format json | jq -r '.[] | \"\\(.Name): \\(.Health // .State)\"'"
		idempotent:  true
	}

	logs: {
		name:        "Stack Logs"
		description: "View compose logs (last 100 lines)"
		command:     "docker compose -p \(PROJECT) logs --tail 100"
		idempotent:  true
	}

	up: {
		name:        "Start Stack"
		description: "Start all services"
		command:     "docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml up -d"
		idempotent:  true
	}

	down: {
		name:                   "Stop Stack"
		description:            "Stop and remove all services"
		command:                "docker compose -p \(PROJECT) down"
		destructive:            true
		requires_confirmation:  true
	}

	restart: {
		name:        "Restart Stack"
		description: "Restart all services"
		command:     "docker compose -p \(PROJECT) restart"
		destructive: true
	}

	pull: {
		name:        "Pull Images"
		description: "Pull latest images"
		command:     "docker compose -p \(PROJECT) -f \(DIR)/docker-compose.yml pull"
		idempotent:  true
	}
}

// #ConnectivityActions - Network connectivity for Docker hosts
#ConnectivityActions: vocab.#ConnectivityActions & {
	HOST: string

	ping: {
		name:        "Ping"
		description: "Test network connectivity"
		command:     "ping -c 3 \(HOST)"
		idempotent:  true
	}

	ssh: {
		name:        "SSH"
		description: "SSH to Docker host"
		command:     "ssh \(HOST)"
	}
}

// #ImageActions - Docker image management
#ImageActions: vocab.#SnapshotActions & {
	IMAGE: string
	TAG:   string | *"latest"

	list: {
		name:        "List Images"
		description: "List local images"
		command:     "docker images \(IMAGE)"
		idempotent:  true
	}

	pull: {
		name:        "Pull Image"
		description: "Pull image from registry"
		command:     "docker pull \(IMAGE):\(TAG)"
		idempotent:  true
	}

	inspect: {
		name:        "Inspect Image"
		description: "Show image details"
		command:     "docker inspect \(IMAGE):\(TAG)"
		idempotent:  true
	}

	history: {
		name:        "Image History"
		description: "Show image layers"
		command:     "docker history \(IMAGE):\(TAG)"
		idempotent:  true
	}

	create: {
		name:        "Tag Image"
		description: "Create new tag for image"
		command:     "docker tag \(IMAGE):\(TAG)"
	}

	revert: {
		name:                  "Remove Image"
		description:           "Remove local image"
		command:               "docker rmi \(IMAGE):\(TAG)"
		destructive:           true
		requires_confirmation: true
	}
}
