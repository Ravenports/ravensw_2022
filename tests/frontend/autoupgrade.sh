#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	autoupgrade \
	autoupgrade_multirepo

autoupgrade_body() {
	atf_skip_on Linux Test fails on Linux

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw ravensw1 ravensw:standard 1
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw ravensw2 ravensw:standard 1_1

	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -M ravensw1.ucl

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -M ./ravensw2.ucl

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
		-o match:".*New version of ravensw detected.*" \
		-s exit:1 \
		ravensw -o REPOS_DIR="$TMPDIR" -o RAVENSW_CACHEDIR="$TMPDIR" upgrade -n
}

autoupgrade_multirepo_head() {
	atf_set "timeout" 40
}

autoupgrade_multirepo_body() {

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw ravensw1 ravensw:standard 1
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw ravensw2 ravensw:standard 1.1

	atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -M ravensw1.ucl

	mkdir repo1 repo2

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -M ./ravensw1.ucl -o repo1

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -M ./ravensw2.ucl -o repo2

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw repo repo1

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw repo repo2

	cat << EOF > repo.conf
repo1: {
	url: file:///$TMPDIR/repo1,
	enabled: true
}
repo2: {
	url: file:///$TMPDIR/repo2,
	enabled: true
}
EOF

	export REPOS_DIR="${TMPDIR}"
	atf_check \
		-o ignore \
		-s exit:0 \
		ravensw install -r repo1 -fy ravensw:standard-1

	atf_check \
		-o match:".*New version of ravensw detected.*" \
		-s exit:0 \
		ravensw upgrade -y

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw upgrade -y
}

