#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	metalog \
	reinstall \
	pre_script_fail \
	post_script_ignored

metalog_body()
{
        atf_skip_on Linux Test fails on Linux

	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest test test 1 / || atf_fail "Failed to create the ucl file"
	touch ${TMPDIR}/testfile1 || atf_fail "Failed to create the temp file"
	echo "@(root,wheel,640,) testfile1" > test.plist
	echo "test123" > ${TMPDIR}/testfile2 || atf_fail "Failed to create the temp file"
	echo "@(daemon,nobody,644,) testfile2" >> test.plist
	ln -s ${TMPDIR}/testfile1 ${TMPDIR}/testlink1
	echo "@ testlink1" >> test.plist
	ln ${TMPDIR}/testfile2 ${TMPDIR}/testhlink2
	echo "@ testhlink2" >> test.plist
	mkdir ${TMPDIR}/testdir1  || atf_fail "Failed to create the temp dir"
	echo "@dir testdir1" >> test.plist
	mkdir ${TMPDIR}/testdir2  || atf_fail "Failed to create the temp dir"
	chmod 750 ${TMPDIR}/testdir2 || atf_fail "Failed to chmod the temp dir"
	echo "@dir(daemon) testdir2" >> test.plist

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -r ${TMPDIR} -M test.ucl -p test.plist

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw repo .

	cat << EOF > repo.conf
local: {
	url: file:///${TMPDIR},
	enabled: true
}
EOF

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		mkdir ${TMPDIR}/root

	atf_check \
		-o ignore \
		-s exit:0 \
		ravensw -o REPOS_DIR="${TMPDIR}" -o METALOG=${TMPDIR}/METALOG -r ${TMPDIR}/root install -y test

	atf_check \
		-o match:"./testfile1 type=file uname=root gname=wheel mode=640" \
		-o match:"./testfile2 type=file uname=daemon gname=nobody mode=644" \
		-o match:"./testlink1 type=link uname=root gname=wheel mode=755 link=${TMPDIR}/testfile1" \
		-o match:"./testhlink2 type=file uname=root gname=wheel mode=644" \
		-o match:"./testdir1 type=dir uname=root gname=wheel mode=755" \
		-o match:"./testdir2 type=dir uname=daemon gname=wheel mode=750" \
		-e empty \
		-s exit:0 \
		cat ${TMPDIR}/METALOG
}

reinstall_body()
{
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest test test 1 /raven

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw register -M test.ucl

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl

	atf_check \
		-o ignore \
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
		ravensw -o REPOS_DIR="${TMPDIR}" install -y test
}

pre_script_fail_body()
{
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest test test 1
	cat << EOF >> test.ucl
scripts: {
   pre-install: "exit 1"
}
EOF

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl

	atf_check -o ignore \
		-e inline:"PRE-INSTALL script failed\n" \
		-s exit:3 \
		ravensw -o REPOS_DIR="/dev/null" install -y ${TMPDIR}/test-1.tzst
}

post_script_ignored_body()
{
	atf_check -s exit:0 sh ${RESOURCEDIR}/test_subr.sh new_manifest test test 1
	cat << EOF >> test.ucl
scripts: {
   post-install: "exit 1"
}
EOF

	atf_check \
		-o ignore \
		-e empty \
		-s exit:0 \
		ravensw create -M test.ucl

	atf_check -o ignore \
		-e inline:"POST-INSTALL script failed\n" \
		-s exit:0 \
		ravensw -o REPOS_DIR="/dev/null" install -y ${TMPDIR}/test-1.tzst
}
