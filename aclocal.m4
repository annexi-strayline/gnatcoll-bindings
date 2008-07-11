## This file contains various m4 macros that can be included in your
## own projects to enable proper detection of the scripting languages
## In your own aclocal.m4 file, you can use syntax like
##   include(gnatcoll/aclocal.m4)

#############################################################
# Check whether GNAT on that target supports building shared
# libraries
# The following variables is exported by configure:
#   @GNAT_BUILDS_SHARED@: either "yes" or "no"
#   @DEFAULT_LIBRARY_TYPE@: either "static" or "relocatable"
#############################################################

AC_DEFUN(AM_GNAT_BUILDS_SHARED,
[
   AC_MSG_CHECKING(whether gnat can build shared libs)

   DEFAULT_LIBRARY_TYPE=static

   AC_ARG_ENABLE(shared,
     [AC_HELP_STRING(
        [--disable-shared],
        [Disable building of shared libraries])
AC_HELP_STRING(
        [--enable-shared],
        [Build shared libraries if supported on the target
Make them the installation default])],
     [GNAT_BUILDS_SHARED=$enableval
      if test $enableval = yes; then
         DEFAULT_LIBRARY_TYPE=relocatable
      fi],
     [GNAT_BUILDS_SHARED=yes])

   if test x$GNAT_BUILDS_SHARED = xyes; then
      # Create a temporary directory (from "info autoconf")
      : ${TMPDIR=/tmp}
      {
        tmp=`(umask 077 && mktemp -d "$TMPDIR/fooXXXXXX") 2>/dev/null` \
           && test -n "$tmp" && test -d "$tmp"
      } || {
        tmp=$TMPDIR/foo$$-$RANDOM
        (umask 077 && mkdir -p "$tmp")
      } || exit $?

      mkdir $tmp/lib
      echo "package Foo is end Foo;" > $tmp/foo.ads
      cat > $tmp/lib.gpr <<EOF
project Lib is
   for Source_Dirs use (".");
   for Library_Dir use "lib";
   for Library_Name use "lib";
   for Library_Kind use "relocatable";
end Lib;
EOF

      gnatmake -c -q -P$tmp/lib 2>/dev/null
      if test $? = 0 ; then
         GNAT_BUILDS_SHARED=yes
      else
         GNAT_BUILDS_SHARED=no
         DEFAULT_LIBRARY_TYPE=static
      fi
      rm -rf $tmp
      AC_MSG_RESULT($GNAT_BUILDS_SHARED)
   else
      AC_MSG_RESULT([no (--disabled-shared)])
   fi
   
   AC_SUBST(GNAT_BUILDS_SHARED)
   AC_SUBST(DEFAULT_LIBRARY_TYPE)
])

#############################################################
# Checking for syslog
# This checks whether syslog exists on this system.
# This module can be disabled with
#    --disable-syslog
# The following variables are exported by configure:
#    @WITH_SYSLOG@: either "yes" or "no"
############################################################

AC_DEFUN(AM_PATH_SYSLOG,
[
   AC_ARG_ENABLE(syslog,
     AC_HELP_STRING(
        [--disable-syslog],
        [Disable support for syslog [[default=enabled]]]),
     [WITH_SYSLOG=$enableval],
     [WITH_SYSLOG=yes])

   if test x$WITH_SYSLOG = xyes ; then
     AC_CHECK_HEADER([syslog.h],
                     [WITH_SYSLOG=yes],
                     [WITH_SYSLOG=no])
   fi

   AC_SUBST(WITH_SYSLOG)
])

#############################################################
# Checking for postgreSQL
# This checks whether the libpq exists on this system
# This module can be disabled with
#    --with-postgresql=path
# The following variables are exported by configure:
#   @WITH_POSTGRES@: whether postgres was detected
#   @LIBPQ@: path to libpq, or "" if not found
#############################################################

AC_DEFUN(AM_PATH_POSTGRES,
[
   AC_ARG_WITH(postgresql,
     [AC_HELP_STRING(
       [--with-postgresql=<path>],
       [Specify the full path to the PostgreSQL installation])
AC_HELP_STRING(
       [--without-postgresql],
       [Disable PostgreSQL support])],
     POSTGRESQL_PATH_WITH=$withval,
     POSTGRESQL_PATH_WITH=yes)

   PATH_LIBPQ=""
   if test x"$POSTGRESQL_PATH_WITH" = xno ; then
      AC_MSG_CHECKING(for PostgreSQL)
      AC_MSG_RESULT(no, use --with-postgresql if needed)
      WITH_POSTGRES=no

   else
     if test x"$POSTGRESQL_PATH_WITH" = xyes ; then
       AC_CHECK_LIB(pq,PQreset,WITH_POSTGRES=yes,WITH_POSTGRES=no)
     else
       PATH_LIBPQ="-L$POSTGRESQL_PATH_WITH"
       WITH_POSTGRES=yes
     fi
   fi

   AC_SUBST(WITH_POSTGRES)
   AC_SUBST(PATH_LIBPQ)
])

