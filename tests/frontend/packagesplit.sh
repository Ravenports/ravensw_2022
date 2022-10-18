#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	package_split

package_split_body() {
	touch file1
	touch file2

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw1 test 1
	cat << EOF >> ravensw1.ucl
files: {
	${TMPDIR}/file1: "",
	${TMPDIR}/file2: "",
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest dep1 master 1
	cat << EOF >> dep1.ucl
deps: {
	test {
		origin: test,
		version: 1
	}
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw2 sub-test 1
	cat << EOF >> ravensw2.ucl
files: {
	${TMPDIR}/file1: "",
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw3 sub-test2 1
	cat << EOF >> ravensw3.ucl
files: {
	${TMPDIR}/file2: "",
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw4 test 1
	cat << EOF >> ravensw4.ucl
deps: {
	sub-test: {
		origin: test,
		version: 1
	},
	sub-test2: {
		origin: test,
		version: 1
	}
}
EOF

	for p in ravensw1 dep1; do
		atf_check \
		    -o match:".*Installing.*\.\.\.$" \
		    -e empty \
		    -s exit:0 \
		    ravensw register -M ${p}.ucl
	done

	for p in dep1 ravensw2 ravensw3 ravensw4; do
		atf_check \
		    -o ignore \
		    -e empty \
		    -s exit:0 \
		    ravensw create -M ./${p}.ucl
	done

	atf_check \
	    -o inline:"Creating repository in .:  done\nPacking files for repository:  done\n" \
	    -e empty \
	    -s exit:0 \
	    ravensw repo .

	cat << EOF > repo.conf
local: {
	url: file:///$TMPDIR,
	enabled: true
}
EOF
	atf_check \
	    -o ignore \
	    -s exit:0 \
	    ravensw -o REPOS_DIR="$TMPDIR" -o RAVENSW_CACHEDIR="$TMPDIR" upgrade -y

	test -f file1 || atf_fail "file1 is not present"
}
