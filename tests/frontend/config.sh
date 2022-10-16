#!/usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh
tests_init \
	empty_conf \
	duplicate_ravensws_notallowed \
	inline_repo \
	nameserver
#	duplicate_ravensws_allowed \

duplicate_ravensws_allowed_body() {
	cat << EOF > ravensw.conf
duplicatedefault: 2
EOF

	for n in 1 2; do
		atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw test${n} test ${n}
		echo 'allowduplicate: true' >> test${n}.ucl

	atf_check \
		-e empty \
		-o match:"Installing test-${n}..." \
		-s exit:0 \
		ravensw register -M test${n}.ucl
done

	atf_check \
		-e empty \
		-o match:"test-1                         a test" \
		-o match:"test-2                         a test" \
		-s exit:0 \
		ravensw info
}

duplicate_ravensws_notallowed_body() {
	for n in 1 2; do
		atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_ravensw test${n} test ${n}
	done

	atf_check \
		-e empty \
		-o match:"Installing test-1..." \
		-s exit:0 \
		ravensw register -M test1.ucl

	atf_check \
		-e empty \
		-s exit:70 \
		ravensw register -M test1.ucl

	atf_check \
		-e empty \
		-o match:"test-1                         a test" \
		-s exit:0 \
		ravensw info
}

empty_conf_body() {
	touch ravensw.conf

	cat << EOF > test.ucl
name: test
origin: test
version: 1
maintainer: test
categories: [test]
comment: a test
www: http://test
prefix: /
desc: <<EOD
Yet another test
EOD
EOF

	atf_check \
		-e empty \
		-o ignore \
		-s exit:0 \
		ravensw register -M test.ucl

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw -C ravensw.conf info test
}

inline_repo_body() {
	cat > ravenswconfiguration << EOF
repositories: {
	ravensw1: { url = file:///tmp },
	ravensw2: { url = file:///tmp2 },
}
EOF
	atf_check -o match:'^    url             : "file:///tmp",$' \
		-o match:'^    url             : "file:///tmp2",$' \
		ravensw -o REPOS_DIR=/dev/null -C ravenswconfiguration -vv
}

nameserver_body()
{
	atf_skip_on Darwin Not possible to inject a namserver on OSX
	atf_skip_on Linux Not possible to inject a namserver on OSX

	atf_check \
		-o inline:"\n" \
		ravensw -C /dev/null config nameserver

	atf_check \
		-o inline:"192.168.1.1\n" \
		ravensw -o NAMESERVER="192.168.1.1" -C /dev/null config nameserver

	atf_check \
		-o inline:"plop\n" \
		-e inline:"Unable to set nameserver, ignoring\n" \
		ravensw -o NAMESERVER="plop" -C /dev/null config nameserver
}
