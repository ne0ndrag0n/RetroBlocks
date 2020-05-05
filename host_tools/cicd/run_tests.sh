#!/bin/bash
echo -e "Concordia \e[96mUnit Test Executor\e[0m"
echo ""

tests=(testsuite/tests/*.asm)

for test in "${tests[@]}"
do
	echo "   include '${test}'" > testsuite/current_test.asm
	makeresult=`make -B testsuite`
	passed=`echo $?`
	if (( passed != 0 )); then
		echo -e "\e[91mFailed to compile\e[0m ${test}!"
		echo "$makeresult"
		echo ""
		let index++
		continue
	fi
	echo -en "\e[93m[....]\e[0m"
	mame_output=`xvfb-run mame genesis -debug -debugscript testsuite/build.mds -cart out.bin -video none -seconds_to_run 5 -oslog`
	passed=`echo ${mame_output} | grep "test<passed>" | echo $?`
	if (( passed == 0 )); then
		passed='\e[92m[PASS]\e[0m\t'
	else
		passed='\e[91m[FAIL]\e[0m\t'
	fi

	passed="${passed} ${test}"
	echo -en "\r        \r"
	echo -e $passed

	let index++
done
