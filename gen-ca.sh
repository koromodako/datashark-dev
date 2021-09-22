#!/usr/bin/env bash
set -e

. common.sh

CWD="$(pwd)"
CA_DIR="${CWD}/ssl/ca"
INT_DIR="${CA_DIR}/intermediate"

# create and enter CA directory
mkdir -p "${CA_DIR}" && cd "${CA_DIR}"
# create directories
mkdir -p certs crl newcerts private
# change directory permissions
chmod 700 private
# create files
touch index.txt
echo 1000 > serial
cat <<EOF > openssl.cnf
# ---------------------------------------------------------------------
[ ca ]
default_ca = CA_default
# ---------------------------------------------------------------------
[ CA_default ]
# directory and file locations ----------------------------------------
dir               = ${CA_DIR}
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand
# root key and root certificate ---------------------------------------
private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem
# certificate revocation lists ----------------------------------------
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
# other options -------------------------------------------------------
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict
# ---------------------------------------------------------------------
[ policy_strict ]
# root CA should only sign intermediate certificates that match -------
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
# ---------------------------------------------------------------------
[ policy_loose ]
# intermediate CA to sign a more diverse range of certificates --------
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
# ---------------------------------------------------------------------
[ req ]
# req options ---------------------------------------------------------
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
# extension to add when the -x509 option is used ----------------------
x509_extensions     = v3_ca
# ---------------------------------------------------------------------
[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address
# Optionally, specify some defaults.
countryName_default             = FR
stateOrProvinceName_default     = France
localityName_default            = Paris
0.organizationName_default      = Datashark
organizationalUnitName_default  = Datashark Root Certificate Authority
#emailAddress_default           =
# ---------------------------------------------------------------------
[ v3_ca ]
# extensions for a typical CA -----------------------------------------
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
# ---------------------------------------------------------------------
[ v3_intermediate_ca ]
# extensions for a typical intermediate CA ----------------------------
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
# ---------------------------------------------------------------------
[ cli_cert ]
# extensions for client certificates ----------------------------------
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
# ---------------------------------------------------------------------
[ alt_names ]
DNS.1 = localhost
# ---------------------------------------------------------------------
[ agent_cert ]
# extensions for server certificates ----------------------------------
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectAltName = @alt_names
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
# ---------------------------------------------------------------------
[ crl_ext ]
# extension for CRLs --------------------------------------------------
authorityKeyIdentifier=keyid:always
# ---------------------------------------------------------------------
[ ocsp ]
# extension for OCSP signing certificates
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
print "generate CA private key"
openssl genpkey \
    -algorithm ed25519 \
    -out private/ca.key.pem
# change private key permissions
chmod 400 private/ca.key.pem
print "self-sign CA certificate"
openssl req \
    -config openssl.cnf \
    -key private/ca.key.pem \
    -new \
    -x509 \
    -days 7300 \
    -sha256 \
    -extensions v3_ca \
    -subj "/C=FR/ST=France/L=Paris/O=Datashark/OU=Datashark Root Certificate Authority/CN=Datashark Root CA" \
    -out certs/ca.cert.pem
# change self-signed CA certificate permissions
chmod 444 certs/ca.cert.pem
cat certs/ca.cert.pem
print "display self-signed CA certificate"
openssl x509 \
    -noout  \
    -text \
    -in certs/ca.cert.pem
# create intermediate certificates directories
mkdir -p "${INT_DIR}" && cd "${INT_DIR}"
# create directories
mkdir -p certs crl csr newcerts private
# change directory permissions
chmod 700 private
# create files
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
# copy and slightly change configuration file
cp "${CA_DIR}/openssl.cnf" "${INT_DIR}/openssl.cnf"
sed -i "s#^dir               = .*\$#dir               = ${INT_DIR}#g" "${INT_DIR}/openssl.cnf"
sed -i "s#^private_key       = .*\$#private_key       = \$dir/private/intermediate.key.pem#g" "${INT_DIR}/openssl.cnf"
sed -i "s#^certificate       = .*\$#certificate       = \$dir/certs/intermediate.cert.pem#g" "${INT_DIR}/openssl.cnf"
sed -i "s#^crl               = .*\$#crl               = \$dir/crl/intermediate.crl.pem#g" "${INT_DIR}/openssl.cnf"
sed -i "s#^policy            = .*\$#policy            = policy_loose#g" "${INT_DIR}/openssl.cnf"
sed -i "s#^organizationalUnitName_default  = .*\$#organizationalUnitName_default  = Datashark Intermediate Certificate Authority#g" "${INT_DIR}/openssl.cnf"
# move to CA directory
cd "${CA_DIR}"
print "generate intermediate CA private key"
openssl genpkey \
    -algorithm ed25519 \
    -out intermediate/private/intermediate.key.pem
# change intermediate CA private key permissions
chmod 400 intermediate/private/intermediate.key.pem
print "create intermediate CA certificate signing request"
openssl req \
    -config intermediate/openssl.cnf \
    -new \
    -sha256 \
    -key intermediate/private/intermediate.key.pem \
    -subj "/C=FR/ST=France/L=Paris/O=Datashark/OU=Datashark Intermediate Certificate Authority/CN=Datashark Intermediate CA" \
    -out intermediate/csr/intermediate.csr.pem
print "create intermediate CA certificate"
openssl ca \
    -batch \
    -config openssl.cnf \
    -extensions v3_intermediate_ca \
    -days 3650 \
    -notext \
    -md sha256 \
    -in intermediate/csr/intermediate.csr.pem \
    -out intermediate/certs/intermediate.cert.pem
# change intermediate CA certficate permissions
chmod 444 intermediate/certs/intermediate.cert.pem
cat intermediate/certs/intermediate.cert.pem
print "display intermediate CA certificate"
openssl x509 \
    -noout \
    -text \
    -in intermediate/certs/intermediate.cert.pem
print "verify intermediate CA certificate"
openssl verify \
    -CAfile certs/ca.cert.pem \
    intermediate/certs/intermediate.cert.pem
print "create CA certficates chain"
cat intermediate/certs/intermediate.cert.pem \
    certs/ca.cert.pem | tee intermediate/certs/ca-chain.cert.pem
# change CA certificates chain permissions
chmod 444 intermediate/certs/ca-chain.cert.pem
