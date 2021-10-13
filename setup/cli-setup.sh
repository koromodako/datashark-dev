#!/usr/bin/env bash
set -e
# script requirements
# * id
# * apt
# * tee
# * cat
# * curl
# * sudo
# script parameters
user="$(id -nu)"
home="/home/${user}"
repo_url="https://github.com/koromodako"
core_vers="0.1.1"
cli_vers="0.1.0"
dev_vers="0.1.0"
# computed variables
tmpdir="$(mktemp -d)"
# datashark related variables
core="datashark_core-${core_vers}-py3-none-any.whl"
core_url="${repo_url}/datashark-core/releases/download/${core_vers}/${core}"
core_path="${tmpdir}/${core}"
cli="datashark_cli-${cli_vers}-py3-none-any.whl"
cli_url="${repo_url}/datashark-cli/releases/download/${cli_vers}/${cli}"
cli_path="${tmpdir}/${cli}"
config_url="${repo_url}/datashark-dev/releases/download/${dev_vers}/datashark.dist.yml"
config_path="${home}/datashark.yml"
# setup python 3.x
echo "[INFO] installing datashark agent dependencies..."
sudo apt install python3 python3-dev python3-pip python3-venv
# ensure pip is up-to-date
echo "[INFO] ensuring pip is up-to-date..."
python3 -m pip install -U pip
# create virtual environment
echo "[INFO] creating virtual environment..."
python3 -m venv "${home}/venv"
# source virtual environment
echo "[INFO] activating virtual environment..."
. "${home}/venv/bin/activate"
# download packages
echo "[INFO] downloading Datashark agent packages..."
curl -o "${core_path}" "${core_url}"
curl -o "${cli_path}" "${cli_url}"
# install packages
echo "[INFO] installing Datashark agent..."
pip install "${core_path}"
pip install "${cli_path}"
# remove temporary directory
echo "[INFO] removing Datashark package cache..."
rm -rf "${tmpdir}"
# download configuration file
echo "[INFO] download Datashark agent configuration file..."
curl -o "${config_path}" "${config_url}"
# setup is complete
echo "[INFO] setup complete!"
echo "[INFO] 1. you should customize ${config_path}"
echo "[INFO] 2. then start datashark cli using: datashark -c ${config_path} -h"
