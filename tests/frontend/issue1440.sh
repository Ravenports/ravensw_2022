#! /usr/bin/env atf-sh

. $(atf_get_srcdir)/test_environment.sh


# https://github.com/freebsd/ravensw/issues/1440
#ravenswA
# - ravenswB
#    - ravenswC
#      - ravenswD
#1. Two repos (repoA and repoB) with same set of packages. ravenswA for repoA and repoB have different options set.
#   repoB has prio 100, so all packages must be prefered from this one.
#2. On upgrade ravensw wants to reinstall ravenswA due options changed from repoA which is wrong.

tests_init \
        issue1440

issue1440_body() {

        touch ravenswA.file
        touch ravenswB.file
        touch ravenswC.file
        touch ravenswD.file

        cat << EOF > ravenswA.ucl
name: ravenswA
origin: misc/ravenswA
version: "1.0"
maintainer: test
categories: [test]
comment: a test
www: http://test
prefix: /raven
desc: <<EOD
Yet another test
EOD
options: {
    APNG: "on",
    PNGTEST: "on"
}
deps:   {
          ravenswB: {
                origin: "misc/ravenswB",
                version: "1.0"
              }
        }
files: {
    ${TMPDIR}/ravenswA.file: "",
}
EOF

        cat << EOF > ravenswB.ucl
name: ravenswB
origin: misc/ravenswB
version: "1.0"
maintainer: test
categories: [test]
comment: a test
www: http://test
prefix: /raven
desc: <<EOD
Yet another test
EOD
deps:   {
          ravenswC: {
                origin: "misc/ravenswC",
                version: "1.0"
              }
        }

files: {
    ${TMPDIR}/ravenswB.file: "",
}
EOF

        cat << EOF > ravenswC.ucl
name: ravenswC
origin: misc/ravenswC
version: "1.0"
maintainer: test
categories: [test]
comment: a test
www: http://test
prefix: /raven
desc: <<EOD
Yet another test
EOD
deps:   {
          ravenswD: {
                origin: "misc/ravenswD",
                version: "1.0"
              }
        }
files: {
    ${TMPDIR}/ravenswC.file: "",
}
EOF


        cat << EOF > ravenswD.ucl
name: ravenswD
origin: misc/ravenswD
version: "1.0"
maintainer: test
categories: [test]
comment: a test
www: http://test
prefix: /raven
desc: <<EOD
Yet another test
EOD
files: {
    ${TMPDIR}/ravenswD.file: "",
}
EOF

        cat << EOF > repos.conf
repoA: {
        url: file://${TMPDIR}/repoA,
        enabled: true
}
repoB: {
        url: file://${TMPDIR}/repoB,
	priority: 100,
        enabled: true
}

EOF

        for p in ravenswA ravenswB ravenswC ravenswD; do
                atf_check \
                        -o ignore \
                        -e empty \
                        -s exit:0 \
                        ravensw create -o ${TMPDIR}/repoA -M ./${p}.ucl
        done

        atf_check \
                -o inline:"Creating repository in ${TMPDIR}/repoA:  done\nPacking files for repository:  done\n" \
                -e empty \
                -s exit:0 \
                ravensw repo -o ${TMPDIR}/repoA ${TMPDIR}/repoA

        cat << EOF > ravenswA.ucl
name: ravenswA
origin: misc/ravenswA
version: "1.0"
maintainer: test
categories: [test]
comment: a test
www: http://test
prefix: /raven
desc: <<EOD
Yet another test
EOD
options: {
    APNG: "off",
    PNGTEST: "on"
}
deps:   {
          ravenswB: {
                origin: "misc/ravenswB",
                version: "1.0"
              }
        }
files: {
    ${TMPDIR}/ravenswA.file: "",
}
EOF

        for p in ravenswA ravenswB ravenswC ravenswD; do
                atf_check \
                        -o ignore \
                        -e empty \
                        -s exit:0 \
                        ravensw create -o ${TMPDIR}/repoB -M ./${p}.ucl
        done


        atf_check \
                -o inline:"Creating repository in ${TMPDIR}/repoB:  done\nPacking files for repository:  done\n" \
                -e empty \
                -s exit:0 \
                ravensw repo -o ${TMPDIR}/repoB ${TMPDIR}/repoB



OUTPUT_CASE1="Updating repoA repository catalog...
${JAILED}Fetching meta.tzst:  done
${JAILED}Fetching packagesite.tzst:  done
Processing entries:  done
repoA repository update completed. 4 packages processed.
Updating repoB repository catalog...
${JAILED}Fetching meta.tzst:  done
${JAILED}Fetching packagesite.tzst:  done
Processing entries:  done
repoB repository update completed. 4 packages processed.
All repositories are up to date.
Checking integrity... done (0 conflicting)
The following 4 package(s) will be affected (of 0 checked):

New packages to be INSTALLED:
	ravenswA: 1.0 [repoB]
	ravenswB: 1.0 [repoB]
	ravenswC: 1.0 [repoB]
	ravenswD: 1.0 [repoB]

Number of packages to be installed: 4
${JAILED}[1/4] Installing ravenswD-1.0...
${JAILED}[1/4] Extracting ravenswD-1.0:  done
${JAILED}[2/4] Installing ravenswC-1.0...
${JAILED}[2/4] Extracting ravenswC-1.0:  done
${JAILED}[3/4] Installing ravenswB-1.0...
${JAILED}[3/4] Extracting ravenswB-1.0:  done
${JAILED}[4/4] Installing ravenswA-1.0...
${JAILED}[4/4] Extracting ravenswA-1.0:  done
"

        atf_check \
                -o inline:"${OUTPUT_CASE1}" \
                -s exit:0 \
                ravensw -o REPOS_DIR="${TMPDIR}" -o RAVENSW_CACHEDIR="${TMPDIR}" install -y ravenswA



OUTPUT_CASE2="Updating repoA repository catalog...
repoA repository is up to date.
Updating repoB repository catalog...
repoB repository is up to date.
All repositories are up to date.
Checking for upgrades (1 candidates):  done
Processing candidates (1 candidates):  done
Checking integrity... done (0 conflicting)
Your packages are up to date.
"
        atf_check \
                -o inline:"${OUTPUT_CASE2}" \
                -e empty \
                -s exit:0 \
                ravensw -o REPOS_DIR="${TMPDIR}" -o RAVENSW_CACHEDIR="${TMPDIR}" upgrade -y

}
