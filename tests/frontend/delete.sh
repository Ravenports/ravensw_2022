#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	delete_all \
	delete_ravensw \
	delete_with_directory_owned \
	simple_delete \
	simple_delete_prefix_ending_with_slash

delete_all_body() {
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "foo" "foo" "1"
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "ravensw" "ravensw:standard" "1"
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "test" "test" "1"

	atf_check -o ignore ravensw register -M foo.ucl
	atf_check -o ignore ravensw register -M ravensw.ucl
	atf_check -o ignore ravensw register -M test.ucl

	atf_check -o ignore ravensw delete -ay
}

delete_ravensw_body() {
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "ravensw" "ravensw:standard" "1"
	atf_check -o ignore ravensw register -M ravensw.ucl
	atf_check -o ignore -e ignore -s exit:0 -o match:"Cannot delete ravensw itself without force flag" ravensw delete -y ravensw:standard
	atf_check -o ignore -e ignore ravensw delete -yf ravensw:standard
}

simple_delete_body() {
	touch file1
	mkdir dir
	touch dir/file2

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "test" "test" "1" "${TMPDIR}"
	cat << EOF >> test.ucl
files: {
    ${TMPDIR}/file1: "",
    ${TMPDIR}/dir/file2: "",
}
EOF

	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -M test.ucl

	atf_check \
		-o match:".*Deinstalling.*" \
		-e empty \
		-s exit:0 \
		ravensw delete -y test

	test -f file1 && atf_fail "'file1' still present"
	test -f dir/file2 && atf_fail "'dir/file2' still present"
	test -d dir && atf_fail "'dir' still present"
	test -d ${TMPDIR} || atf_fail "Prefix have been removed"
}

simple_delete_prefix_ending_with_slash_body() {
	touch file1
	mkdir dir
	touch dir/file2

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "test" "test" "1" "${TMPDIR}/"
	cat << EOF >> test.ucl
files: {
    ${TMPDIR}/file1: "",
    ${TMPDIR}/dir/file2: "",
}
EOF

	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -M test.ucl

	atf_check \
		-o match:".*Deinstalling.*" \
		-e empty \
		-s exit:0 \
		ravensw delete -y test

	test -f file1 && atf_fail "'file1' still present"
	test -f dir/file2 && atf_fail "'dir/file2' still present"
	test -d dir && atf_fail "'dir' still present"
	test -d ${TMPDIR} || atf_fail "Prefix have been removed"
}

delete_with_directory_owned_body() {
	touch file1
	mkdir dir
	touch dir/file2

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "test" "test" "1" "${TMPDIR}/"
	cat << EOF >> test.ucl
files: {
    ${TMPDIR}/file1: "",
    ${TMPDIR}/dir/file2: "",
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw "test2" "test2" "1" "${TMPDIR}/"
	cat << EOF >> test2.ucl
directories: {
    ${TMPDIR}/dir: 'y',
}
EOF
	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -M test.ucl

	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -M test2.ucl

	atf_check \
		-o match:".*Deinstalling.*" \
		-e empty \
		-s exit:0 \
		ravensw delete -y test

	test -f file1 && atf_fail "'file1' still present"
	test -f dir/file2 && atf_fail "'dir/file2' still present"
	test -d dir || atf_fail "'dir' has been removed"

	atf_check \
		-o match:".*Deinstalling.*" \
		-e empty \
		-s exit:0 \
		ravensw delete -y test2

	test -d dir && atf_fail "'dir' still present"
	test -d ${TMPDIR} || atf_fail "Prefix has been removed"
}
