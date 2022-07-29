#!/bin/sh

# Mamiza's Auto-Rice Script (MARS)
# by Mamiza <themamiza@gmail.com>
# License: GNU GPLv3
# Heavily inspired by: <https://larbs.xyz/larbs.sh>

##### FUNCTIONS #####

dotfilesrepo="https://github.com/mamizaxyz/dotfiles.git"
# progsfile="https://raw.githubusercontent.com/mamizaxyz/dotfiles/main/progs/minimal.csv" # minimal
progsfile="https://raw.githubusercontent.com/mamizaxyz/dotfiles/main/progs/progs.csv" # full
aurhelper="paru"
repobranch="main"

installpkg()
{
        pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

error()
{
        printf "%s\n" "$1" >&2
        exit 1
}

welcomemsg()
{
        whiptail --title "Welcome!" \
                --msgbox "Welcome to Mamiza's Auto-Rice Script!\\n\\nThis script will automatically install a fully-featured Linux desktop, Which I use as my main machine.\\n\\n-Mamiza" 10 60

        whiptail --title "Important Note!" --yes-button "All ready!" \
                --no-button "Return..." \
                --yesno "Be sure the computer you are using has current pacman updates and refreshed Arch keyring.\\n\\nIf it does not, the installation if some programs might fail." 8 70
}

getuserandpass()
{
        name=$(whiptail --inputbox "First, please enter a name for the user account." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
        while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
                name=$(whiptail --nocancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
        done
        pass1=$(whiptail --nocancel --passwordbox "Enter a password for that user." 10 60 3>&1 1>&2 2>&3 3>&1)
        pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
        while ! [ "$pass1" = "$pass2" ]; do
                unset pass2
                pass1=$(whiptail --nocancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
                pass2=$(whiptail --nocancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
        done
}

usercheck()
{
        ! { id -u "$name" >/dev/null 2>&1; } ||
                whiptail --title "WARNING" --yes-button "CONTINUE" \
                        --no-button "No wait..." \
                        --yesno "The user \`$name\` already exists on this system. MARS can install for a user already existing, but it will OVERWRITE any conflicting settings/dotfiles on the user account.\\n\\nMARS will not overwrite you user files, documents, videos, etc., so don't worry about that, but only click <CONTINUE> if you don't mind your settings being overwritten.\\n\\nNote also that MARS will change $name's password to the one you just gave." 14 70
}

setprogs()
{
        progs_choice="$(whiptail --title "Select software..." \
                --radiolist "Choose one of the below boxes." 10 55 2 \
                "Full" "Full set of software that I use." ON \
                "Minimal" "A more minimal software suite." OFF 3>&1 1>&2 2>&3)"

        case "$progs_choice" in
                "Full") export progsfile="https://raw.githubusercontent.com/mamizaxyz/dotfiles/main/progs/progs.csv";;
                "Minimal") export progsfile="https://raw.githubusercontent.com/mamizaxyz/dotfiles/main/progs/minimal.csv";;
        esac
}

preinstallmsg()
{
        whiptail --title "Let's get the party started!" --yes-button "Let's go!" \
                --no-button "No, nevermind!" \
                --yesno "The rest of the installation will now be totally automated, so you can just sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || {
                clear
                exit 1
        }
}

adduserandpass()
{
        whiptail --infobox "Adding user \"$name\"..." 7 50
        useradd -m -s /bin/zsh "$name" >/dev/null 2>&1 ||
                mkdir "/home/$name" && chown "$name":"$name" "/home/$name"
        export repodir="/home/$name/.local/src"
        mkdir -p "$repodir"
        chown -R "$name":"$name" "$(dirname "$repodir")"
        echo "$name:$pass1" | chpasswd
        unset pass1 pass2
}

refreshkeys()
{
        case "$(readlink -f /sbin/init)" in
                *systemd*)
                        whiptail --infobox "Refreshing Arch Keyring..." 7 40
                        pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
                        ;;
                *)
                        whiptail --infobox "Enabling Arch Repositories..." 7 40
                        if ! grep -q "^\[universe\]" /etc/pacman.conf; then
                                echo "[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" >>/etc/pacman.conf
                                pacman -Sy
                        fi
                        pacman --noconfirm --needed -S \
                                artix-keyring artix-archlinux-support >/dev/null 2>&1
                        for repo in extra community; do
                                grep -q "^\[$repo\]" /etc/pacman.conf ||
                                        echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
                        done
                        pacman -Sy >/dev/null 2>&1
                        pacman-key --populate archlinux >/dev/null 2>&1
                        ;;
        esac
}

