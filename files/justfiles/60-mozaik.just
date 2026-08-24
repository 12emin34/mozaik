mozaik:
    #!/usr/bin/bash
    set -euo pipefail
    . /etc/os-release
    echo
    echo "  ${PRETTY_NAME}"
    echo "  ─────────────────────────────────────────────"
    printf "  %-16s %s\n" "Kernel"  "$(uname -r)"
    printf "  %-16s %s\n" "Session" "${XDG_CURRENT_DESKTOP:-tty} / ${XDG_SESSION_TYPE:-n-a}"
    printf "  %-16s %s\n" "Uptime"  "$(uptime -p 2>/dev/null || echo unknown)"
    echo
    echo "  Deployments:"
    rpm-ostree status | sed 's/^/    /'
    echo

mozaik-sysinfo mode="print":
    #!/usr/bin/bash
    set -euo pipefail
    report="$(mktemp)"
    {
      echo "### os-release";    cat /etc/os-release
      echo; echo "### deployments"; rpm-ostree status
      echo; echo "### kernel";      uname -a
      echo; echo "### cpu";         lscpu | sed -n '1,20p'
      echo; echo "### memory";      free -h
      echo; echo "### selinux";     getenforce 2>/dev/null || echo "n/a"
      echo; echo "### failed units"; systemctl --failed --no-legend || true
      echo; echo "### flatpaks";    flatpak list --app --columns=application,version 2>/dev/null || true
    } > "${report}"
    if [ "{{ mode }}" = "upload" ]; then
      echo "Uploading report..."
      curl -sF "file=@${report}" https://0x0.st
    else
      cat "${report}"
      echo
      echo "(run 'ujust mozaik-sysinfo upload' to get a shareable link instead)"
    fi

mozaik-verify:
    #!/usr/bin/bash
    set -euo pipefail
    key=/usr/share/mozaik/cosign.pub
    img=ghcr.io/12emin34/mozaik:latest
    command -v cosign >/dev/null || { echo "cosign is not in this image"; exit 1; }
    [ -f "${key}" ] || { echo "missing ${key}"; exit 1; }
    echo "Verifying ${img}"
    cosign verify --key "${key}" "${img}"
