#!/bin/bash
set -euo pipefail

path="$1"

if [[ ! -d "$path" ]]; then
    echo "::error ::Invalid package path: [$path]"
    exit 1
fi

abspath="$(realpath "$path")"

warn() {
    local message="$1"
    if [[ -n "$message" ]]; then
        message="${message//'%'/'%25'}"
        message="${message//$'\n'/'%0A'}"
        message="${message//$'\r'/'%0D'}"
        echo "::warning::$message"
    fi
}

echo "::group::Install namcap, git and yay"
HOME=/home/builder
cd $HOME
sudo pacman -S --noconfirm --needed git namcap
git clone https://aur.archlinux.org/yay-bin.git
pushd yay-bin
makepkg -si --noconfirm
popd
echo "::endgroup"
 
echo "::group::Copy files to home."
cp -r ${abspath} .
cd "$(basename ${abspath})"
echo "::endgroup::"

echo "::group::Install depends and makedepends"
source PKGBUILD
yay -S --removemake --needed --noconfirm ${depends[@]} ${makedepends[@]}
echo "::endgroup::"

echo "::group::Build packages"
makepkg -s --noconfirm
echo "::endgroup::"

echo "::group::Get package info"
pkgfile=$(basename $(makepkg --packagelist))
echo "pkgfile=${pkgfile}" | sudo tee -a $GITHUB_OUTPUT
pacman -Qip ${pkgfile}
echo "::endgroup::"

echo "::group::Run namcap checks"
warn "$(namcap PKGBUILD)"
warn "$(namcap "${pkgfile}")"
echo "::endgroup::"

echo "::group::Generate .SRCINFO"
makepkg --printsrcinfo > .SRCINFO
sudo mv .SRCINFO ${abspath}
echo "::endgroup::"

echo "::group::Remove namcap, git and yay"
sudo pacman -Rnsd --noconfirm yay-bin git namcap || true
echo "::endgroup::"

sudo mv ${pkgfile} $GITHUB_WORKSPACE
