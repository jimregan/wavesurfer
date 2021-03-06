# snackConfig.sh --
# 
# This shell script (for sh) is generated automatically by Snack's
# configure script. It will create shell variables for most of
# the configuration options discovered by the configure script.
# This script is intended to be included by the configure scripts
# for Snack extensions so that they don't have to figure this all
# out for themselves.  This file does not duplicate information
# already provided by tclConfig.sh and tkConfig.sh, so you may
# need to use those files in addition to this one.
#
# The information in this file is specific to a single platform.
#

# Snack's version number.

SNACK_VERSION='2.2'

# Snack's installation path.

SNACK_INSTALL_PATH='${exec_prefix}/lib'

# String to pass to linker to pick up the Snack library from its
# installed directory.

SNACK_LIB_SPEC='-L${exec_prefix}/lib -lsnack'

# Platform specific audio definitions.

AINC='@AINC@'
ALIB='@ALIB@'
AFLAG='@AFLAG@'

# -l flag to pass to the linker to pick up the Snack stub library

SNACK_STUB_LIB_FLAG='-lsnackstub22'