manualinstall()
{
        [ -x "$(command -v "$1")" ] && return 0
        whiptail --infobox "Installing \"$1\" an AUR helper..." 7 50
        sudo -u "$name" mkdir -p "$repodir/$1"
        sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
                --no-tags -q "https://aur.archlinux.org/$1.git" "$repodir/$1" ||
                {
                        cd "$repodir/$1" || return 1
                        sudo -u "$name" git pull --force origin master
                }
        cd "$repodir/$1" || exit 1
        sudo -u "$name" -D "$repodir/$1" \
                makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}

maininstall()
{
        whiptail --title "MARS Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 9 70
        installpkg "$1"
}

gitmakeinstall()
{
        progname="${1##*/}"
        progname="${progname%.git}"
        dir="$repodir/$progname"
        whiptail --title "MARS Installation" \
                --infobox "Installing \`$progname\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 8 70
        sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
                --no-tags -q "$1" "$dir" ||
                {
                        cd "$dir" || return 1
                        sudo -u "$name" git pull --force origin master
                }
        cd "$dir" || exit 1
        make >/dev/null 2>&1
        make install >/dev/null 2>&1
        cd /tmp || return 1
}

aurinstall()
{
        whiptail --title "MARS Installation" \
                --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2" 9 70
        echo "$aurinstalled" | grep -q "^$1$" && return 1
        sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
}

installationloop()
{
        ([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) ||
                curl -Ls "$progsfile" | sed '/^#/d' >/tmp/progs.csv
        total=$(wc -l </tmp/progs.csv)
        aurinstalled=$(pacman -Qqm)
        while IFS=, read -r tag program comment; do
                n=$((n + 1))
                echo "$comment" | grep -q "^\".*\"$" &&
                        comment="$(echo "$comment" | sed -E "s/(^\"|\"$)//g")"
                case "$tag" in
                        "A") aurinstall "$program" "$comment" ;;
                        "G") gitmakeinstall "$program" "$comment" ;;
                        *) maininstall "$program" "$comment" ;;
                esac
        done </tmp/progs.csv
}

putgitrepo()
{
        whiptail --infobox "Downloading and installing config files..." 7 60
        [ -z "$3" ] && branch="master" || branch="$repobranch"
        dir=$(mktemp -d)
        [ ! -d "$2" ] && mkdir -p "$2"
        chown "$name":"$name" "$dir" "$2"
        sudo -u "$name" git -C "$repodir" clone --depth 1 \
                --single-branch --no-tags -q --recursive -b "$branch" \
                --recurse-submodules "$1" "$dir" ||
                {
                        cd "$dir" || return 1
                        sudo -u "$name" git pull --force origin master
                }
        sudo -u "$name" cp -rfT "$dir" "$2"
}

doominstall()
{

        [ -x "$(command -v emacs)" ] || return 0
        whiptail --infobox "Installing \"doomemacs\" from github..." 7 50
        rm -rf "/home/$name/.config/emacs"
        sudo -u "$name" mkdir "/home/$name/.config/emacs"
        sudo -u "$name" git -C "/home/$name/.config" clone --depth 1 --single-branch \
                --no-tags -q "https://github.com/doomemacs/doomemacs.git" "/home/$name/.config/emacs" ||
                {
                        cd "/home/$name/.config/emacs" || return 1
                        sudo -u "$name" git pull --force origin master
                }
        cd "/home/$name/.config/emacs" || exit 1
        sudo -u "$name" -D "/home/$name/.config/emacs" \
                "/home/$name/.config/emacs/bin/doom" install -! >/dev/null 2>&1 || return 1
        sudo -u "$name" -D "/home/$name/.config/emacs" \
                "/home/$name/.config/emacs/bin/doom" sync -! >/dev/null 2>&1 || return 1
}

finalize()
{
        whiptail --title "All done!" \
                --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nTo run the new graphical environment, just reboot.\\n\\n.t Mamiza" 13 80
}

##### THE SCRIPT #####

printf "Installing \`libnewt\` for an ncurses like interface.\n"
pacman --noconfirm --needed -Sy libnewt ||
        error "Are you sure you're running this as the root user, are on a Arch based distribution and have an internet connection?"

welcomemsg || error "ERROR: User exited."

getuserandpass || error "ERROR: User exited."

usercheck || error "ERROR: User exited."

setprogs || error "ERROR: User exited."

preinstallmsg || error "ERROR: User existed."

##### The rest of the script requires no user input.

refreshkeys || error "ERROR: Could not refresh Arch keyring automatically. Consider doing so manually."

for x in curl ca-certificates base-devel git zsh; do
        whiptail --title "MARS Installation" \
                --infobox "Installing \`$x\` which is required to install and configure other programs." 8 70
        installpkg "$x"
