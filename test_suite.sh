#!/bin/bash

##
#
# Author: Nikolaus Mayer, 2015 (mayern@cs.uni-freiburg.de)
#
##

## 
# Perform tests on the C4P2 toolkit
##

CALLED_SCRIPT_PATH="$0"

FUNC_PRINT () {
  printf "%s\n" "$@"
}

FUNC_PRINT ""
FUNC_PRINT "#######################################"
FUNC_PRINT "## Running tests for ccutccopyppaste ##"
FUNC_PRINT "#######################################"
FUNC_PRINT ""


## Return "success" or "error"
EXIT_SUCCESS () {
  ## ":" is a more portable version of "true"
  exit `:`
}
EXIT_ERROR () { 
  FUNC_PRINT "!!! TEST FAILED !!!" 
  exit `false`
}


## Throw error if...
## ...a file does not exist
EXIST () { 
  if test ! -e "$1"; then 
    FUNC_PRINT "EXIST: '$1' does not exist!"
    EXIT_ERROR
  fi
}
## ...a file exists
NEXIST () { 
  if test   -e "$1"; then 
    FUNC_PRINT "NEXIST: '$1' exists!"
    EXIT_ERROR
  fi
}
## ...a file is not readable
READABLE () { 
  if test ! -r "$1"; then 
    FUNC_PRINT "READABLE: '$1' is not readable!"
    EXIT_ERROR
  fi
}
## ...a file is readable
NREADABLE () { 
  if test   -r "$1"; then 
    FUNC_PRINT "NREADABLE: '$1' is readable!"
    EXIT_ERROR
  fi
}
## ...a file is not writeable
WRITEABLE () { 
  if test ! -w "$1"; then 
    FUNC_PRINT "WRITEABLE: '$1' is not writeable!"
    EXIT_ERROR
  fi
}
## ...a file is writeable
NWRITEABLE () { 
  if test   -w "$1"; then 
    FUNC_PRINT "NWRITEABLE: '$1' is writeable!"
    EXIT_ERROR
  fi
}

## ...a call returns with failure
CHECK  () { 
  if test $1 -ne 0; then 
    FUNC_PRINT "CHECK: Value is not 0!" 
    EXIT_ERROR
  fi
}
## ...a call returns successfully
NCHECK () { 
  if test $1 -ne 1; then 
    FUNC_PRINT "NCHECK: Value is not 1!"
    EXIT_ERROR
  fi
}

## ...two files are different
SAME () { 
  cmp -s "$1" "$2"; 
  if test $? -ne 0; then 
    FUNC_PRINT "SAME: '$1' is different from '$2'!"
    EXIT_ERROR
  fi
}
## ...two files are identical
NSAME () { 
  cmp -s "$1" "$2"
  if test $? -eq 0; then 
    FUNC_PRINT "NSAME: '$1' is the same as '$2'!"
    EXIT_ERROR
  fi
}

## Location of the ccutccopyppaste script and testing environment
C4P2DIR=`dirname ${CALLED_SCRIPT_PATH}`
C4P2DIR=`cd "${C4P2DIR}" && pwd`
C4P2="${C4P2DIR}/ccutccopyppaste.sh"
C4P2_BUFFERFILE="${C4P2DIR}/c4p2buffer"
C4P2_BUFFERTMP="${C4P2DIR}/.c4p2buffer.tmp"
TESTDIR="${C4P2DIR}/TESTS/"

## Cleanup on exit (do not leave the testing environment hanging around
#  in case the test script fails)
EXIT_TRAP () {
  cd "${C4P2DIR}"
  if test -e ${TESTDIR}; then
    chmod -R +rw "${TESTDIR}"
    READABLE "${TESTDIR}"
    WRITEABLE "${TESTDIR}"
    rm -r "${TESTDIR}"
  fi
}
trap EXIT_TRAP EXIT

## Remove trap
# UNTRAP () {
#   trap - EXIT
# }


## Test objects
FOLDER1="folder/"
FOLDER2_WS="folder with whitespace/"
FILE1="file1.txt"
FILE2="file2.png"
FILE3="file 3.sh"

