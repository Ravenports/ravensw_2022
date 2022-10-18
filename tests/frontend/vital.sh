#!/usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	vital

vital_body()
{
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest "test" "test" "1"
	cat << EOF >> test.ucl
vital = true;
EOF

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl

	atf_check \
		-o match:"^vital" \
		-e empty \
		-s exit:0 \
		ravensw info -R --raw-format ucl -F ${TMPDIR}/test-1.tzst

	mkdir ${TMPDIR}/target
	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw -o REPOS_DIR=/dev/null -r ${TMPDIR}/target install -qfy \
			${TMPDIR}/test-1.tzst

	atf_check \
		-o inline:"1\n" \
		-e empty \
		-s exit:0 \
		ravensw -o REPOS_DIR=/dev/null -r ${TMPDIR}/target query "%V" test

	atf_check \
		-o empty \
		-e inline:"Cannot delete vital package: test!\nIf you are sure you want to remove test, \nunset the 'vital' flag with: ravensw set -v 0 test\n" \
		-s exit:3 \
		ravensw -r ${TMPDIR}/target delete -qy test
	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw -r ${TMPDIR}/target delete -qyf test
}
