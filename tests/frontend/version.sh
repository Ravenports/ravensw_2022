#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	version \
	compare

version_body() {
	atf_check -o inline:"<\n" -s exit:0 ravensw version -t 1 2
	atf_check -o inline:">\n" -s exit:0 ravensw version -t 2 1
	atf_check -o inline:"=\n" -s exit:0 ravensw version -t 2 2
	atf_check -o inline:"<\n" -s exit:0 ravensw version -t 2 1,1
}

compare_body() {
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw test test 5.20_3

	atf_check \
		-o match:".*Installing.*" \
		ravensw register -M test.ucl
	atf_check \
		-o ignore \
		ravensw info "test>0"
	atf_check \
		-o ignore \
		-e ignore \
		-s exit:70 \
		ravensw info "test<5"
	atf_check \
		-o ignore \
		ravensw info "test>5<6"
	atf_check \
		-o ignore \
		-e ignore \
		-s exit:70 \
		ravensw info "test>5<5.20"
	atf_check \
		-o ignore \
		-e ignore \
		-s exit:70 \
		ravensw info "test>5.20_3<6"
}
