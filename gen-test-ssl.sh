#!/usr/bin/env bash
set -e

. common.sh

print "create CA and intermediate CA"
./gen-ca.sh
print "create cli test certificate"
./gen-cert.sh cli cli
print "create agent test certificate"
./gen-cert.sh agent agent
print "create symbolic links"
ln -s ca/intermediate/certs/ca-chain.cert.pem ssl/ca-chain.cert.pem
ln -s ca/intermediate/certs/cli.cert.pem ssl/cli.cert.pem
ln -s ca/intermediate/certs/agent.cert.pem ssl/agent.cert.pem
ln -s ca/intermediate/private/cli.key.pem ssl/cli.key.pem
ln -s ca/intermediate/private/agent.key.pem ssl/agent.key.pem
print "list symbolic links"
ls -lah ssl/*.pem
