# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES="
	aho-corasick@1.1.4
	anstream@1.0.0
	anstyle-parse@1.0.0
	anstyle-query@1.1.5
	anstyle-wincon@3.0.11
	anstyle@1.0.14
	cfg-if@1.0.4
	colorchoice@1.0.5
	dirs-sys@0.5.0
	dirs@6.0.0
	env_filter@1.0.1
	env_logger@0.11.10
	equivalent@1.0.2
	getrandom@0.2.17
	hashbrown@0.17.1
	indexmap@2.14.0
	is_terminal_polyfill@1.70.2
	jiff-static@0.2.28
	jiff@0.2.28
	libc@0.2.186
	libredox@0.1.17
	log@0.4.32
	memchr@2.8.1
	once_cell_polyfill@1.70.2
	option-ext@0.2.0
	portable-atomic-util@0.2.7
	portable-atomic@1.13.1
	proc-macro2@1.0.106
	quote@1.0.45
	redox_users@0.5.2
	regex-automata@0.4.14
	regex-syntax@0.8.10
	regex@1.12.3
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	serde_regex@1.2.0
	serde_spanned@1.1.1
	syn@2.0.117
	thiserror-impl@2.0.18
	thiserror@2.0.18
	toml@1.1.2+spec-1.1.0
	toml_datetime@1.1.1+spec-1.1.0
	toml_parser@1.1.2+spec-1.1.0
	toml_writer@1.1.1+spec-1.1.0
	unicode-ident@1.0.24
	utf8parse@0.2.2
	wasi@0.11.1+wasi-snapshot-preview1
	windows-link@0.2.1
	windows-sys@0.61.2
	winnow@1.0.3
"

inherit cargo

DESCRIPTION="Adblocker for Spotify"
HOMEPAGE="https://github.com/abba23/spotify-adblock/"
SRC_URI="
	https://github.com/abba23/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${CARGO_CRATE_URIS}
"

LICENSE="GPL-3 MIT Unicode-DFS-2016"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	media-sound/spotify
"

src_prepare(){
	default
	# assigned here to use get_libdir
	QA_FLAGS_IGNORED="usr/$(get_libdir)/${PN}.so"
}

src_install(){
	# executable
	SPOTIFY_HOME=/opt/spotify/spotify-client
	cat <<-EOF > "${T}/spotify-adblock" || die
		#! /bin/sh
		LD_LIBRARY_PATH="${SPOTIFY_HOME}" \\
		LD_PRELOAD=/usr/$(get_libdir)/spotify-adblock.so \\
		exec ${SPOTIFY_HOME}/spotify "\$@"
	EOF
	dobin "${T}/spotify-adblock"

	# library
	newlib.so "$(cargo_target_dir)/libspotifyadblock.so" "${PN}.so"

	# config
	insinto "/etc/${PN}"
	doins config.toml
}