done

whiptail --title "LARBS Installation" \
        --infobox "Syncronizing system time to secure successful and secure installation of software..." 8 70
ntpupdate 0.us.pool.ntp.org >/dev/null 2>&1

adduserandpass || error "ERROR: Could not add user and/or password."

whiptail --title "MARS Installation" \
        --infobox "Giving user sudo permission with no password for installing AUR packages." 8 70
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers
trap "rm -f /etc/sudoers.d/mars-temp" HUP INT QUIT TERM PWR EXIT
echo "$name ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/mars-temp

whiptail --title "MARS Installation" \
        --infobox "Adding color to pacman and some other pacman settings." 8 70
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf

whiptail --title "MARS Installation" \
        --infobox "Using all cpu cores for compilation." 8 70
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

manualinstall "$aurhelper" || error "ERROR: Failed to install AUR helper."

installationloop

whiptail --title "MARS Installation" \
        --infobox "Finally, installing \`libxft-bgra\` to enable color emoji in suckless software without crashes." 8 70
pacman -Qs libxft-bgra ||
        yes | sudo -u "$name" $aurhelper -S libxft-bgra-git >/dev/null 2>&1


putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"

whiptail --title "MARS Installation" \
        --infobox "Removing unnecessary files." 8 70
rm -rf  "/home/$name/.git" "/home/$name/README.md" "/home/$name/LICENSE" \
        "/home/$name/mars.sh" "/home/$name/progs" "/home/$name/.lesshst" \
        "/home/$name/.bashrc" "/home/$name/.bash_logout" "/home/$name/.bash_profile"


whiptail --title "MARS Installation" \
        --infobox "Changing user's default shell." 8 70
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh" "/home/$name/.cache/bash"
# TODO: add all the file moves and corrections here

whiptail --title "MARS Installation" \
        --infobox "Moving directories where they belong." 8 70
[ -d "/home/$name/.cargo" ] && mv "/home/$name/.cargo" "/home/$name/.local/share/cargo"

whiptail --title "MARS Installation" \
        --infobox "Replacing \`vim\` with \`nvim\`." 8 70
[ -x "$(command -v vim)" ] && pacman -Rns vim
ln -sf /usr/bin/nvim /usr/bin/vim

doominstall || error "ERROR: Failed to install doomemacs."

whiptail --title "MARS Installation" \
        --infobox "Configuring \`ly\` the TUI display manager." 8 70
sed -Ei "/^#animate = true$/s/#//;
        s/.*animation = 0/animation = 1/;
        /^#blank_password = true/s/#//;
        /^#hide_f1_commands = true/s/#//;
        s/^#shutdown_cmd = .*/shutdown_cmd = \/sbin\/shutdown -h now/" /etc/ly/config.ini

systemctl enable ly

whiptail --title "MARS Installation" \
        --infobox "Configuring \`GRUB\` bootloader." 8 70
sed -Ei "/^#GRUB_DISABLE_SUBMENU.*/s/#//; \
         /^#GRUB_GFXMODE=auto$/s/#//; \
         /^#GRUB_SAVEDEFAULT=true$/s/#//; \
         s/^GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"resume=/dev/nvme0n1p4\"/;" /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1

whiptail --title "MARS Installation" \
        --infobox "Generating dbus UUID." 8 70
dbus-uuidgen >/var/lib/dbus/machine-id

whiptail --title "MARS Installation" \
        --infobox "Updating files database for pacman." 8 70
pacman --noconfirm -Fy >/dev/null 2>&1 || error "ERROR: Failed to update files database for pacman."

whiptail --title "MARS Installation" \
        --infobox "Using system notification for brave on Artix." 8 70
echo "export \$(dbus-launch)" >/etc/profile.d/dbus.sh

whiptail --title "MARS Installation" \
        --infobox "Enabling taping for touchpads." 8 70
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
    # Enable left mouse button by tapping
    Option "Tapping" "on"
EndSection' >/etc/X11/xorg.conf.d/40-libinput.conf

whiptail --title "MARS Installation" \
        --infobox "Setting correct sudo permissions." 8 70
echo "$name ALL=(ALL) ALL #MARS" >/etc/sudoers.d/mars-user-can-sudo
echo "$name ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend, /usr/bin/systemctl hibernate,/usr/bin/pacman -Syu, /usr/bin/pacman -Syyu" >/etc/sudoers.d/mars-cmds-without-password

whiptail --title "MARS Installation" \
        --infobox "Adding a .date file to log when the system get installed." 8 70
date >> /etc/installation.date

finalize