#############################################################
# Checking for python
# This checks whether python is available on the system, and if yes
# what the paths are. The result can be forced by using the
#    --with-python=path
# command line switch
# The following variables are exported by configure on exit:
#    @PYTHON_BASE@:    Either "no" or the directory that contains python
#    @PYTHON_VERSION@: Version of python detected
#    @PYTHON_CFLAGS@:  Compiler flags to use for python code
#    @PYTHON_DIR@:     Directory for libpython.so
#    @PYTHON_LIBS@:    extra command line switches to pass to the linker
#                      In some cases, -lpthread should be added. We do not
#                      add this systematically, to allow you to recompile
#                      your own libpython and avoid dragging the tasking
#                      Ada runtime in your application if you do not use it
#                      otherwise
#    @WITH_PYTHON@: either "yes" or "no" depending on whether
#                      python support is available.
#############################################################

AC_DEFUN(AM_PATH_PYTHON,
[
   AC_ARG_WITH(python,
     [AC_HELP_STRING(
       [--with-python=<path>],
       [Specify the full path to the Python installation])
AC_HELP_STRING(
       [--without-python],
       [Disable python support])],
     PYTHON_PATH_WITH=$withval,
     PYTHON_PATH_WITH=yes)
   AC_ARG_ENABLE(shared-python,
     AC_HELP_STRING(
       [--enable-shared-python],
       [Link with shared python library instead of static]),
     PYTHON_SHARED=$enableval,
     PYTHON_SHARED=no)

   WITH_PYTHON=yes
   if test x"$PYTHON_PATH_WITH" = xno ; then
      AC_MSG_CHECKING(for python)
      AC_MSG_RESULT(no, use --with-python if needed)
      PYTHON_BASE=no
      WITH_PYTHON=no

   else
      AC_PATH_PROG(PYTHON, python, no, $PYTHON_PATH_WITH/bin:$PATH)
      if test x"$PYTHON" = xno ; then
         PYTHON_BASE=no
         WITH_PYTHON=no
      else
        AC_MSG_CHECKING(for python >= 2.0)
        if test x"$PYTHON_PATH_WITH" != xyes ; then
           PYTHON_BASE=$PYTHON_PATH_WITH
        else
           PYTHON_BASE=`$PYTHON -c 'import sys; print sys.prefix' `
        fi

        PYTHON_MAJOR_VERSION=`$PYTHON -c 'import sys; print sys.version_info[[0]]' 2>/dev/null`
        if test x$PYTHON_MAJOR_VERSION != x2 ; then
           AC_MSG_RESULT(no, need at least version 2.0)
           PYTHON_BASE=no
           WITH_PYTHON=no
        else
           PYTHON_VERSION=`$PYTHON -c 'import sys; print \`sys.version_info[[0]]\`+"."+\`sys.version_info[[1]]\`'`

           if test x$PYTHON_SHARED = xyes; then
              PYTHON_DIR=${PYTHON_BASE}/lib
           else
              PYTHON_DIR=${PYTHON_BASE}/lib/python${PYTHON_VERSION}/config
           fi
           AC_MSG_RESULT(yes (version $PYTHON_VERSION))
        fi
      fi
   fi

   PYTHON_LIBS=""
   if test x"$PYTHON_BASE" != xno; then
      case "${host}" in
          hppa*-hp-hpux1* )
             PYTHON_LIBS="-Wl,-E -lm ${PYTHON_LIBS}"
             ;;
          powerpc-ibm-aix5.* ) 
             PYTHON_LIBS="-lld -lm ${PYTHON_LIBS}"
             ;;
          powerpc-*-darwin* )
             PYTHON_LIBS="-ldl -lm ${PYTHON_LIBS}"
             ;;
          *-sunos5.5* | *-solaris2.5* )
             PYTHON_LIBS="-lresolv -lsocket -lnsl -ldl -lm ${PYTHON_LIBS}"
             ;;
          *-sunos5* | *-solaris* )
             PYTHON_LIBS="-lresolv -lsocket -lnsl -ldl -lm ${PYTHON_LIBS}"
             ;;
          ia64-*-* )
             case "${host}" in
               *-linux-gnu* )
                  PYTHON_LIBS="-Wl,-export-dynamic -ldl -lm ${PYTHON_LIBS}"
                  ;;
               *-hp-hpux11* )
                  PYTHON_LIBS="-ldld -ldl -lm -Wl,-E ${PYTHON_LIBS}"
                  ;;
               *-sgi* )
                  PYTHON_LIBS="-lm ${PYTHON_LIBS}"
                  ;;
             esac
             ;;
          x86_64-*-* )
             PYTHON_LIBS="-Wl,-export-dynamic -lm -ldl ${PYTHON_LIBS}"
             ;;
          i[[3456]]86-*linux-gnu* )
             PYTHON_LIBS="-Wl,-export-dynamic -lm -ldl ${PYTHON_LIBS}"
             ;;
          i[[3456]]86-*win32* | i[[3456]]86-*mingw32* | i[[3456]]86-*cygwin* )
             ;;
          *-darwin* )
             PYTHON_LIBS="-ldl -lm ${PYTHON_LIBS}"
             ;;
          *-freebsd* )
             PYTHON_LIBS="-lm -lutil ${PYTHON_LIBS}"
             ;;
      esac

      PYTHON_LIBS="-L${PYTHON_DIR} -lpython${PYTHON_VERSION} ${PYTHON_LIBS}"
      PYTHON_CFLAGS="-I${PYTHON_BASE}/include/python${PYTHON_VERSION}"

      # Automatically check whether some libraries are needed to link with
      # the python libraries. If you are using the default system library, it is
      # generally the case that at least -lpthread will be needed. But you might
      # also have recompiled your own version, and if it doesn't depend on
      # pthreads, we shouldn't bring that in, since that also impacts the choice
      # of the GNAT runtime

      CFLAGS="${CFLAGS} ${PYTHON_CFLAGS}"
      LIBS="${LIBS} ${PYTHON_LIBS}"
      AC_LINK_IFELSE(
        [AC_LANG_PROGRAM([#include <Python.h>],[Py_Initialize();])],
        [],
        [LIBS="${LIBS} -lpthread -lutil"
         AC_LINK_IFELSE(
           [AC_LANG_PROGRAM([#include <Python.h>],[Py_Initialize();])],
           [PYTHON_LIBS="${PYTHON_LIBS} -lpthread -lutil"],
           [AC_MSG_FAILURE([Can't compile and link python example])])])
   fi

   AC_SUBST(PYTHON_BASE)
   AC_SUBST(PYTHON_VERSION)
   AC_SUBST(PYTHON_DIR)
   AC_SUBST(PYTHON_LIBS)
   AC_SUBST(PYTHON_CFLAGS)
   AC_SUBST(WITH_PYTHON)
])

###########################################################################
## Checking for pygtk
##   $1=minimum pygtk version required
## This function checks whether pygtk exists on the system, and has a recent
## enough version. It exports the following variables:
##    @WITH_PYGTK@:    "yes" or "no"
##    @PYGTK_PREFIX@:  installation directory of pygtk
##    @PYGTK_INCLUDE@: cflags to use when compiling a pygtk application
## This function must be called after the variable PKG_CONFIG has been set,
## ie probably after gtk+ itself has been detected. Python must also have been
## detected first.
###########################################################################


AC_DEFUN(AM_PATH_PYGTK,
[
    AC_ARG_ENABLE(pygtk,
      AC_HELP_STRING(
        [--disable-pygtk],
        [Disable support for PyGTK [[default=enabled]]]),
      [WITH_PYGTK=$enableval],
      [WITH_PYGTK=$WITH_PYTHON])

    if test "$PKG_CONFIG" = "" -o "$PKG_CONFIG" = "no" ; then
       AC_MSG_CHECKING(for pygtk)
       AC_MSG_RESULT(no (pkg-config not found))
       WITH_PYGTK=no
    else
       min_pygtk_version=ifelse([$1], ,2.8,$1)
       module=pygtk-2.0
       AC_MSG_CHECKING(for pygtk - version >= $min_pygtk_version)

       if test x"$WITH_PYGTK" = x -o x"$WITH_PYGTK" = xno ; then
          AC_MSG_RESULT(no)
          PYGTK_PREFIX=""
          PYGTK_INCLUDE=""
          WITH_PYGTK=no

       elif test "$PYTHON_BASE" != "no" ; then
          pygtk_version=`$PKG_CONFIG $module --modversion`
          $PKG_CONFIG $module --atleast-version=$min_pygtk_version
          if test $? = 0 ; then
             PYGTK_INCLUDE="`$PKG_CONFIG $module --cflags` -DPYGTK"
             PYGTK_PREFIX=`$PKG_CONFIG $module --variable=prefix`
             AC_MSG_RESULT(yes (version $pygtk_version))
             WITH_PYGTK=yes
          else
             AC_MSG_RESULT(no (found $pygtk_version))
             PYGTK_PREFIX=""
             PYGTK_INCLUDE=""
             WITH_PYGTK=no
          fi

       else
          AC_MSG_RESULT(no since python not found)
          PYGTK_PREFIX=""
          PYGTK_INCLUDE=""
          WITH_PYGTK=no
       fi
    fi

    AC_SUBST(PYGTK_PREFIX)
    AC_SUBST(PYGTK_INCLUDE)
    AC_SUBST(WITH_PYGTK)
])

##########################################################################
## Converts a list of space-separated words into a list suitable for
## inclusion in .gpr files
##   $1=the list
##   $2=exported name
##########################################################################

AC_DEFUN(AM_TO_GPR,
[
   value=[$1]
   output=$2
   result=""
   for v in $value; do
      if test "$result" != ""; then
         result="$result, "
      fi
      result="$result\"$v\""
   done
   $2=$result
   AC_SUBST($2)

])

##########################################################################
## Check the availability of a project file
## The file is searched on the predefined PATH and (ADA|GPR)_PROJECT_PATH
##   $1=project to test
##   $2=exported name
##########################################################################

AC_DEFUN(AM_PATH_PROJECT,
[
   project=[$1]
   output=$2

   # Create a temporary directory (from "info autoconf")
   : ${TMPDIR=/tmp}
   {
     tmp=`(umask 077 && mktemp -d "$TMPDIR/fooXXXXXX") 2>/dev/null` \
        && test -n "$tmp" && test -d "$tmp"
   } || {
     tmp=$TMPDIR/foo$$-$RANDOM
     (umask 077 && mkdir -p "$tmp")
   } || exit $?

   mkdir $tmp/lib
   echo "with \"$project\"; project default is for Source_Dirs use (); end default;" > $tmp/default.gpr

   gnat make -P$tmp/default.gpr >/dev/null 2>/dev/null
   if test $? = 0 ; then
     $2=yes
   else
     $2=no
   fi
   AC_SUBST($2)
])

##########################################################################
## Detects GTK and GtkAda
## This exports the following variables
##     @PKG_CONFIG@: path to pkg-config, or "no" if not found
##     @GTK_GCC_FLAGS@: cflags to pass to the compiler. It isn't call
##                      GTK_CFLAGS for compatibility reasons with GPS
##     @WITH_GTK@: Either "yes" or "no", depending on whether gtk+ was found
##########################################################################

AC_DEFUN(AM_PATH_GTK,
[
   AC_ARG_ENABLE(gtk,
     AC_HELP_STRING(
       [--disable-gtk],
       [Disable support for GTK [[default=enabled]]]),
     [WITH_GTK=$enableval],
     [WITH_GTK=yes])


   if test $WITH_GTK = yes; then
     AC_PATH_PROG(PKG_CONFIG, pkg-config, no)
     AC_MSG_CHECKING(for gtk+)
     if test "$PKG_CONFIG" = "no" ; then
        AC_MSG_RESULT(not found)
        WITH_GTK=no
     else
        GTK_PREFIX=`$PKG_CONFIG gtk+-2.0 --variable=prefix`
        AC_MSG_RESULT($GTK_PREFIX)
        GTK_GCC_FLAGS=`$PKG_CONFIG gtk+-2.0 --cflags`
        if test x"$GTK_GCC_FLAGS" != x ; then
           AC_MSG_CHECKING(for gtkada)
           AM_PATH_PROJECT(gtkada, HAVE_GTKADA)
           if test "$HAVE_GTKADA" = "yes"; then
              AC_MSG_RESULT(found);
              WITH_GTK=yes
           else
              AC_MSG_RESULT(not found)
              WITH_GTK=no
           fi
        else
           WITH_GTK=no
        fi
     fi
   else
     AC_MSG_CHECKING(for gtk+)
     AC_MSG_RESULT($WITH_GTK (from switch))
   fi

   AC_SUBST(PKG_CONFIG)
   AC_SUBST(GTK_GCC_FLAGS)
   AC_SUBST(WITH_GTK)

])
