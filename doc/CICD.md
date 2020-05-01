Concordia CI/CD Notes
=====================

MAME has some arguments that can aid in CI/CD development.

# Build agent requirements
* Xvfb with xvfb-run
* MAME

# MAME Command-Line Arguments
```
xvfb-run \
mame \
	genesis \
	-debug \
	-debugscript testsuite/build.mds \
	-cart out.bin \
	-video none \
	-seconds_to_run 5 \
	-oslog
```

# MAME Debugscript
* Use "reserved" region $A14102
```
wp A14102,1,w,wpdata == 1,{quit}
wp A14102,1,w,wpdata == 2,{logerror "test<passed>\n"; go}
wp A14102,1,w,wpdata == 3,{logerror "test<failed>\n"; go}
wp A14103,1,w,1,{ logerror "executing<%X>\n",wpdata; go}
go
```