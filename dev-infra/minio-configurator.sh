#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $(basename "$0") <bucket-name> <user-name>

Required environment variables (override defaults as needed):
  MINIO_ENDPOINT             Default: http://127.0.0.1:9000 (prompted if unset)
  MINIO_ROOT_USER            Default: admin (prompted if unset)
  MINIO_ROOT_PASSWORD        Default: password-dev (prompted if unset)
  MINIO_ALIAS                Default: minio
  MINIO_BUCKET_PASSWORD      Optional; prompts if unset
  MINIO_POLICY_DIR           Default: directory of this script (needs minio-public-policy.json and minio-private-writer.json)
USAGE
}

POLICY_DIR=${MINIO_POLICY_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

BUCKET_NAME=$1
PRIVATE_USER=$2
PRIVATE_PASSWORD=${MINIO_BUCKET_PASSWORD:-}

if [[ -z "${PRIVATE_PASSWORD}" ]]; then
  read -r -s -p "Enter password for MinIO user '${PRIVATE_USER}': " PRIVATE_PASSWORD
  echo
  if [[ -z "${PRIVATE_PASSWORD}" ]]; then
    echo "Error: password cannot be empty." >&2
    exit 1
  fi
fi

DEFAULT_ENDPOINT=http://127.0.0.1:9000
DEFAULT_ROOT_USER=admin
DEFAULT_ROOT_PASSWORD=password-dev
DEFAULT_ALIAS=minio

if [[ -z "${MINIO_ENDPOINT:-}" ]]; then
  read -r -p "Enter MinIO endpoint [${DEFAULT_ENDPOINT}]: " MINIO_ENDPOINT_INPUT
  MINIO_ENDPOINT=${MINIO_ENDPOINT_INPUT:-$DEFAULT_ENDPOINT}
else
  MINIO_ENDPOINT=${MINIO_ENDPOINT}
fi

if [[ -z "${MINIO_ROOT_USER:-}" ]]; then
  read -r -p "Enter MinIO root user [${DEFAULT_ROOT_USER}]: " MINIO_ROOT_USER_INPUT
  MINIO_ROOT_USER=${MINIO_ROOT_USER_INPUT:-$DEFAULT_ROOT_USER}
else
  MINIO_ROOT_USER=${MINIO_ROOT_USER}
fi

if [[ -z "${MINIO_ROOT_PASSWORD:-}" ]]; then
  read -r -s -p "Enter MinIO root password [hidden, default ${DEFAULT_ROOT_PASSWORD}]: " MINIO_ROOT_PASSWORD_INPUT
  echo
  if [[ -z "${MINIO_ROOT_PASSWORD_INPUT}" ]]; then
    MINIO_ROOT_PASSWORD=$DEFAULT_ROOT_PASSWORD
  else
    MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD_INPUT
  fi
else
  MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
fi

MINIO_ALIAS=${MINIO_ALIAS:-$DEFAULT_ALIAS}

for f in minio-public-policy.json minio-private-writer.json; do
  if [[ ! -f "$POLICY_DIR/$f" ]]; then
    echo "Error: policy template '$POLICY_DIR/$f' not found (set MINIO_POLICY_DIR)." >&2
    exit 1
  fi
done

if ! command -v mc >/dev/null 2>&1; then
  echo "Error: MinIO Client (mc) is not installed or not in PATH." >&2
  exit 1
fi

public_policy=$(mktemp)
private_policy=$(mktemp)
placeholder_file=$(mktemp)

cleanup() {
  rm -f "$public_policy" "$private_policy" "$placeholder_file"
}
trap cleanup EXIT

# Las políticas son plantillas JSON; ${MINIO_BUCKET_NAME} se sustituye por el nombre del bucket.
# Solo bash y coreutils: la imagen de MinIO no trae sed, awk ni envsubst.
render_policy() {
  local content
  content=$(<"$1")
  printf '%s\n' "${content//'${MINIO_BUCKET_NAME}'/$BUCKET_NAME}" >"$2"
}

render_policy "$POLICY_DIR/minio-public-policy.json" "$public_policy"
render_policy "$POLICY_DIR/minio-private-writer.json" "$private_policy"

# Ensure the administrative alias exists and points to the expected endpoint.
mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

# Create bucket and expected prefixes if they do not already exist.
mc mb --ignore-existing "$MINIO_ALIAS/${BUCKET_NAME}"

# Publish the anonymous read policy for the public prefix.
mc anonymous set-json "$public_policy" "$MINIO_ALIAS/${BUCKET_NAME}"

PRIVATE_POLICY_NAME="${BUCKET_NAME}-private-writer"

# Register or update the tailored private policy and attach it to the managed user.
if mc admin policy info "$MINIO_ALIAS" "$PRIVATE_POLICY_NAME" >/dev/null 2>&1; then
  mc admin policy delete "$MINIO_ALIAS" "$PRIVATE_POLICY_NAME"
fi
mc admin policy create "$MINIO_ALIAS" "$PRIVATE_POLICY_NAME" "$private_policy"

# Seed expected prefixes with placeholder objects so they are visible via clients.
printf '' >"$placeholder_file"
mc cp "$placeholder_file" "$MINIO_ALIAS/${BUCKET_NAME}/public/.keep" >/dev/null 2>&1 || true
mc cp "$placeholder_file" "$MINIO_ALIAS/${BUCKET_NAME}/private/.keep" >/dev/null 2>&1 || true

mc admin user add "$MINIO_ALIAS" "$PRIVATE_USER" "$PRIVATE_PASSWORD"
mc admin policy attach "$MINIO_ALIAS" --user "$PRIVATE_USER" "$PRIVATE_POLICY_NAME"

echo "Bucket '${BUCKET_NAME}' configured with public/private prefixes."
echo "User '${PRIVATE_USER}' now has policy '${PRIVATE_POLICY_NAME}'."
