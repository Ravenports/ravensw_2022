#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	lock \
	lock_delete

lock_setup() {
	for ravensw in 'png' 'sqlite3' ; do
		atf_check \
		    -o match:".*Installing.*\.\.\.$" \
		    -e empty \
		    -s exit:0 \
		    ravensw register -t -M ${RESOURCEDIR}/$ravensw.ucl
	done

	test -f "./local.sqlite" || \
	    atf_fail "Can't populate $RAVENSW_DBDIR/local.sqlite"
}

lock_head() {
	atf_set "require.files" \
	   "${RESOURCEDIR}/png.ucl ${RESOURCEDIR}/sqlite3.ucl"
}

lock_body() {
	lock_setup

	atf_check \
	    -o match:"Locking sqlite3.*" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -y sqlite3

	atf_check \
	    -o match:"sqlite3-3.8.6" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -l

	atf_check \
	    -o inline:"sqlite3-3.8.6: already locked\n" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -y sqlite3

	atf_check \
	    -o match:"Unlocking sqlite3.*" \
	    -e empty \
	    -s exit:0 \
	    ravensw unlock -y sqlite3

	atf_check \
	    -o inline:"Currently locked packages:\n" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -l

	atf_check \
	    -o inline:"sqlite3-3.8.6: already unlocked\n" \
	    -e empty \
	    -s exit:0 \
	    ravensw unlock -y sqlite3

	atf_check \
	    -o match:"Locking.*" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -y -a

	atf_check \
	    -o match:"sqlite3.*" \
	    -o match:"png.*" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -l

	atf_check \
	    -o match:"Unlocking.*" \
	    -e empty \
	    -s exit:0 \
	    ravensw unlock -y -a

	atf_check \
	    -o inline:"Currently locked packages:\n" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -l
}

lock_delete_head() {
	lock_head
}

lock_delete_body() {
	lock_setup

	atf_check \
	    -o match:"Locking sqlite3.*" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -y sqlite3

	atf_check \
	    -o match:".*locked and may not be removed.*" \
	    -o match:"sqlite3.*" \
	    -e empty \
	    -s exit:7 \
	    ravensw delete -y sqlite3

	atf_check \
	    -o match:"sqlite3-3.8.6" \
	    -e empty \
	    -s exit:0 \
	    ravensw lock -l
}