## Create the buffer file
BUFFER_EXISTED_BEFORE="YES"
CREATEBUFFER () {
  if test ! -f ${C4P2_BUFFERFILE}; then
    touch ${C4P2_BUFFERFILE}
    BUFFER_EXISTED_BEFORE="NO"
  else
    BUFFER_EXISTED_BEFORE="YES"
  fi
}

## Setup test environment before a test
SETUP () {
  cd "${C4P2DIR}"
  CREATEBUFFER
  READABLE ${C4P2_BUFFERFILE}
  WRITEABLE ${C4P2_BUFFERFILE}
  FUNC_PRINT "" > ${C4P2_BUFFERFILE}
  mkdir -p "${TESTDIR}"
  EXIST "${TESTDIR}"
  WRITEABLE "${TESTDIR}"
  cd "${TESTDIR}"
}
## Clean up test environment after a test
CLEANUP () { 
  cd "${C4P2DIR}"
  if test -f ${C4P2_BUFFERFILE}; then
    chmod +rw ${C4P2_BUFFERFILE}
    READABLE ${C4P2_BUFFERFILE}
    WRITEABLE ${C4P2_BUFFERFILE}
    if test "${BUFFER_EXISTED_BEFORE}" = "NO"; then
      rm "${C4P2_BUFFERFILE}"
    else
      FUNC_PRINT "" > ${C4P2_BUFFERFILE}
    fi
  fi
  if test -f ${C4P2_BUFFERTMP}; then
    rm "${C4P2_BUFFERTMP}"
  fi
  EXIT_TRAP
  NEXIST "${TESTDIR}"
}

## Prettyprint tests
SUITE   () { FUNC_PRINT "Test suite: $1"; }
TEST    () { FUNC_PRINT "  Test: $1"; }
SUBTEST () { FUNC_PRINT "    Subtest: $1"; }
OK      () { FUNC_PRINT "  ...passed"; }


FUNC_PRINT ""
##
SUITE "Everything ok"
##

  TEST "Copy"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    SAME "${FILE1}" "../${FILE1}"
    SAME "${FILE2}" "../${FILE2}"
    SAME "${FILE3}" "../${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Copy: Target '${FILE2}' is not writeable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"; chmod -w "${FILE1}"; NWRITEABLE "${FILE1}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    SAME "${FILE1}" "../${FILE1}"
    SAME "${FILE2}" "../${FILE2}"
    SAME "${FILE3}" "../${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Copy: Targets' parent folder is not writeable"
    ##
    SETUP
    touch "${FILE1}"
    mkdir "${FOLDER1}"
    cd "${FOLDER1}"
    touch "${FILE2}"
    cd ..
    chmod -R -w "${FOLDER1}"
    NWRITEABLE "${FOLDER1}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FOLDER1}/${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    SAME "${FILE1}" "../${FILE1}"
    SAME "${FILE2}" "../${FOLDER1}/${FILE2}"
    SAME "${FILE3}" "../${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FOLDER1}/${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut"
    ##
    SETUP
    FUNC_PRINT "dummy1" > "${FILE1}"
    FUNC_PRINT "dummy1" > "${FILE2}"
    FUNC_PRINT "dummy1" > "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    FUNC_PRINT "dummy1" > "${FILE1}_2"
    FUNC_PRINT "dummy1" > "${FILE2}_2"
    FUNC_PRINT "dummy1" > "${FILE3}_2"
    SAME "${FILE1}" "${FILE1}_2"
    SAME "${FILE2}" "${FILE2}_2"
    SAME "${FILE3}" "${FILE3}_2"
    cd ..
    NEXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Copy: Overwrite existing files"
    ##
    SETUP
    FUNC_PRINT "dummy1" > "${FILE1}"
    FUNC_PRINT "dummy1" > "${FILE2}"
    FUNC_PRINT "dummy1" > "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    FUNC_PRINT "dummy2" > "${FILE1}"
    FUNC_PRINT "dummy2" > "${FILE2}"
    FUNC_PRINT "dummy2" > "${FILE3}"
    "${C4P2}" -vf
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    SAME "${FILE1}" "../${FILE1}"
    SAME "${FILE2}" "../${FILE2}"
    SAME "${FILE3}" "../${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Copy: Do not overwrite existing files"
    ##
    SETUP
    FUNC_PRINT "dummy1" > "${FILE1}"
    FUNC_PRINT "dummy1" > "${FILE2}"
    FUNC_PRINT "dummy1" > "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    FUNC_PRINT "dummy2" > "${FILE1}"
    FUNC_PRINT "dummy2" > "${FILE2}"
    FUNC_PRINT "dummy2" > "${FILE3}"
    "${C4P2}" -vn
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    NSAME "${FILE1}" "../${FILE1}"
    NSAME "${FILE2}" "../${FILE2}"
    NSAME "${FILE3}" "../${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: Overwrite existing files"
    ##
    SETUP
    FUNC_PRINT "dummy1" > "${FILE1}"
    FUNC_PRINT "dummy1" > "${FILE2}"
    FUNC_PRINT "dummy1" > "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    FUNC_PRINT "dummy2" > "${FILE1}"
    FUNC_PRINT "dummy2" > "${FILE2}"
    FUNC_PRINT "dummy2" > "${FILE3}"
    "${C4P2}" -vf
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    FUNC_PRINT "dummy1" > "${FILE1}_2"
    FUNC_PRINT "dummy1" > "${FILE2}_2"
    FUNC_PRINT "dummy1" > "${FILE3}_2"
    SAME "${FILE1}" "${FILE1}_2"
    SAME "${FILE2}" "${FILE2}_2"
    SAME "${FILE3}" "${FILE3}_2"
    cd ..
    NEXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: Do not overwrite existing files"
    ##
    SETUP
    FUNC_PRINT "dummy1" > "${FILE1}"
    FUNC_PRINT "dummy1" > "${FILE2}"
    FUNC_PRINT "dummy1" > "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    FUNC_PRINT "dummy2" > "${FILE1}"
    FUNC_PRINT "dummy2" > "${FILE2}"
    FUNC_PRINT "dummy2" > "${FILE3}"
    "${C4P2}" -vn
    CHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    FUNC_PRINT "dummy1" > "${FILE1}_2"
    FUNC_PRINT "dummy1" > "${FILE2}_2"
    FUNC_PRINT "dummy1" > "${FILE3}_2"
    NSAME "${FILE1}" "${FILE1}_2"
    NSAME "${FILE2}" "${FILE2}_2"
    NSAME "${FILE3}" "${FILE3}_2"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""



