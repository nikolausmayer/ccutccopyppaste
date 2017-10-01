#!/bin/bash

##
#
# Author: Nikolaus Mayer, 2015 (mayern@cs.uni-freiburg.de)
#
##

#######################################################################
#
# The C4P2 toolkit provides CLI functions for the cut/copy/paste
# shortcuts which are so common in GUI applications. From anywhere,
# call "ccut <targets>" or "ccopy <targets>" to cut/copy arbitrary
# target files.
# Calling "ppaste" then cuts/copies the previously specified files
# and/or folders to the current working directory.
#
# The application performs full checks on existence and permissions
# for all relevant objects.
#
# (C4P2 as in [CC]ut[CC]opy[PP]aste)
#
#######################################################################
#
# Usage example:
# 
# ~$ ls
# File1  File2  folder/
# ~$ ccopy File1
# ~$ cd folder/
# ~$ ppaste
# ~$ ls
# File1
#
#######################################################################

CALLED_SCRIPT_PATH="$0"

#######################
## Safety mechanisms ##
#######################
## Fail if any command fails (use "|| true" if a command is ok to fail)
set -e
## Fail if any pipeline command fails
set -o pipefail
## Fail if a glob does not expand
shopt -s failglob


#######################################################################

## Debug flag, COMMENT OUT to disable
#C4P2DEBUG=true

## Script names for user commands 
C4P2_CCUT_NAME="ccut"
C4P2_CCOPY_NAME="ccopy"
C4P2_PPASTE_NAME="ppaste"

## Wrapper for 'echo' for easy changes later
C4P2_PRINT () {
  printf "%s\n" "$@"
}

## Print argument, but only if debug flag is set
C4P2_DEBUGPRINT () {
  if test "X${C4P2DEBUG}" != "X"; then
    C4P2_PRINT "$@"
  fi
}

## Print option info 
C4P2_DEBUGOPTION () {
  C4P2_DEBUGPRINT "$@"
}

## Return "success" or "error"
C4P2_EXIT_SUCCESS () {
  ## ":" is a more portable version of "true"
  exit `:`
}
C4P2_EXIT_ERROR () { 
  exit `false`
}

## TODO Print usage info and exit as failure
C4P2_PRINT_USAGE () {
  C4P2_PRINT ""
  C4P2_PRINT "Usage: ${C4P2_CCUT_NAME}   [-l] [..TARGETS..]"
  C4P2_PRINT "       ${C4P2_CCOPY_NAME}  [-l] [..TARGETS..]"
  C4P2_PRINT "       ${C4P2_PPASTE_NAME} [-f] [-n] [-l]"
  C4P2_PRINT ""
}

#######################################################################

C4P2_DEBUGPRINT "C4P2DEBUG is set"

###############################
## Parse and process options ##
###############################
CUT=0
COPY=0
PASTE=0
LIST=0
FORCE_OVERWRITE=0
NO_OVERWRITE=0
while getopts xcvlfn OPTION;
do
  case "${OPTION}" in
    x)   CUT=1;   C4P2_DEBUGOPTION "CUT";;
    c)   COPY=1;  C4P2_DEBUGOPTION "COPY";;
    v)   PASTE=1; C4P2_DEBUGOPTION "PASTE";;
    l)   LIST=1;  C4P2_DEBUGOPTION "LIST";;
    ## TODO 'Add' function
    f)   FORCE_OVERWRITE=1; C4P2_DEBUGOPTION "FORCE_OVERWRITE";;
    n)   NO_OVERWRITE=1;    C4P2_DEBUGOPTION "NO_OVERWRITE";;
    [?]) C4P2_EXIT_ERROR;;
    #l)   LIST="${OPTARG}";
  esac
done


## If none of CUT/COPY/PASTE are set, this script has been called
#  incorrectly
if test "${CUT}"   -eq 0 &&
   test "${COPY}"  -eq 0 &&
   test "${PASTE}" -eq 0; then
  C4P2_PRINT_USAGE
  C4P2_EXIT_ERROR
fi
## If more than one of CUT/COPY/PASTE are set, this script has been
#  called incorrectly
if   test "${CUT}"  -eq 1 && test "${COPY}"  -eq 1; then
  C4P2_PRINT_USAGE
  C4P2_EXIT_ERROR
elif test "${CUT}"  -eq 1 && test "${PASTE}" -eq 1; then
  C4P2_PRINT_USAGE
  C4P2_EXIT_ERROR
