Concordia CI/CD Notes
=====================

MAME has some arguments that can aid in CI/CD development.

# MAME Command-Line Arguments
```
mame \
	genesis \
	-debug \
	-debugscript cicd/build.mds \
	-cart out.bin \
	-video none \
	-seconds_to_run 5
```

# MAME Debugscript
* Use "reserved" region $A14102
```
wp A14102,1,w,wpdata == 1,{quit}
go
```