FUNC_PRINT ""
##
SUITE "Target does not exist"
##

  TEST "Copy: Missing file '${FILE2}'"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    NCHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: Missing file '${FILE2}'"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    NCHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""



FUNC_PRINT ""
##
SUITE "Target has missing permissions"
##

  TEST "Copy: File '${FILE2}' is not readable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"; chmod -r "${FILE2}"; NREADABLE "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    NCHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: File '${FILE2}' is not readable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"; chmod -r "${FILE2}"; NREADABLE "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    NCHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: File '${FILE2}' is not writeable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"; chmod -w "${FILE2}"; NWRITEABLE "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    NCHECK $?
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Copy: Target folder is not writeable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    chmod -w "${FOLDER2_WS}"; NWRITEABLE "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    NCHECK $?
    NEXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: Target folder is not writeable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    mkdir -p "${FOLDER2_WS}"
    chmod -w "${FOLDER2_WS}"; NWRITEABLE "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    NCHECK $?
    NEXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""



FUNC_PRINT ""
##
SUITE "Target lost necessary permissions between ccut/ccopy and ppaste"
##

  TEST "Copy: File '${FILE2}' becomes unreadable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -c "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    chmod -r "${FILE2}"; NREADABLE "${FILE2}"
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    NCHECK $?
    EXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    cd ..
    EXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: File '${FILE2}' becomes unreadable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    chmod -r "${FILE2}"; NREADABLE "${FILE2}"
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    NCHECK $?
    EXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    cd ..
    NEXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Cut: File '${FILE2}' becomes unwriteable"
    ##
    SETUP
    touch "${FILE1}"
    touch "${FILE2}"
    touch "${FILE3}"
    "${C4P2}" -x "${FILE1}" "${FILE2}" "${FILE3}"
    CHECK $?
    chmod -w "${FILE2}"; NWRITEABLE "${FILE2}"
    mkdir -p "${FOLDER2_WS}"
    cd "${FOLDER2_WS}"
    "${C4P2}" -v
    NCHECK $?
    EXIST "${FILE1}"
    NEXIST "${FILE2}"
    NEXIST "${FILE3}"
    cd ..
    NEXIST "${FILE1}"
    EXIST "${FILE2}"
    EXIST "${FILE3}"
    OK
    CLEANUP
    FUNC_PRINT ""



