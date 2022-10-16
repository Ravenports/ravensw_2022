#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	set_automatic \
	set_change_name \
	set_change_origin \
	set_vital

initialize_ravensw() {

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw test test 1
	sed -i'' -e 's#origin.*#origin: origin/test#' test.ucl

	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -t -M test.ucl
}

set_automatic_body() {
	initialize_ravensw

	atf_check \
		-o inline:"0\n" \
		-e empty \
		-s exit:0 \
		ravensw query "%a" test

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw set -y -A 1 test

	atf_check \
		-o inline:"1\n" \
		-e empty \
		-s exit:0 \
		ravensw query "%a" test

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw set -y -A 0 test

	atf_check \
		-o inline:"0\n" \
		-e empty \
		-s exit:0 \
		ravensw query "%a" test
}

set_change_name_body() {
	initialize_ravensw

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw set -yn test:new

	atf_check \
		-o inline:"new-1\n" \
		-e empty \
		-s exit:0 \
		ravensw info -q
}

set_change_origin_body() {
	initialize_ravensw

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw set -yo origin/test:neworigin/test

	atf_check \
		-o inline:"neworigin/test\n" \
		-e empty \
		-s exit:0 \
		ravensw info -qo
}

set_vital_body() {
	initialize_ravensw

	atf_check \
		-o inline:"0\n" \
		-e empty \
		-s exit:0 \
		ravensw query "%V" test

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw set -y -v 1 test

	atf_check \
		-o inline:"1\n" \
		-e empty \
		-s exit:0 \
		ravensw query "%V" test

	atf_check \
		-o empty \
		-e empty \
		-s exit:0 \
		ravensw set -y -v 0 test

	atf_check \
		-o inline:"0\n" \
		-e empty \
		-s exit:0 \
		ravensw query "%V" test
}
