#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh
tests_init	\
		add \
		add_automatic \
		add_noscript \
		add_noscript \
		add_force \
		add_accept_missing \
		add_quiet \
		add_stdin \
		add_stdin_missing \
		add_no_version \
		add_no_version_multi \
		add_wrong_version

initialize_pkg() {
	touch a
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg test test 1
	cat << EOF >> test.ucl
files: {
	${TMPDIR}/a: ""
}
scripts: {
	pre-install: <<EOD
echo "pre-install"
EOD
	post-install: <<EOD
echo "post-install"
EOD
}
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl
}

add_body() {
	initialize_pkg

OUTPUT="${JAILED}Installing test-1...
pre-install
${JAILED}Extracting test-1:  done
post-install
"
	atf_check \
		-o inline:"${OUTPUT}" \
		-e empty \
		ravensw add test-1.tzst

# test automatic is not set
	atf_check \
		-o inline:"0\n" \
		-e empty \
		ravensw query "%a" test
}

add_automatic_body() {
	initialize_pkg

OUTPUT="${JAILED}Installing test-1...
pre-install
${JAILED}Extracting test-1:  done
post-install
"
	atf_check \
		-o inline:"${OUTPUT}" \
		-e empty \
		ravensw add -A test-1.tzst

	atf_check \
		-o inline:"1\n" \
		-e empty \
		ravensw query "%a" test

}

add_noscript_body() {
	initialize_pkg

OUTPUT="${JAILED}Installing test-1...
${JAILED}Extracting test-1:  done
"
	cat test-1.tzst | atf_check \
		-o inline:"${OUTPUT}" \
		-e empty \
		ravensw add -I test-1.tzst
}

add_force_body() {
	initialize_pkg
}


add_accept_missing_body() {
	touch a
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg test test 1
	cat << EOF >> test.ucl
deps: {
	b: {
		origin: "wedontcare",
		version: "1"
	}
}
files: {
	${TMPDIR}/a: ""
}
scripts: {
	pre-install: <<EOD
echo "pre-install"
EOD
	post-install: <<EOD
echo "post-install"
EOD
}
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl

	atf_check \
		-o inline:"${JAILED}Installing test-1...\n\nFailed to install the following 1 package(s): test-1.tzst\n" \
		-e inline:"${PROGNAME}: Missing dependency 'b'\n" \
		-s exit:1 \
		ravensw add test-1.tzst

OUTPUT="${JAILED}Installing test-1...
pre-install
${JAILED}Extracting test-1:  done
post-install
"
	atf_check \
		-o inline:"${OUTPUT}" \
		-e inline:"${PROGNAME}: Missing dependency 'b'\n" \
		-s exit:0 \
		ravensw add -M test-1.tzst
}

add_quiet_body() {
	initialize_pkg

	atf_check \
		-o inline:"pre-install\npost-install\n" \
		-e empty \
		ravensw add -q ./test-1.tzst
}

add_stdin_body() {
	initialize_pkg

OUTPUT="${JAILED}Installing test-1...
pre-install
${JAILED}Extracting test-1:  done
post-install
"
	cat test-1.tzst | atf_check \
		-o inline:"${OUTPUT}" \
		-e empty \
		ravensw add -
}

add_stdin_missing_body() {
	touch a
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg test test 1
	cat << EOF >> test.ucl
deps: {
	b: {
		origin: "wedontcare",
		version: "1"
	}
}
files: {
	${TMPDIR}/a: ""
}
scripts: {
	pre-install: <<EOD
echo "pre-install"
EOD
	post-install: <<EOD
echo "post-install"
EOD
}
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl

	atf_check \
		-o inline:"${JAILED}Installing test-1...\n\nFailed to install the following 1 package(s): -\n" \
		-e inline:"${PROGNAME}: Missing dependency 'b'\n" \
		-s exit:1 \
		ravensw add - < test-1.tzst

OUTPUT="${JAILED}Installing test-1...
pre-install
${JAILED}Extracting test-1:  done
post-install
"
	atf_check \
		-o inline:"${OUTPUT}" \
		-e inline:"${PROGNAME}: Missing dependency 'b'\n" \
		-s exit:0 \
		ravensw add -M - < test-1.tzst
}

add_no_version_body() {
	for p in test final ; do
		atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg ${p} ${p} 1
		if [ ${p} = "final" ]; then
			cat << EOF >> final.ucl
deps {
	test {
		origin = "test";
	}
}
EOF
		fi
		atf_check -o ignore -s exit:0 \
			ravensw create -M ${p}.ucl
	done
	atf_check -o ignore -s exit:0 \
		ravensw add final-1.tzst
}

add_no_version_multi_body() {
	for p in test final ; do
		atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg ${p} ${p} 1
		if [ ${p} = "final" ]; then
			cat << EOF >> final.ucl
deps {
	test {
		origin = "test";
	},
	pkgnotfound {
		origin = "pkgnotfound";
	}
}
EOF
		fi
		atf_check -o ignore -s exit:0 \
			ravensw create -M ${p}.ucl
	done
	atf_check -o ignore -e ignore -s exit:1 \
		ravensw add final-1.tzst
}

add_wrong_version_body() {
	for p in test final ; do
		atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_pkg ${p} ${p} 1
		if [ ${p} = "final" ]; then
			cat << EOF >> final.ucl
deps {
	test {
		origin = "test";
		version = "2";
	}
}
EOF
		fi
		atf_check -o ignore -s exit:0 \
			ravensw create -M ${p}.ucl
	done
	atf_check -o ignore -s exit:0 \
		ravensw add final-1.tzst
}
