#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	dead_symlink \
	good_symlink


dead_symlink_body() {
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest "test" "test" "1"
	cat << EOF >> test.ucl
directories {
	${TMPDIR}/plop = "y";
}
EOF
	mkdir ${TMPDIR}/plop
	atf_check \
		ravensw create -M test.ucl

	rmdir ${TMPDIR}/plop
	ln -sf ${TMPDIR}/plop2 ${TMPDIR}/plop
	atf_check \
		-o ignore \
		ravensw -o REPOS_DIR=/dev/null install -y ${TMPDIR}/test-1.tzst
	test -d ${TMPDIR}/plop || atf_fail "directory not created"
}

good_symlink_body() {
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest "test" "test" "1"
	cat << EOF >> test.ucl
directories {
	${TMPDIR}/plop = "y";
}
EOF
	mkdir ${TMPDIR}/plop
	atf_check \
		ravensw create -M test.ucl

	rmdir ${TMPDIR}/plop
	mkdir ${TMPDIR}/plop2
	ln -sf ${TMPDIR}/plop2 ${TMPDIR}/plop
	atf_check \
		-o ignore \
		ravensw -o REPOS_DIR=/dev/null install -y ${TMPDIR}/test-1.tzst
	test -h ${TMPDIR}/plop || atf_fail "Symlink deleted"
}
