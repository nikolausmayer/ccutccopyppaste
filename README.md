# ccutccopyppaste

Ccutccopyppaste is a toolkit that brings ctrl-x/c/v functionality to the command line. Moving files between directories is a pain using the raw `mv` or `cp` commands, because you always have to specify either the full source or the full target path. Ccutccopyppaste makes it as easy as "ccopy <file>" and "ppaste". The commands can come from different terminals so you do not have to `cd` around all the time.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)


**THIS SOFTWARE IS NOT IN A PRODUCTION-READY STATE. USE AT OWN RISK.**


## Usage

Cut files ("ctrl-x"): `ccut <file> [more files...]`

Copy files ("ctrl-c"): `ccopy <file> [more files...]`

Paste files ("ctrl-v") that were "ccut" or "ccopied": `ppaste`


By default, `ppaste` will ask before overwriting existing files (similar to `mv -i`/`cp -i`). Use `-f` to force overwriting.

Ccutccopyppaste stores its "clipboard" in a buffer file. The `-l` option for any ccutccopyppaste command will print the buffer contents instead of executing the command.


## Running the tests

Ccutccopyppaste comes with a test suite that hopefully covers most of the functions. Simply run `test_suite.sh`. If any test fails, please open an issue!


## License
The files in this repository are under the [MIT License](LICENSE)

