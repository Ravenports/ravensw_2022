#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	annotate

annotate_body() {
	for ravensw in 'png' 'sqlite3' ; do
	    atf_check \
		-o match:".*Installing.*\.\.\.$" \
		-e empty \
		-s exit:0 \
		ravensw register -t -M ${RESOURCEDIR}/$ravensw.ucl
	done

	[ -f "./local.sqlite" ] || \
	    atf_fail "Can't populate $RAVENSW_DBDIR/local.sqlite"

	atf_check \
	    -o match:"added annotation tagged: TEST1" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate -Ay png TEST1 test1

	atf_check \
	    -o match:"TEST1 +: test1" \
	    -e empty \
	    -s exit:0 \
	    ravensw info -A png

	atf_check \
	    -o match:"^png-1.5.18: Tag: TEST1 Value: test1$" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate -S png TEST1

	echo test2 > $HOME/annotate-TEST2.txt

	atf_check \
	    -o match:"added annotation tagged: TEST2" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate -Ay png TEST2 < $HOME/annotate-TEST2.txt

	atf_check \
	    -o match:"TEST1 +: test1" \
	    -o match:"TEST2 +: test2" \
	    -e empty \
	    -s exit:0 \
	    ravensw info -A png

	atf_check \
	    -o match:"Modified annotation tagged: TEST1" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate -My png TEST1 test1-modified

	atf_check \
	    -o match:"TEST1 +: test1-modified" \
	    -o match:"TEST2 +: test2" \
	    -e empty \
	    -s exit:0 \
	    ravensw info -A png

	atf_check \
	    -o match:"^png-1.5.18: Tag: TEST1 Value: test1-modified$" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate --show png TEST1

	atf_check \
	    -o match:"Deleted annotation tagged: TEST1" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate -Dy png TEST1

	atf_check \
	    -o not-match:"TEST1" \
	    -o match:"TEST2 +: test2" \
	    -e empty \
	    -s exit:0 \
	    ravensw info -A png

	atf_check \
	    -o match:"Deleted annotation tagged: TEST2" \
	    -s exit:0 \
	    -e empty \
	    ravensw annotate -Dy png TEST2

	atf_check \
	    -o not-match:"TEST1" \
	    -o not-match:"TEST2" \
	    -s exit:0 \
	    -e empty \
	    ravensw info -A png

	# Check multiple annotations
	atf_check \
	    -o match:"^png-1.5.18: added annotation tagged: TEST1$" \
	    -o match:"^sqlite3-3.8.6: added annotation tagged: TEST1$" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate -aAy TEST1 test1

	atf_check \
	    -o match:"^png-1.5.18: Tag: TEST1 Value: test1$" \
	    -o match:"^sqlite3-3.8.6: Tag: TEST1 Value: test1$" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate --all --show TEST1

	atf_check \
	    -o match:"^png-1.5.18: Deleted annotation tagged: TEST1$" \
	    -o match:"^sqlite3-3.8.6: Deleted annotation tagged: TEST1$" \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate --yes --all --delete TEST1

	atf_check \
	    -o empty \
	    -e empty \
	    -s exit:0 \
	    ravensw annotate --all --show TEST1

}
