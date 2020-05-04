#!/bin/bash
test_output=`xmllint --xpath "/testsuite/testcase/@classname" testsuite/tests/tests.xml | sed "s/classname=//g; s/\"//g"`
read -a tests <<< $test_output
for test in "${tests[@]}"
do
	echo "Executing test ${test}..."
	echo "   include 'testsuite/tests/${test}.asm'" > testsuite/current_test.asm
	make -B testsuite > /dev/null
	passed=`echo $?`
	if (( passed != 0 )); then
		echo "Failed to compile!"
		continue
	fi
	mame_output=`xvfb-run mame genesis -debug -debugscript testsuite/build.mds -cart out.bin -video none -seconds_to_run 5 -oslog`
	passed=`echo ${mame_output} | grep "test<passed>"`
	passed=`echo $?`
	if (( passed == 0 )); then
		echo "Passed!"
	else
		echo "Failed!"
	fi
done
