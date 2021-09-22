#!/usr/bin/env bash
set -e

. common.sh

CWD="$(pwd)"
CA_DIR="${CWD}/ssl/ca"
INT_DIR="${CA_DIR}/intermediate"

PROG="${0}"
MODE="${1}"
PREFIX="${2}"

function usage {
    echo "usage: ${PROG} mode prefix"
    echo
    echo 'arguments:'
    echo '  mode: one of {cli,agent}'
    echo '  prefix: unique identifier matching grep regexp ^\w+$'
    echo
    exit 1
}

# check command line arguments
if [ -z "$(echo -n "${PREFIX}" | grep -Po '^\w+$')" ]; then
    usage
fi
SUBJECT=""
EXTENSIONS=""
case "${MODE}" in
    agent)
        SUBJECT="/C=FR/ST=France/L=Paris/O=Datashark/OU=Datashark Agent/CN=${PREFIX}"
        EXTENSIONS="agent_cert"
        ;;
    cli)
        SUBJECT="/C=FR/ST=France/L=Paris/O=Datashark/OU=Datashark CLI/CN=${PREFIX}"
        EXTENSIONS="cli_cert"
        ;;
    *)
        usage
        ;;
esac
# move to CA directory
cd "${CA_DIR}"
print "generate private key"
openssl genpkey \
      -algorithm ed25519 \
      -out "intermediate/private/${PREFIX}.key.pem"
# change private key permissions
chmod 400 "intermediate/private/${PREFIX}.key.pem"
print "generate certificate signing request"
openssl req \
    -config intermediate/openssl.cnf \
    -key "intermediate/private/${PREFIX}.key.pem" \
    -new \
    -sha256 \
    -subj "${SUBJECT}" \
    -out "intermediate/csr/${PREFIX}.csr.pem"
print "create certificate and sign it with intermediate CA"
openssl ca \
    -batch \
    -config intermediate/openssl.cnf \
    -extensions "${EXTENSIONS}" \
    -days 730 \
    -notext \
    -md sha256 \
    -in "intermediate/csr/${PREFIX}.csr.pem" \
    -out "intermediate/certs/${PREFIX}.cert.pem"
# change certificate permissions
chmod 444 "intermediate/certs/${PREFIX}.cert.pem"
cat "intermediate/certs/${PREFIX}.cert.pem"
print "display certificate"
openssl x509 \
    -noout \
    -text \
    -in "intermediate/certs/${PREFIX}.cert.pem"
print "verify certificate"
openssl verify \
    -CAfile intermediate/certs/ca-chain.cert.pem \
    "intermediate/certs/${PREFIX}.cert.pem"
