# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="A clone of Transport Tycoon Deluxe - JGR Patch Pack"
HOMEPAGE="https://www.openttd.org/"
SRC_URI="https://github.com/JGRennison/OpenTTD-patches/archive/refs/tags/jgrpp-${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="~amd64"
LICENSE="GPL-2"
SLOT="0"
IUSE="allegro cpu_flags_x86_sse debug dedicated +fluidsynth icu +lzma lzo +openmedia +png +sdl timidity +truetype +zlib"
REQUIRED_USE="!dedicated? ( || ( allegro sdl ) )"

RDEPEND="
	net-misc/curl
	dedicated? (
		acct-group/openttd
		acct-user/openttd
		app-misc/dtach
	)
	!dedicated? (
		allegro? ( media-libs/allegro:5 )
		fluidsynth? ( media-sound/fluidsynth )
		icu? (
			>=dev-libs/icu-58.1:=
			media-libs/harfbuzz
		)
		sdl? ( media-libs/libsdl2[sound,video] )
		truetype? (
			media-libs/fontconfig
			media-libs/freetype:2
			sys-libs/zlib:=
		)
	)
	lzma? ( app-arch/xz-utils )
	lzo? ( dev-libs/lzo:2 )
	png? ( media-libs/libpng:= )
	zlib? ( sys-libs/zlib:= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=games-util/grfcodec-6.0.6_p20210310
	virtual/pkgconfig
"
PDEPEND="
	!dedicated? (
		openmedia? (
			>=games-misc/openmsx-0.4.0
			>=games-misc/opensfx-1.0.1
		)
	)
	openmedia? ( >=games-misc/opengfx-0.6.1 )
	timidity? ( media-sound/timidity++ )
"

S="${WORKDIR}/OpenTTD-patches-jgrpp-${PV}"

DOCS=( docs/directory_structure.md )

PATCHES=(
	"${FILESDIR}/${PN}-0.68.0-fix-rev.patch"
)

src_prepare() {
	# Drop automagic LTO usage
	sed -i -e '/check_ipo_supported(RESULT IPO_FOUND)/d' CMakeLists.txt || die

	# Don't force _FORTIFY_SOURCE via CMake
	# (we already set it in the toolchain by default with a minimum level
	# of _FORTIFY_SOURCE=2)
	sed -i -e '/-D_FORTIFY_SOURCE/d' cmake/CompileFlags.cmake || die

	cmake_src_prepare
}

src_configure() {
	einfo "Checking version detection..."
	grep -r "GIT_DESCRIBE\\|VERSION\\|git" CMakeLists.txt cmake/ | head -20

	local mycmakeargs=(
		-DBINARY_NAME="openttd-jgrpp"
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_BINDIR=bin
		-DCMAKE_INSTALL_DATADIR=share
		-DOPTION_DEDICATED=$(usex dedicated)
		-DOPTION_USE_ASSERTS=$(usex debug)
		-DCMAKE_DISABLE_FIND_PACKAGE_Allegro=$(usex !allegro)
		-DCMAKE_DISABLE_FIND_PACKAGE_Freetype=$(usex !truetype)
		-DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=$(usex !truetype)
		-DCMAKE_DISABLE_FIND_PACKAGE_Fluidsynth=$(usex !fluidsynth)
		-DCMAKE_DISABLE_FIND_PACKAGE_ICU=$(usex !icu)
		-DCMAKE_DISABLE_FIND_PACKAGE_Harfbuzz=$(usex !icu)
		-DCMAKE_DISABLE_FIND_PACKAGE_LibLZMA=$(usex !lzma)
		-DCMAKE_DISABLE_FIND_PACKAGE_LZO=$(usex !lzo)
		-DCMAKE_DISABLE_FIND_PACKAGE_PNG=$(usex !png)
		# N.B. regarding #807364 and #828984: CMAKE_DISABLE_FIND_PACKAGE_SDL is used only
		# with USE="allegro -sdl" combination flags. There no other way to
		# completely disable SDL1 support.
		-DCMAKE_DISABLE_FIND_PACKAGE_SDL=ON
		-DCMAKE_DISABLE_FIND_PACKAGE_SDL2=$(usex !sdl)
		-DCMAKE_DISABLE_FIND_PACKAGE_SSE=$(usex !cpu_flags_x86_sse)
		-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=$(usex !zlib)
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	if use dedicated ; then
		newconfd "${FILESDIR}"/openttd-jgrpp.confd-r1 openttd-jgrpp
		newinitd "${FILESDIR}"/openttd-jgrpp.initd-r3 openttd-jgrpp
		sed -i -e 's|OPENTTD_BINARY="openttd"|OPENTTD_BINARY="openttd-jgrpp"|' \
            "${ED}/etc/init.d/openttd-jgrpp" || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if ! use openmedia ; then
		elog
		elog "OpenTTD was compiled without the 'openmedia' USE flag."
		elog
		elog "In order to play, you must at least install"
		elog "games-misc/opengfx, and games-misc/opensfx, or copy the "
		elog "following 6 files from a version of Transport Tycoon Deluxe"
		elog "(Windows or DOS) to shared or personal location."
		elog "See ${EROOT}/usr/share/doc/${PF}/directory_structure.md for more info."
		elog
		elog "From the Windows version you need: "
		elog "sample.cat trg1r.grf trgcr.grf trghr.grf trgir.grf trgtr.grf"
		elog "OR from the DOS version you need: "
		elog "SAMPLE.CAT TRG1.GRF TRGC.GRF TRGH.GRF TRGI.GRF TRGT.GRF"
	fi

	elog
	elog "As of OpenTTD 14.0 and later, integrations have been added;"
	elog "Slight caveat - those need to be installed manually."
	elog "The integrations are for Steam, Discord, and GOG Galaxy."
	elog
	elog "If you use one of those platforms and you wish for the game"
	elog "to utilize these integrations, go to the following links for:"
	elog
	elog "Discord:"
	elog "https://www.openttd.org/downloads/discord-social-releases/latest"
	elog
	elog "GOG Galaxy:"
	elog "https://www.openttd.org/downloads/gog-galaxy-social-releases/latest"
	elog
	elog "Steam:"
	elog "https://www.openttd.org/downloads/steam-social-releases/latest"
	elog
	elog "Simply extract the contents of the file inside of the tarball to"
	elog "\$XDG_RUNTIME_DIR/${PN}/social_integrations"
	elog "while the game is off, and optionally toggle them in the main"
	elog "menu."
	elog
}
