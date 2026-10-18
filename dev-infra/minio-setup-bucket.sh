#!/usr/bin/env bash
set -euo pipefail

BUCKET_NAME=${MINIO_BUCKET_NAME:?MINIO_BUCKET_NAME is required}
PRIVATE_USER=${MINIO_BUCKET_USER:?MINIO_BUCKET_USER is required}
PRIVATE_PASSWORD=${MINIO_BUCKET_PASSWORD:?MINIO_BUCKET_PASSWORD is required}

MINIO_ENDPOINT=${MINIO_ENDPOINT:-http://minio:9000}
MINIO_ROOT_USER=${MINIO_ROOT_USER:?MINIO_ROOT_USER is required}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:?MINIO_ROOT_PASSWORD is required}
MINIO_ALIAS=${MINIO_ALIAS:-minio}
POLICY_DIR=${MINIO_POLICY_DIR:-/policies}

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

echo "Waiting for MinIO at ${MINIO_ENDPOINT}..."
until mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null 2>&1; do
  sleep 2
done

if mc ls "$MINIO_ALIAS/${BUCKET_NAME}" >/dev/null 2>&1; then
  echo "Bucket '${BUCKET_NAME}' already exists. Skipping bucket setup."
  exit 0
fi

# Las políticas son plantillas JSON; ${MINIO_BUCKET_NAME} se sustituye por el nombre del bucket.
render_policy() {
  # Solo bash y coreutils: la imagen de MinIO no trae sed, awk ni envsubst.
  local content
  content=$(<"$1")
  printf '%s\n' "${content//'${MINIO_BUCKET_NAME}'/$BUCKET_NAME}" >"$2"
}

render_policy "$POLICY_DIR/minio-public-policy.json" "$public_policy"
render_policy "$POLICY_DIR/minio-private-writer.json" "$private_policy"

mc mb "$MINIO_ALIAS/${BUCKET_NAME}"
mc anonymous set-json "$public_policy" "$MINIO_ALIAS/${BUCKET_NAME}"

PRIVATE_POLICY_NAME="${BUCKET_NAME}-private-writer"

if mc admin policy info "$MINIO_ALIAS" "$PRIVATE_POLICY_NAME" >/dev/null 2>&1; then
  mc admin policy delete "$MINIO_ALIAS" "$PRIVATE_POLICY_NAME"
fi
mc admin policy create "$MINIO_ALIAS" "$PRIVATE_POLICY_NAME" "$private_policy"

printf '' >"$placeholder_file"
mc cp "$placeholder_file" "$MINIO_ALIAS/${BUCKET_NAME}/public/.keep" >/dev/null 2>&1 || true
mc cp "$placeholder_file" "$MINIO_ALIAS/${BUCKET_NAME}/private/.keep" >/dev/null 2>&1 || true

if mc admin user info "$MINIO_ALIAS" "$PRIVATE_USER" >/dev/null 2>&1; then
  mc admin user remove "$MINIO_ALIAS" "$PRIVATE_USER"
fi
mc admin user add "$MINIO_ALIAS" "$PRIVATE_USER" "$PRIVATE_PASSWORD"
mc admin policy attach "$MINIO_ALIAS" --user "$PRIVATE_USER" "$PRIVATE_POLICY_NAME"

echo "Bucket '${BUCKET_NAME}' configured with public/private prefixes."
echo "User '${PRIVATE_USER}' now has policy '${PRIVATE_POLICY_NAME}'."
