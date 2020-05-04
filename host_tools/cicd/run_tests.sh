#!/bin/bash
test_output=`xmllint --xpath "/testsuite/testcase/@classname" testsuite/tests/tests.xml | sed "s/classname=//g; s/\"//g"`
read -a tests <<< $test_output
for test in "${tests[@]}"
do
	echo "${test}"
done