elif test "${COPY}" -eq 1 && test "${PASTE}" -eq 1; then
  C4P2_PRINT_USAGE
  C4P2_EXIT_ERROR
fi

## Reset the arguments index so that $@ only captures non-options
shift `expr $OPTIND - 1`

## Do nothing if no arguments are given for cut or copy...
if test "${CUT}" -eq 1 || test "${COPY}" -eq 1; then
  if test $# -le 0; then
    C4P2_DEBUGPRINT "No non-option arguments given, exiting..." 
    C4P2_EXIT_ERROR
  fi
## ...or if arguments are given for paste
elif test "${PASTE}" -eq 1; then
  if test $# -gt 0; then
    C4P2_DEBUGPRINT "${C4P2_PPASTE_NAME} does not take arguments, exiting..." 
    C4P2_EXIT_ERROR
  fi
else
  C4P2_PRINT "Error"
  C4P2_EXIT_ERROR
fi

## 'Force' and 'no overwrite' options are only valid in paste mode
if test "${PASTE}" -eq 0; then
  if test "${FORCE_OVERWRITE}" -eq 1; then
    C4P2_PRINT "-f (force) option is only valid for ${C4P2_PPASTE_NAME}"
    C4P2_EXIT_ERROR
  fi
  if test "${NO_OVERWRITE}" -eq 1; then
    C4P2_PRINT "-n (no-overwrite) option is only valid for ${C4P2_PPASTE_NAME}"
    C4P2_EXIT_ERROR
  fi
fi

## 'Force' and 'no overwrite' options cannot be used together
if test "${FORCE_OVERWRITE}" -eq 1 && test "${NO_OVERWRITE}" -eq 1; then
  C4P2_PRINT "-f (force) and -n (no-overwrite) cannot be active together"
  C4P2_EXIT_ERROR
fi



######################
## Central commands ##
######################
CMD_MOVE=mv
CMD_COPY=cp
CMD_REMOVE=rm


###############
## Locations ##
###############
## Get location of this script (which is where the buffer file lives)
C4P2DIR=`dirname "${CALLED_SCRIPT_PATH}"`
C4P2DIR=`cd "${C4P2DIR}" && pwd`
C4P2_DEBUGPRINT "C4P2DIR=${C4P2DIR}"
C4P2BUFFER="${C4P2DIR}/c4p2buffer"
C4P2BUFFERTMP="${C4P2DIR}/.c4p2buffer.tmp"
C4P2_DEBUGPRINT "C4P2BUFFER=${C4P2BUFFER}"

## Make a temporary backup of the buffer file
BACKUP_BUFFER () {
  C4P2_DEBUGPRINT "Backing up buffer file"
  "${CMD_COPY}" "${C4P2BUFFER}" "${C4P2BUFFERTMP}"
}
## Revert the buffer file to temporary save version
C4P2_REVERT_BUFFER () {
  if test ! -f "${C4P2BUFFERTMP}"; then
    C4P2_PRINT "Buffer backup '${C4P2BUFFERTMP}' does not exist"
    C4P2_EXIT_ERROR
  else
    C4P2_DEBUGPRINT "Reverting buffer file"
    "${CMD_MOVE}" "${C4P2BUFFERTMP}" "${C4P2BUFFER}"
  fi
}

## If the buffer file does not exist, create it (assume the buffer
#  file's _folder_ exists because that should also be the script's 
#  folder)
if test ! -f "${C4P2BUFFER}"; then
  ## Test if we can write to the script's folder
  if test -w "${C4P2DIR}"; then
    C4P2_PRINT "Creating buffer file '${C4P2BUFFER}'"
    touch "${C4P2BUFFER}"
  else
    C4P2_PRINT "Cannot create buffer file '${C4P2BUFFER}' (no write"
    C4P2_PRINT "permissions in folder '${C4P2DIR}'"
    C4P2_EXIT_ERROR
  fi
fi

## Test if we can read from and write to the buffer file
if   test ! -w "${C4P2BUFFER}"; then
  C4P2_PRINT "Cannot write to buffer file '${C4P2BUFFER}'"
  C4P2_EXIT_ERROR
elif test ! -r "${C4P2BUFFER}"; then
  C4P2_PRINT "Cannot read from buffer file '${C4P2BUFFER}'"
  C4P2_EXIT_ERROR
