# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A low poly 3D model editor"
HOMEPAGE="www.blockbench.net"
SRC_URI="https://github.com/JannisX11/blockbench/releases/download/v${PV}/Blockbench_5.2.2.deb"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"

DEPEND="
		app-accessibility/at-spi2-core
		app-crypt/libsecret
		dev-libs/nss
		x11-libs/gtk+:3
		x11-libs/libnotify
		x11-libs/libXtst
		x11-misc/xdg-utils
"
RDEPEND="${DEPEND}"

S="${WORKDIR}"

src_unpack() {
		default
		unpack "${WORKDIR}"/data.tar.xz

		# Docs just provide the changelog, it's not important to have them.
		rm -r usr/share/doc || die
}

src_install() {
		insinto /
		doins -r opt/
		doins -r usr/

		chmod +x "${ED}"/opt/Blockbench/blockbench || die
}
