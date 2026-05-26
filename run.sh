#!/bin/bash
#
# This script allows you to launch several images
# from this repository once they're built.
#
# Make sure you add the `docker run` command
# in the header of the Dockerfile so the script
# can find it and execute it.
#
# Use pulseaudio/Dockerfile and skype/Dockerfile as examples.
set -e
set -o pipefail

if command -v docker >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v docker)
elif command -v podman >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v podman)
elif command -v container >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v container)
else
        echo "ERROR: docker, podman or container is required." >&2
        exit 1
fi

# Apple's `container` defaults to host arch. Set RUN_ARCH=amd64 (or arm64) to
# force a specific architecture, e.g. for images that aren't multi-arch yet.
RUN_TOKEN="${CONTAINER_CMD} run"
if [[ "$(basename "$CONTAINER_CMD")" == "container" && -n "${RUN_ARCH:-}" ]]; then
        RUN_TOKEN="${CONTAINER_CMD} run --arch ${RUN_ARCH}"
fi

if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [--test] image1 image2 ..."
        exit 1
fi

if [[ "$1" = "--test" ]]; then
        TEST=1
        shift
fi

for name in "$@"; do
        if [[ ! -d "$name" ]]; then
                echo "Unable to find container configuration with name: $name"
                exit 1
        fi

        #script=$(sed -n '/docker run/,/^#$/p' "$name/Dockerfile" | head -n -1 | sed "s/#//" | sed "s#\\\\##" | tr '\n' ' ' | sed "s/\$@//" | sed 's/""//')
        script=$(sed -n '/docker run/,/^#$/p' "$name/Dockerfile" | sed "s/#//" | sed "s#\\\\##" | tr '\n' ' ' | sed "s/\$@//" | sed 's/""//' | sed 's/ \{1,\}/ /g' | sed "s|docker run|${RUN_TOKEN}|")
        if [[ "$(basename "$CONTAINER_CMD")" == "container" ]]; then
                # Apple's `container` won't allocate a pty under make/CI; detached
                # examples don't need stdin/tty anyway, so strip -i/-t flags.
                script=$(echo "$script" | sed 's/ -it / /g; s/ -ti / /g; s/ -t / /g; s/ -i / /g; s/  */ /g')
        fi
        echo "Running: $script"

        if [ $TEST ]; then
                echo "$script"
        else
                eval "$script"
        fi

        shift
done
