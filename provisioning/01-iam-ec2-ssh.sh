#!/bin/bash -eu

if [ "$EUID" -ne 0 ]; then
  exec sudo -- "$0" "$@"
fi

# https://github.com/widdix/aws-ec2-ssh/blob/08c06cf227e8c36f1cbaae451c4a191a3221c395/install.sh
# Get the scripts from GitHub
install_dir=/opt/aws-ec2-ssh
githash=08c06cf227e8c36f1cbaae451c4a191a3221c395

function download()
{
  host=https://raw.githubusercontent.com
  repo=widdix/aws-ec2-ssh
  local file=$1
  local install_dir=$2
  local output="${install_dir}/${file}"
  mkdir -p "${install_dir}"
  curl --silent --output "${output}" \
    "${host}/${repo}/${githash}/${file}"
  chmod +x "${output}"
}

function configure_crontab()
{
  local install_dir=$1
  local crontab=/etc/cron.d/import-iam-users
  echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    > "${crontab}"
  echo "* * * * * root ${install_dir}/import_users.sh" \
    >> "${crontab}"
  chmod 0644 "${crontab}"
}

function configure_sshd()
{
  local install_dir=$1
  local sshd_config=/etc/ssh/sshd_config
  cat <<END>> "${sshd_config}"

# aws-ec2-ssh
AuthorizedKeysCommand ${install_dir}/authorized_keys_command.sh
AuthorizedKeysCommandUser nobody
PermitRootLogin no
UseDNS no
END
}

function cleanup()
{
  shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
  passwd -l root
}

function main()
{
  download authorized_keys_command.sh "${install_dir}"
  download import_users.sh "${install_dir}"
  configure_crontab "${install_dir}"
  configure_sshd "${install_dir}"
  ${install_dir}/import_users.sh
  cleanup
}

main