fi

## If LIST is set, print the buffer and exit
if test ${LIST} -eq 1; then
  C4P2_PRINT "Buffer contents:"
  ## See http://stackoverflow.com/a/10929511
  while IFS='' read -r line || test -n "${line}"; do
    C4P2_PRINT "  ${line}"
  done < "${C4P2BUFFER}"
  C4P2_EXIT_SUCCESS
fi

## Get location from where this script is called
PWD=`pwd`
C4P2_DEBUGPRINT "PWD=${PWD}"
## Disallow operation from root
#  This started as a workaround for the problem that extending the
#  PWD path with a slash is wrong when PWD is "/", but now I think
#  it is a good idea to prevent accidental root-level shenanigans.
if test "${PWD}" = "/"; then
  C4P2_PRINT "By design, working from '/' is disallowed. You can easily"
  C4P2_PRINT "change this behaviour if you wish, it is just a precaution."
  C4P2_EXIT_ERROR
fi


#########
## CUT ##
#########
if test ${CUT} -eq 1; then
  BACKUP_BUFFER
  ## Write absolute paths of cut targets into buffer file
  C4P2_DEBUGPRINT "Writing CUT header to buffer"
  C4P2_PRINT "CUT" > "${C4P2BUFFER}"
  for ARG in "$@"; do
    ## Convert relative input paths to absolute paths
    ARG_EXPANDED=""
    ## An absolute path starts with "/"
    if test "/" = `C4P2_PRINT "${ARG}" | head -c1`; then
      ARG_EXPANDED="${ARG}"
    else
      ARG_EXPANDED="${PWD}/${ARG}"
    fi

    ## Test if the target exists
    if test ! -e "${ARG_EXPANDED}"; then
      C4P2_PRINT "${C4P2_CCUT_NAME}: Target '${ARG}' does not exist!"
      C4P2_REVERT_BUFFER
      C4P2_EXIT_ERROR
    fi
    ## Test if the target is readable
    if test ! -r "${ARG_EXPANDED}"; then
      C4P2_PRINT "${C4P2_CCUT_NAME}: '${ARG}' is not readable!"
      C4P2_REVERT_BUFFER
      C4P2_EXIT_ERROR
    fi
    ## Test if the target is writeable
    if test ! -w "${ARG_EXPANDED}"; then
      C4P2_PRINT "${C4P2_CCUT_NAME}: '${ARG}' is not writeable!"
      C4P2_REVERT_BUFFER
      C4P2_EXIT_ERROR
    fi

    C4P2_PRINT "${ARG_EXPANDED}" >> ${C4P2BUFFER}
    C4P2_DEBUGPRINT "${C4P2_CCUT_NAME}: Marking ${ARG_EXPANDED} for cut"
  done
##########
## COPY ##
##########
elif test ${COPY} -eq 1; then
  BACKUP_BUFFER
  ## Write absolute paths of copy targets into buffer file
  C4P2_DEBUGPRINT "Writing COPY header to buffer"
  C4P2_PRINT "COPY" > "${C4P2BUFFER}"
  for ARG in "$@"; do
    ## Convert relative input paths to absolute paths
    ARG_EXPANDED=""
    ## An absolute path starts with "/"
    if test "/" = `C4P2_PRINT "${ARG}" | head -c1`; then
      ARG_EXPANDED="${ARG}"
    else
      ARG_EXPANDED="${PWD}/${ARG}"
    fi

    ## Test if the target exists
    if test ! -e "${ARG_EXPANDED}"; then
      C4P2_PRINT "${C4P2_CCOPY_NAME}: Target '${ARG}' does not exist!"
      C4P2_REVERT_BUFFER
      C4P2_EXIT_ERROR
    fi
    ## Test if the target is readable
    if test ! -r "${ARG_EXPANDED}"; then
      C4P2_PRINT "${C4P2_CCOPY_NAME}: '${ARG}' is not readable!"
      C4P2_REVERT_BUFFER
      C4P2_EXIT_ERROR
    fi

    C4P2_PRINT "${ARG_EXPANDED}" >> ${C4P2BUFFER}
    C4P2_DEBUGPRINT "${C4P2_CCOPY_NAME}: Marking '${ARG_EXPANDED}' for copy"
  done
