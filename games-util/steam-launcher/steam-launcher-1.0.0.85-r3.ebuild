# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Please report bugs/suggestions on: https://github.com/anyc/steam-overlay
# or come to #gentoo-games in Libera Chat IRC

inherit desktop linux-info pax-utils prefix xdg

DESCRIPTION="Installer, launcher and supplementary files for Valve's Steam client"
HOMEPAGE="https://store.steampowered.com"
SRC_URI="https://repo.steampowered.com/steam/archive/stable/steam_${PV}.tar.gz"
S="${WORKDIR}/${PN}"

LICENSE="ValveSteamLicense MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+desktop-portal +dialogs +joystick +pulseaudio steamvr trayicon +udev video_cards_nvidia +vulkan wayland"
RESTRICT="bindist mirror test"

# This can help to determine the dependencies:
# find ~/.steam/root/ -exec readelf -d {} + 2>/dev/null | grep -F NEEDED | sort -u | grep -F -v -f <(ls -1 ~/.steam/root/ubuntu12_32/)

RDEPEND="
	app-alternatives/tar
	app-arch/xz-utils
	app-shells/bash
	media-libs/fontconfig
	media-libs/mesa[opengl,X]
	sys-libs/libudev-compat
	sys-process/lsof
	virtual/opengl
	virtual/ttf-fonts
	x11-libs/libdrm
	!sys-apps/dbus[-X]
	!x11-libs/cairo[-X]

	desktop-portal? ( sys-apps/xdg-desktop-portal )
	pulseaudio? ( media-libs/libpulse )
	!pulseaudio? ( media-sound/apulse )
	steamvr? ( sys-apps/usbutils )
	vulkan? ( media-libs/vulkan-loader[wayland?,X] )

	joystick? (
		udev? ( games-util/game-device-udev-rules )
		wayland? ( || (
			x11-libs/extest
			>=x11-base/xwayland-23.2.1[libei(+)]
		) )
	)

	>=sys-devel/gcc-4.6.0
	>=sys-libs/glibc-2.15
"

PATCHES=(
	"${FILESDIR}"/apply-steam-non-gtar.patch
)

pkg_setup() {
	linux-info_pkg_setup

	if ! { linux_config_exists && linux_chkconfig_present INPUT_UINPUT; }; then
		ewarn "If you want to use Steam Input's virtual controller"
		ewarn "implementation, please make sure CONFIG_INPUT_UINPUT"
		ewarn "is enabled in your kernel config."

		# Device Drivers
		#  -> Input device support
		#   -> Miscellaneous devices
		#    -> User level driver support
	fi
}

lib_path_entries() {
	while true; do
		echo -n ${EPREFIX}/usr/\\\\\${LIB}/${1}
		shift

		if [[ -n ${1} ]]; then
			echo -n :
		else
			break
		fi
	done
}

src_prepare() {
	default

	sed \
		-e "s#@@PVR@@#${PVR}#g" \
		-e "s#@@GENTOO_LD_LIBRARY_PATH@@#$(lib_path_entries debiancompat fltk)#g" \
		-e "s#@@GENTOO_X86_LIBDIR@@#${EPREFIX}/usr/$(ABI=x86 get_libdir)#g" \
		-e "s#@@STEAM_RUNTIME@@#1#g" \
		"${FILESDIR}"/steam-wrapper.sh > steam-wrapper.sh || die

	# Still need EPREFIX in the sed replacements above because the
	# regular expression used by hprefixify doesn't match there.
	hprefixify bin_steam.sh steam-wrapper.sh

	# Allow the desktop launcher to use wrappers from the PATH.
	sed -i "s:/usr/bin/::g" steam.desktop || die
}

src_install() {
	emake install-{icons,bootstrap} \
		  DESTDIR="${D}" PREFIX="${EPREFIX}/usr"

	newbin steam-wrapper.sh steam
	exeinto /usr/lib/steam
	doexe bin_steam.sh
	domenu steam.desktop

	insinto /usr/lib/steam
	doins "${FILESDIR}"/steam-non-gtar.patch

	dodoc README debian/changelog
	doman steam.6
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Execute ${EPREFIX}/usr/bin/steam to download and install the actual"
	elog "client into your home folder. After installation, the script"
	elog "also starts the client from your home folder."
	elog ""

	ewarn "The Steam client and the games are _not_ controlled by Portage."
	ewarn "Updates are handled by the client itself."
	ewarn ""

	if ! use desktop-portal; then
		ewarn "You have disabled desktop-portal, which is not supported."
		ewarn "An xdg-desktop-portal backend is needed for file pickers"
		ewarn "and other desktop components to work, e.g. when adding a"
		ewarn "non-Steam game or a new library folder."
		ewarn ""
	fi

	if ! has_version "gnome-extra/zenity"; then
		ewarn "Valve does not provide a xterm fallback for all calls of zenity."
		ewarn "Please install gnome-extra/zenity for full support."
		ewarn ""
	fi

	if host-is-pax; then
		elog "If you're using PAX, please see:"
		elog "https://wiki.gentoo.org/wiki/Steam#Hardened_Gentoo"
		elog ""
	fi
}
