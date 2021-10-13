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
agent_vers="0.1.0"
lin_procs_vers="0.1.0"
indep_procs_vers="0.1.0"
dev_vers="0.1.0"
# computed variables
tmpdir="$(mktemp -d)"
# datashark related variables
core="datashark_core-${core_vers}-py3-none-any.whl"
core_url="${repo_url}/datashark-core/releases/download/${core_vers}/${core}"
core_path="${tmpdir}/${core}"
agent="datashark_agent-${agent_vers}-py3-none-any.whl"
agent_url="${repo_url}/datashark-agent/releases/download/${agent_vers}/${agent}"
agent_path="${tmpdir}/${agent}"
lin_procs="datashark_processors_linux-${lin_procs_vers}-py3-none-any.whl"
lin_procs_url="${repo_url}/datashark-processors-linux/releases/download/${lin_procs_vers}/${lin_procs}"
lin_procs_path="${tmpdir}/${lin_procs}"
indep_procs="datashark_processors_independent-${indep_procs_vers}-py3-none-any.whl"
indep_procs_url="${repo_url}/datashark-processors-independent/releases/download/${indep_procs_vers}/${indep_procs}"
indep_procs_path="${tmpdir}/${indep_procs}"
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
curl -o "${agent_path}" "${agent_url}"
curl -o "${lin_procs_path}" "${lin_procs_url}"
curl -o "${indep_procs_path}" "${indep_procs_url}"
# install packages
echo "[INFO] installing Datashark agent..."
pip install "${core_path}"
pip install "${agent_path}"
pip install "${lin_procs_path}"
pip install "${indep_procs_path}"
# remove temporary directory
echo "[INFO] removing Datashark package cache..."
rm -rf "${tmpdir}"
# download configuration file
echo "[INFO] download Datashark agent configuration file..."
curl -o "${config_path}" "${config_url}"
# create systemd service
echo "[INFO] creating Datashark agent service..."
cat << EOF | tee "${home}/.config/systemd/user/datashark.service"
[Unit]
Description=Datashark Agent
After=network.target

[Service]
Type=simple
User=${user}
Group=${user}
WorkingDirectory=${home}
Environment=LANG=en_US.UTF-8
Environment=LC_ALL=en_US.UTF-8
Environment=LC_LANG=en_US.UTF-8
ExecStart=${home}/venv/bin/datashark-agent ${home}/datashark.yml
ExecStop=/bin/kill -s TERM \$MAINPID
PrivateTmp=true
Restart=always

[Install]
WantedBy=multi-user.target
EOF
# enable systemd service
echo "[INFO] enabling datashark startup service..."
systemctl --user enable datashark.service
systemctl --user daemon-reload
# setup is complete
echo "[INFO] setup complete!"
echo "[INFO] 1. you should customize ${config_path}"
echo "[INFO] 2. to start datashark agent"
echo "[INFO]   a. sign-out and sign-in again"
echo "[INFO]   b. start datashark agent service manually using systemctl"
