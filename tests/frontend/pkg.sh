#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	ravensw_no_database \
	ravensw_config_defaults \
	ravensw_create_manifest_bad_syntax \
	ravensw_repo_load_order

ravensw_no_database_body() {
        atf_skip_on Linux Test fails on Linux

	atf_check \
	    -o empty \
	    -e inline:"package database non-existent\n" \
	    -s exit:69 \
	    env -i PATH="${PATH}" DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}" LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" ravensw -o RAVENSW_DBDIR=/dev/null -N
}

ravensw_config_defaults_body()
{
	atf_check \
	    -o match:'^ *RAVENSW_DBDIR = "/var/db/ravensw";$' \
	    -o match:'^ *RAVENSW_CACHEDIR = "/var/cache/ravensw";$' \
	    -o match:'^ *PORTSDIR = "/usr/d?ports";$' \
	    -o match:'^ *HANDLE_RC_SCRIPTS = false;$' \
	    -o match:'^ *DEFAULT_ALWAYS_YES = false;$' \
	    -o match:'^ *ASSUME_ALWAYS_YES = false;$' \
	    -o match:'^ *PLIST_KEYWORDS_DIR = "";$' \
	    -o match:'^ *SYSLOG = true;$' \
	    -o match:'^ *ALTABI = "[a-zA-Z0-9]+:[a-z\.A-Z0-9]+:[a-zA-Z0-9]+:[a-zA-Z0-9:]+";$' \
	    -o match:'^ *DEVELOPER_MODE = false;$' \
	    -o match:'^ *VULNXML_SITE = "http://www.ravenports.com/vuln/vuln.xml.bz2";$' \
	    -o match:'^ *FETCH_RETRY = 3;$' \
	    -o match:'^ *PKG_PLUGINS_DIR = ".*lib/ravensw/";$' \
	    -o match:'^ *PKG_ENABLE_PLUGINS = true;$' \
	    -o match:'^ *DEBUG_SCRIPTS = false;$' \
	    -o match:'^ *PLUGINS_CONF_DIR = ".*/etc/ravensw/";$' \
	    -o match:'^ *PERMISSIVE = false;$' \
	    -o match:'^ *REPO_AUTOUPDATE = true;$' \
	    -o match:'^ *NAMESERVER = "";$' \
	    -o match:'^ *EVENT_PIPE = "";$' \
	    -o match:'^ *FETCH_TIMEOUT = 30;$' \
	    -o match:'^ *UNSET_TIMESTAMP = false;$' \
	    -o match:'^ *SSH_RESTRICT_DIR = "";$' \
	    -e empty              \
	    -s exit:0             \
	    env -i PATH="${PATH}" DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}" LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" ravensw -C "" -R "" -vv
}

ravensw_create_manifest_bad_syntax_body()
{
	mkdir -p testravensw/.metadir
	cat <<EOF >> testravensw/.metadir/+MANIFEST
name: test
version: 1
origin: test
prefix: /raven
categories: [test]
comment: this is a test
maintainer: test
www: http://test
desc: <<EOD
A description
EOD
files:
  /raven/include/someFile.hp: 'sha256sum' p
EOF
	atf_check \
	    -o empty \
	    -e inline:"Bad format in manifest for key: files\n" \
	    -s exit:70 \
	    ravensw create -q -m testravensw/.metadir -r testravensw
}

ravensw_repo_load_order_body()
{
	echo "03_repo: { url: file:///03_repo }" > plop.conf
	echo "02_repo: { url: file:///02_repo }" > 02.conf
	echo "01_repo: { url: file:///01_repo }" > 01.conf

	out=$(ravensw -o REPOS_DIR=. -vv)
	atf_check \
	    -o match:'.*01_repo\:.*02_repo\:.*03_repo\:.*' \
	    -e empty \
	    -s exit:0 \
	    echo $out
}