###########
## PASTE ##
###########
elif test ${PASTE} -eq 1; then
  MODE=0
  LINENUMBER=0
  ## See http://stackoverflow.com/a/10929511
  while IFS='' read -r line || test -n "${line}"; do
    ## Increment LINENUMBER
    LINENUMBER=`expr ${LINENUMBER} + 1`
    ## Parse paste mode from first buffer file line
    if test ${LINENUMBER} -eq 1; then
      case "${line}" in 
        "CUT" ) MODE="CUT";  C4P2_DEBUGPRINT "Parsed CUT";;
        "COPY") MODE="COPY"; C4P2_DEBUGPRINT "Parsed COPY";;
        ""    ) C4P2_DEBUGPRINT "Nothing to be done"; C4P2_EXIT_SUCCESS;;
        *     ) C4P2_PRINT "Bad buffer file!"; C4P2_EXIT_ERROR;;
      esac
    elif test ! -z "${line}"; then
      ## Test if the cut/copy target is actually valid
      if test ! -e "${line}"; then
        C4P2_PRINT "${C4P2_PPASTE_NAME}: '${line}' is not a valid file or folder!"
        C4P2_EXIT_ERROR
      fi
      ## Test if we can read the cut/copy target
      if test ! -r "${line}"; then
        C4P2_PRINT "${C4P2_PPASTE_NAME}: '${line}' is not readable!"
        C4P2_EXIT_ERROR
      fi
      ## Test if we can write the cut/copy target if in CUT mode
      if test "${MODE}" = "CUT" && test ! -w "${line}"; then
        C4P2_PRINT "${C4P2_PPASTE_NAME}: '${line}' is not writeable!"
        C4P2_EXIT_ERROR
      fi
      ## Test if we can write to the cut/copy target location
      if test ! -w "${PWD}"; then
        C4P2_PRINT "${C4P2_PPASTE_NAME}: Cannot write to target folder '${PWD}'!"
        C4P2_EXIT_ERROR
      fi

      ## Test if the paste target already exists and ask user for 
      #  overwrite confirmation (unless FORCE_OVERWRITE is set)
      linebasename=`basename "${line}"`
      if test -e "${PWD}/${linebasename}"; then
        overwrite=0
        if test ${FORCE_OVERWRITE} -eq 1; then
          overwrite=1
        elif test ${NO_OVERWRITE}  -eq 1; then
          overwrite=0
        else
          ## Needs '< /dev/tty' because this happens in a loop which
          #  gets its input from a file. Without the redefinition,
          #  this 'read' would read from the same file.
          read -p "${C4P2_PPASTE_NAME}: Overwrite '${linebasename}'? (y/[n]) " yesno < /dev/tty
          case "${yesno}" in
            [Yy]*) C4P2_PRINT "${C4P2_PPASTE_NAME}: Overwriting.."; overwrite=1;;
            *    ) C4P2_PRINT "${C4P2_PPASTE_NAME}: Skipping.."; overwrite=0;;
          esac
        fi
        if test ${overwrite} -eq 0; then
          continue
        fi
      fi
      
      ## Finally, perform the actual mv/cp action
      if   test "${MODE}" = "CUT" ; then
        C4P2_DEBUGPRINT "${C4P2_PPASTE_NAME}: "${CMD_MOVE}" -i ${line} ${PWD}/${linebasename}"
        "${CMD_MOVE}" "${line}" "${PWD}/${linebasename}"
      elif test "${MODE}" = "COPY"; then
        C4P2_DEBUGPRINT "${C4P2_PPASTE_NAME}: "${CMD_COPY}" -i -r ${line} ${PWD}/${linebasename}"
        "${CMD_COPY}" -r "${line}" "${PWD}/${linebasename}"
      fi
    fi
  done < "${C4P2BUFFER}"

  ## Not really a fatal error, but the buffer should not be empty...
  #  (the CUT operation writes "", but even that results in 1 char)
  if test ${LINENUMBER} -eq 0; then
    C4P2_DEBUGPRINT "${C4P2_PPASTE_NAME}: Buffer file is empty!"
    C4P2_EXIT_ERROR
  fi

  ## If pasted from CUT mode, clear buffer file
  if test "${MODE}" = "CUT"; then
    C4P2_DEBUGPRINT "${C4P2_PPASTE_NAME}: Resetting buffer file"
    C4P2_PRINT "" > "${C4P2BUFFER}"
  fi
fi


## Bye!
C4P2_EXIT_SUCCESS


