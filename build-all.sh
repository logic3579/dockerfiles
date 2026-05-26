#!/bin/bash
set -e
set -o pipefail

if command -v docker >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v docker)
        CONTAINER_RUNTIME=docker
elif command -v podman >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v podman)
        CONTAINER_RUNTIME=podman
elif command -v container >/dev/null 2>&1; then
        CONTAINER_CMD=$(command -v container)
        CONTAINER_RUNTIME=container
else
        echo "ERROR: docker, podman or container is required." >&2
        exit 1
fi

if ! command -v parallel >/dev/null 2>&1; then
        echo "ERROR: GNU parallel is required." >&2
        exit 1
fi

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO_URL="${REPO_URL:-docker.io/logic3579}"
JOBS=${JOBS:-2}
ERRORS=$(mktemp)
trap 'rm -f "$ERRORS"' EXIT

push_image(){
        image=$1

        case "$CONTAINER_RUNTIME" in
                docker)    "${CONTAINER_CMD}" push --disable-content-trust=false "$image" ;;
                container) "${CONTAINER_CMD}" image push "$image" ;;
                *)         "${CONTAINER_CMD}" push "$image" ;;
        esac
}

tag_image(){
        src=$1
        dst=$2

        if [[ "$CONTAINER_RUNTIME" == "container" ]]; then
                "${CONTAINER_CMD}" image tag "$src" "$dst"
        else
                "${CONTAINER_CMD}" tag "$src" "$dst"
        fi
}


build_and_push(){
        base=$1
        suite=$2
        build_dir=$3

        echo "Building ${REPO_URL}/${base}:${suite} for context ${build_dir}"
        if [[ "$CONTAINER_RUNTIME" == "container" ]]; then
                "${CONTAINER_CMD}" build -f "${build_dir}/Dockerfile" -t "${REPO_URL}/${base}:${suite}" "${build_dir}" || return 1
        else
                "${CONTAINER_CMD}" build --rm --force-rm -t "${REPO_URL}/${base}:${suite}" "${build_dir}" || return 1
        fi

        # on successful build, push the image
        echo "                       ---                                   "
        echo "Successfully built ${base}:${suite} with context ${build_dir}"
        echo "                       ---                                   "

        # try push a few times because notary server sometimes returns 401 for
        # absolutely no reason
        n=0
        until [ $n -ge 5 ]; do
                push_image "${REPO_URL}/${base}:${suite}" && break
                echo "Try #$n failed... sleeping for 15 seconds"
                n=$((n+1))
                sleep 15
        done

        # also push the tag latest for "stable" (chrome), "tools" (wireguard) or "3.5" tags for zookeeper
        if [[ "$suite" == "stable" ]] || [[ "$suite" == "3.6" ]] || [[ "$suite" == "tools" ]]; then
                tag_image "${REPO_URL}/${base}:${suite}" "${REPO_URL}/${base}:latest"
                push_image "${REPO_URL}/${base}:latest"
        fi
}

dofile() {
        f=$1
        image=${f%Dockerfile}
        base=${image%%\/*}
        build_dir=$(dirname "$f")
        suite=${build_dir##*\/}

        if [[ -z "$suite" ]] || [[ "$suite" == "$base" ]]; then
                suite=latest
        fi

        {
                $SCRIPT build_and_push "${base}" "${suite}" "${build_dir}"
        } || {
        # add to errors
        echo "${base}:${suite}" >> "$ERRORS"
        }
echo
echo
}

main(){
        # get the dockerfiles
        IFS=$'\n'
        mapfile -t files < <(find -L . -iname '*Dockerfile' | sed 's|./||' | sort)
        unset IFS

        # build all dockerfiles
        echo "Running in parallel with ${JOBS} jobs."
        parallel --tag --verbose --ungroup -j"${JOBS}" "$SCRIPT" dofile "{1}" ::: "${files[@]}"

        if [[ ! -s "$ERRORS" ]]; then
                echo "No errors."
        else
                echo "[ERROR] Some images did not build correctly, see below." >&2
                echo "These images failed: $(cat "$ERRORS")" >&2
                exit 1
        fi
}

run(){
        args=$*
        f=$1

        if [[ "$f" == "" ]]; then
                main "$args"
        else
                $args
        fi
}

run "$@"