FUNC_PRINT ""
##
SUITE "Bad options"
##

  TEST "No mode"
    ##
    SETUP
    "${C4P2}"
    NCHECK $?
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "No targets"
    ##
    SETUP
    SUBTEST "Copy"
      "${C4P2}" -c
      NCHECK $?
    SUBTEST "Cut"
      "${C4P2}" -c
      NCHECK $?
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Conflicting modes"
    ##
    SETUP
    touch "${FILE1}"
    SUBTEST "Cut+Copy"
      "${C4P2}" -xc "${FILE1}"
      NCHECK $?
    SUBTEST "Cut+Paste"
      "${C4P2}" -xv "${FILE1}"
      NCHECK $?
    SUBTEST "Copy+Paste"
      "${C4P2}" -cv "${FILE1}"
      NCHECK $?
    SUBTEST "Cut+Force overwrite"
      "${C4P2}" -xf "${FILE1}"
      NCHECK $?
    SUBTEST "Copy+Force overwrite"
      "${C4P2}" -cf "${FILE1}"
      NCHECK $?
    SUBTEST "Cut+No overwrite"
      "${C4P2}" -xn "${FILE1}"
      NCHECK $?
    SUBTEST "Copy+No overwrite"
      "${C4P2}" -cn "${FILE1}"
      NCHECK $?
    SUBTEST "Force overwrite+No overwrite"
      "${C4P2}" -vfn
      NCHECK $?
    SUBTEST "Unknown option"
      "${C4P2}" -g
      NCHECK $?
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Paste with arguments"
    ##
    SETUP
    touch "${FILE1}"
    "${C4P2}" -v "${FILE1}"
    NCHECK $?
    OK
    CLEANUP
    FUNC_PRINT ""



FUNC_PRINT ""
##
SUITE "Problem with buffer file"
##

  TEST "Bad buffer file"
    ##
    SETUP
    touch "${FILE1}"
    "${C4P2}" -c "${FILE1}"
    CHECK $?
    SUBTEST "Buffer was deleted"
      cd "${C4P2DIR}"
      rm ${C4P2_BUFFERFILE}
      cd "${TESTDIR}"
      "${C4P2}" -v
      NCHECK $?
    SUBTEST "No CUT/COPY header in buffer"
      "${C4P2}" -v
      NCHECK $?
    SUBTEST "Zero-size buffer"
      cd "${C4P2DIR}"
      rm ${C4P2_BUFFERFILE}
      touch ${C4P2_BUFFERFILE}
      cd "${TESTDIR}"
      "${C4P2}" -v
      NCHECK $?
    SUBTEST "Bad contents"
      cd "${C4P2DIR}"
      FUNC_PRINT "BADCOMMAND\nBADLINE" > ${C4P2_BUFFERFILE}
      cd "${TESTDIR}"
      "${C4P2}" -v
      NCHECK $?
    OK
    CLEANUP
    FUNC_PRINT ""

  TEST "Bad permissions on buffer file"
    ##
    SETUP
    SUBTEST "Buffer unreadable"
      cd "${C4P2DIR}"
      chmod -r ${C4P2_BUFFERFILE}; NREADABLE ${C4P2_BUFFERFILE}
      cd "${TESTDIR}"
      touch "${FILE1}"
      "${C4P2}" -c "${FILE1}"
      NCHECK $?
    SUBTEST "Buffer unwriteable"
      cd "${C4P2DIR}"
      chmod +r ${C4P2_BUFFERFILE}; READABLE ${C4P2_BUFFERFILE}
      chmod -w ${C4P2_BUFFERFILE}; NWRITEABLE ${C4P2_BUFFERFILE}
      cd "${TESTDIR}"
      touch "${FILE1}"
      "${C4P2}" -c "${FILE1}"
      NCHECK $?
    OK
    CLEANUP
    FUNC_PRINT ""




FUNC_PRINT ""
FUNC_PRINT "#######################"
FUNC_PRINT "## All tests passed. ##"
FUNC_PRINT "#######################"
FUNC_PRINT ""
EXIT_SUCCESS

