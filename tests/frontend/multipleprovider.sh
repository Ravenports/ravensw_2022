#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	multiple_providers

multiple_providers_body() {
	touch file

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw1 test1 1
	cat << EOF >> ravensw1.ucl
shlibs_provided [
	"lib1.so.6"
]
files: {
	${TMPDIR}/file: ""
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw2 dep 1
	cat << EOF >> ravensw2.ucl
shlibs_required [
	"lib1.so.6"
]
deps: {
	test1 {
		origin: test
		version: 1
	}
}
EOF

	for p in ravensw1 ravensw2; do
		atf_check \
			-o match:".*Installing.*\.\.\.$" \
			-e empty \
			-s exit:0 \
			ravensw register -M ${p}.ucl
	done

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw3 test1 1_0
	cat << EOF >> ravensw3.ucl
shlibs_provided [
	"lib1.so.6"
]
files: {
	${TMPDIR}/file: ""
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw4 test2 1
	cat << EOF >> ravensw4.ucl
shlibs_provided [
	"lib1.so.6"
]
files: {
	${TMPDIR}/file: ""
}
EOF

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest ravensw5 dep 1_1
	cat << EOF >> ravensw5.ucl
shlibs_required [
	"lib1.so.6"
]
deps: {
	test2 {
		origin: test
		version: 1
	}
}
EOF

	for p in ravensw3 ravensw4 ravensw5; do
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
}

