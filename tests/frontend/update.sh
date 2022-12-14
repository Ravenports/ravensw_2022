#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh

tests_init \
	update_error

update_error_body() {

	mkdir repos
	mkdir empty
	cat > repos/test.conf << EOF
test: {
  url: "file://empty/",
}
EOF

	atf_check \
		-o match:"Unable to update repository test" \
		-e match:"file://empty//packagesite.tzst: No such file or directory" \
		-s exit:70 \
		ravensw -R repos update
}
