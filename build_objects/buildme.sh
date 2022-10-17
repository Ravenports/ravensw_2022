#!/bin/sh
#
# Manually build ravensw (for testing purposes)
#
# shellcheck disable=SC3043

DPATH=$(dirname "$0")
BLDOBJDIR=$(cd "${DPATH}" && pwd -P)
# SQLITE_YEAR=2022
# SQLITE_VERSION=3390400
SQLITE_YEAR=2019
SQLITE_VERSION=3280000

obtain_sqlite () {
	local sqlite_filename="sqlite-autoconf-${SQLITE_VERSION}.tar.gz"
	local url="https://www.sqlite.org/${SQLITE_YEAR}/${sqlite_filename}"

	if [ -f "${BLDOBJDIR}/${sqlite_filename}" ]; then
		echo "sqlite already downloaded."
	else
		fetch "$url"
	fi
}

extract_sqlite () {
	local vendordir="${BLDOBJDIR}/../vendor"
	local sqlite3dir="${vendordir}/sqlite3"
	local sqlite="sqlite-autoconf-${SQLITE_VERSION}"
	local sqlite_filename="${sqlite}.tar.gz"

	if [ -f "${BLDOBJDIR}/${sqlite_filename}" ]; then
		rm -rf "${sqlite3dir}"
		(cd "${vendordir}" && tar -xf "${BLDOBJDIR}/${sqlite_filename}")
		mv "${vendordir}/${sqlite}" "${sqlite3dir}" 
	else
		echo "Failed to download sqlite"
		exit 1
	fi
}

execute_makefile () {
	(cd "${BLDOBJDIR}/.." && make)
}

subcheck ()
{
	local desc="$1"
	local prpath="$2"

	if [ ! -f "$prpath" ]; then
		echo "The ${desc} prerequisite is missing"
		exit 1
	fi
}

check_prerequisites()
{
	local linenoise="/raven/include/linenoise.h"
	local gprbuild="/raven/bin/gprbuild"
	local libucl="/raven/lib/libucl_pic.a"
	local libelf="/raven/lib/libelf_pic.a"
	local libarchive="/raven/lib/libarchive_pic.a"
	local libzstd="/raven/lib/libzstd_pic.a"
	local libfetch="/raven/lib/libfetch_pic.a"
	local libblake3="/raven/lib/libblake3_pic.a"
	local libssl="/raven/libressl/lib/libssl_pic.a"
	local libcrypto="/raven/libressl/lib/libcrypto_pic.a"

	subcheck "linenoise" "${linenoise}"
	subcheck "gprbuild" "${gprbuild}"
	subcheck "libucl" "${libucl}"
	subcheck "libelf" "${libelf}"
	subcheck "libarchive" "${libarchive}"
	subcheck "libzstd" "${libzstd}"
	subcheck "libfetch" "${libfetch}"
	subcheck "libblake3" "${libblake3}"
	subcheck "libssl" "${libssl}"
	subcheck "libcrypto" "${libcrypto}"
}

preclean()
{
	(cd "${BLDOBJDIR}/.." && make clean)
}

check_prerequisites
obtain_sqlite
extract_sqlite
preclean
execute_makefile
