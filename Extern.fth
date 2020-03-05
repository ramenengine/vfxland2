\ Extern.fth - DLL and shared library access for VFX Forth

((
Copyright (c) 2001-2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2017
MicroProcessor Engineering
133 Hill Lane
Southampton SO15 5AF
England

tel: +44 (0)23 8063 1441
net: mpe@mpeforth.com
     tech-support@mpeforth.com
web: www.mpeforth.com

From North America, our telephone and fax numbers are:
  011 44 23 8063 1441


To do
=====

Change history
==============
20170223 JD_024 Added more Windows types.
                Added _Reserved_, [in] for Windows.
20140521 SFP023 Enhanced parsing of *** types.
20131119 SFP022	Made LOCATE go to first line of EXTERN:
20130520 SFP021 Exposed INIT-LIB. Added CLEAR-LIB.
2012xxyy SFP020 Added compatibility words for other Forths.
20120418 SFP019 Added FRAMEWORK and FRAMEWORK: for OSX.
		Allowed library and framework redefinitions
		to be ignored.
20120411 SFP018 Prevented inlining of words containing EXTERNs.
20120312 SFP017 Added EXTERNVAR and ALIASEDEXTERNVAR.
20111104 SFP016 More testing for tabs.
20111021 SFP016 Added #BADEXTERNS #BADLIBS and .BADLIBS.
20111004 SFP015 Added PLONG to Windows types.
20110912 SFP014 Added library mode options.
20110427 SFP013 Added additional pointer parsing.
                Added __IN_OPT, __INOUT_OPT and __OUT_OPT for Windows.
20110415 SFP012 Supports C // and /*...*/ comments in argument
                parsing.
                Added __IN, __INOUT and __OUT for Windows.
                Added ** and ***.
20100223 SFP011 Added protection mechanism to Externs.
20100222 SFP010 Moved PREEXTERN and POSTEXTERN to Forth voc.
20091123 SFP009	Refactored with startup.fth.
20090610 SFP008 Added documentation for FLAG from Marcel Hendrix.
20090609 SFP007 Added .BADEXTERNS.
20090502 SFP006	Added code for Windows protection with floats.
20020323 MPE005 Refactored client specific code in prologue and
                epilogue.
20090319 MPE004 Modified after distribution list discussions.
20090310 MPE003 Refactored.
20090131 MPE002 Tightened up.
		Put most words in separate vocabulary.
20090121 MPE001 Ported from the Windows/Linux version.
))


\ =========
\ *! extern
\ *T Functions in DLLs and shared libraries
\ =========

((
Licence
=======
This code can be used as the basis of an implementation of the
EXTERN: interface for other Forth systems. Copyright of the source
notation and behaviour is retained by MicroProcessor Engineering Ltd.
until another copyright has been assigned to a third party by
MicroProcessor Engineering Ltd..

Controlled words can be identified by comments starting
  \ *G
below the name line.

If you implement the notation and behaviour and release the source
code, this licence must be included in the source code.

Rationale and Requests
======================
The rationale for releasing this code is to encourage portability
of Forth source code that accesses shared libraries.

The point of retaining copyright at MPE is not to prevent you
changing and improving the system, it is to provide a central
point of management for the notation and its behaviour. In the
long term, copyright of the EXTERN: notation will be assigned
to a third party.

If your code is better, faster, shorter or more functional, we
request that you contribute it back to the maintainer, currently
Stephen Pelc, stephen@mpeforth.com. Similarly ports for currently
unsupported Forth systems will be gratefully received.

VFXisms
=======
DONOTSIN can be removed or be a NOOP.

.LWORD ( x -- ) and .DWORD ( x -- )
Display x as an unsigned hex number.

: -leading      bl skip  ;
: -white        -leading -trailing  ;

The code is based around three words which can be implemented
for any Windows or Unix-style host.
  LoadLibrary      \ zaddr -- handle|0
  FreeLibrary      \ handle -- status
  GetProcAddress   \ handle zaddr -- addr|0


Legacy code
===========
The words L>R and R>L are for compiling library code from other
Forth systems which may use a right-to-left stack order.
))

only forth definitions decimal

[undefined] externals [if]
vocabulary externals
\ Where library and imported function definitions live.
[then]
vocabulary types	\ --
\ Where the "C" style types go for the *\fo{EXTERN:} notation.
vocabulary Extern.Voc
\ Where the guts of the EXTERN: mechanism live.

also Extern.Voc definitions


\ ***************
\ *S Introduction
\ ***************
\ *P VFX Forth supports calling external API calls in dynamic link
\ ** libraries (DLLs) for Windows and shared libraries in Linux and
\ ** other Unix-derived operating systems.
\ ** Various API libraries export functions in a variety of methods
\ ** mostly transparent to programmers in languages such as C,
\ ** Pascal and Fortran. Floating point data is supported for use
\ ** with *\i{Lib\x86\Ndp387.fth}.

\ *P Before a library function can be used, the library itself must
\ ** be declared, e.g.
\ *E LIBRARY: Kernel32.dll

\ *P Access to functions in a library is provided by the
\ ** *\fo{EXTERN:} syntax which is similar to a C style function
\ ** prototype, e.g.
\ *E EXTERN: int PASCAL SendMessage(
\ **   HWND hwnd, DWORD mesg, WPARAM wparam, LPARAM lparam
\ ** );
\ *P This can be used to prototype the function *\b{SendMessage}
\ ** from the Microsoft Windows API, and produces a Forth word
\ ** *\fo{SendMessage}.
\ *C   SendMessage  \ hwnd mesg wparam lparam -- int

\ *P For Linux and other Unices, the same notation is used.
\ ** The default calling convention is nearly always applicable.
\ ** The following example shows that definitions can occupy more
\ ** than one line. It also indicates that some token separation may
\ ** be necessary for pointers:
\ *E Library: libc.so.6
\ **
\ ** Extern: int execve(
\ **   const char * path,
\ **   char * const argv[],
\ **   char * const envp[]
\ ** );
\ *P This produces a Forth word *\fo{execve}.
\ *C   execve       \ path argv envp -- int

\ *P The parser used to separate the tokens is not ideal. If you
\ ** have problems with a definition, make sure that *\fo{*}
\ ** tokens are white-space separated. Formal parameter names,
\ ** e.g. *\i{argv} above are ignored. Array indicators, *\i{[]}
\ ** above, are also ignored when part of the names.

\ *P The input types may be followed by a dummy name which is
\ ** discarded. Everything on the source line after the closing
\ ** ')' is discarded.

\ *P From VFX Forth v4.3 onwards, PASCAL is the default calling
\ ** convention in the Windows version. The default for the Linux
\ ** and OS X versions is "C". The default is always used unless
\ ** overridden in the declaration.


\ *********
\ *S Format
\ *********
\ *E EXTERN: <return> [ <callconv> ] <name> '(' <arglist> ')' ';'
\ **
\ ** <return>    := { <type> [ '*' ] |  void }
\ ** <arg>       := { <type> [ '*' ] [ <name> ] }
\ ** <args>      := { [ <arg>, ]* <arg> }
\ ** <arglist>   := { <args> | void }	Note: "void, void" etc. is illegal.
\ ** <callconv>  := { PASCAL | WINAPI | STDCALL | "PASCAL" | "C" }
\ ** <name>      := <any Forth acceptable namestring>
\ ** <type>      := ... (see below, "void" is a valid type)

\ *P Note that during searches <name> is passed to the operating
\ ** system exactly as it is written, i.e. case sensitive. The
\ ** Forth name is case-insensitive.

\ *P As a standard Forth's string length for dictionary names is
\ ** only guaranteed up to 31 characters for portable source code,
\ ** very long API names can cause problems. Therefore the word
\ ** *\fo{AliasedExtern:} allows separate specification of API
\ ** and Forth names (see below). *\fo{AliasedExtern:} also
\ ** solves problems when API functions only differ in case
\ ** or their names conflict with existing Forth word names.

\ **********************
\ *S Calling Conventions
\ **********************
\ *P In the discussion *\b{caller} refers to the Forth system
\ ** (below the application layer and *\b{callee} refers to a
\ ** a function in a DLL or shared library. The *\fo{EXTERN:}
\ ** mechanism supports three calling conventions.
\ *(
\ *B C-Language: *\fo{"C"} *\br{}
\ **  Caller tidies the stack-frame.
\ ** The arguments (parameters) which are passed to the library
\ ** are reordered. This convention can be specified by using
\ ** *\fo{"C"} after the return type specifier and
\ ** before the function name. For Linux and most Unix-derived
\ ** operating systems, this is the default.
\ *B Pascal language: *\fo{"PASCAL"} *\br{}
\ ** Callee removes arguments from the stack frame. This is
\ ** invisible to the programmer at the application layer
\ ** The arguments (parameters) which are passed to the library are
\ ** not reordered. This convention is specified by
\ ** *\fo{"PASCAL"} after the return type specifier and
\ ** before the function name.
\ *B Windows API: *\fo{WINAPI | PASCAL | STDCALL} *\br{}
\ ** In nearly all cases (but *\b{not all}), calls to
\ ** Windows API functions require C style argument reversal and
\ ** the called function cleans up. Specify this convention with
\ ** *\fo{PASCAL}, *\fo{WinAPI} or *\fo{StdCall} after the
\ ** return type specifier and before the function name. For
\ ** Windows, this is the default.
\ *)

\ *P Unless otherwise specified, the Forth system's default
\ ** convention is used. Under Windows this is *\fo{WINAPI} and
\ ** under Linux and other Unices it is *\fo{"C"}.

\ *************************
\ *S Promotion and Demotion
\ *************************
\ *P The system generates code to either promote or demote non-CELL
\ ** sized arguments and return results which can be either signed or
\ ** unsigned. Although Forth is an un-typed language it must deal with
\ ** libraries which do have typed calling conventions. In general
\ ** the use of non-CELL arguments should be avoided but return
\ ** results should be declared in Forth with the same size as the C or
\ ** PASCAL convention documented.

\ ********************
\ *S Argument Reversal
\ ********************
\ *P The default calling convention for the host operating system
\ ** is used. The right-most argument/parameter in the C-style
\ ** prototype is on the top the Forth data stack.
\ ** When calling an external function the parameters are reordered
\ ** if required by the operating system; this is to enable the
\ ** argument list to read left to right in Forth source as well
\ ** as in the C-style operating system documentation.

\ *P Under certain conditions, the order can be reversed. See the
\ ** words *\fo{"C"} and *\fo{"PASCAL"} which define the order for
\ ** the operating system. See *\fo{L>R} and *\fo{R>L} which define
\ ** the Forth stack order with respect to the arguments in the
\ ** prototype.

\ *****************************
\ *S C comments in declarations
\ *****************************
\ *P Very rudimentary support for C comments in declarations is
\ ** provided, but is good enough for the vast majority of
\ ** declarations.
\ *(
\ *B Comments can be *\fo{// ...} or *\fo{/* ... */},
\ *B Comments must be at the end of the line,
\ *B Comments are treated as extending to the end of the line,
\ *B Comments must not contain the ')' character.
\ *)
\ *P The example below is taken from a *\i{SQLite} interface.
\ *E Extern: "C" int sqlite3_open16(
\ **   const void * filename,  /* Database filename [UTF-16] */
\ **   sqlite3 ** ppDb         /* OUT: SQLite db handle */
\ ** );


\ **********************************
\ *S Controlling external references
\ **********************************

also forth definitions
1 value ExternWarnings?	\ -- n
\ *G Set this true to get warning messages when an external reference
\ ** is redefined.
0 value ExternRedefs?	\ -- n
\ *G If non-zero, redefinitions of existing imports are permitted.
\ ** Zero is the default for VFX Forth so that redefinitions of
\ ** existing imports are ignored.
1 value LibRedefs?	\ -- n
\ *G If non-zero, redefinitions of existing libraries are permitted.
\ ** Non-zero is the default for VFX Forth so that redefinitions of
\ ** existing libraries and OS X frameworks are permitted. When set
\ ** to zero, redefinitions are silently ignored.
1 value InExternals?	\ -- n
\ *G Set this true if following import definitions are to be in
\ ** the *\fo{EXTERNALS} vocabulary, false if they are to go into
\ ** the wordlist specified in *\fo{CURRENT}. Non-Zero is the
\ ** default for VFX Forth.
: InExternals	\ --
\ *G External imports are created in the *\fo{EXTERNALS} vocabulary.
  1 -> InExternals?  ;
: InCurrent	\ --
\ *G External imports are created in the wordlist specified by
\ ** *\fo{CURRENT}.
  0 -> InExternals?  ;
previous definitions

' externals voc>wid constant Externals.wid
\ The wordlist ID of the EXTERNALS vocabulary.


\ ******************
\ *S Library Imports
\ ******************
\ *P In VFX Forth, libraries are held in the *\fo{EXTERNALS}
\ ** vocabulary, which is part of the minimum search order.
\ ** Other Forth systems may use the *\fo{CURRENT} wordlist.

\ *P For turnkey applications, initialisation, release and
\ ** reload of required libraries is handled at start up.

(( for DocGen
variable lib-link	\ -- addr
\ *G Anchors the chain of dynamic/shared libraries.
))
variable lib-mask	\ -- addr
\ *G If non-zero, this value is used as the mode for *\fo{dlopen()}
\ ** calls in Linux and OS X.

struct /libstr	\ -- size
\ *G The structure used by a *\fo{Library:} definition.
\ *[
  int >liblink		\ link to previous library
  int >libaddr		\ library Id/handle/address, depends on O/S
  int >libmask		\ mask for dlopen()
  0 field >libname	\ zero terminated string of library name
end-struct
\ *]

struct /funcstr	\ -- size
\ *G The structure used by an imported function.
  int >funclink		\ link to previous function
  int >funcaddr		\ function address
  0 field >funcname	\ zero terminated string of function name
end-struct

also forth definitions

[defined] Target_386_Windows [if]
1 constant RTLD_LAZY
: init-lib	\ libstr --
\ *G Given the address of a library structure, load the library.
  dup >libname LoadLibrary swap >libaddr !  ; doNotSin
[then]

[defined] Target_386_Linux [if]
((
\ from /usr/include/bits/dlfcn.h
/* The MODE argument to `dlopen' contains one of the following: */
#define RTLD_LAZY	0x00001	/* Lazy function call binding.  */
#define RTLD_NOW	0x00002	/* Immediate function call binding.  */
#define	RTLD_BINDING_MASK   0x3	/* Mask of binding time value.  */
#define RTLD_NOLOAD	0x00004	/* Do not load the object.  */
#define RTLD_DEEPBIND	0x00008	/* Use deep binding.  */

/* If the following bit is set in the MODE argument to `dlopen',
   the symbols of the loaded object and its dependencies are made
   visible as if the object were linked directly into the program.  */
#define RTLD_GLOBAL	0x00100

/* Unix98 demands the following flag which is the inverse to RTLD_GLOBAL.
   The implementation does this by default and so we can define the
   value to zero.  */
#define RTLD_LOCAL	0

/* Do not delete object when closed.  */
#define RTLD_NODELETE	0x01000
))
1 constant RTLD_LAZY		\ -- x
$0102 constant RTLD_NOW_GLOBAL	\ -- x
: init-lib	\ libstr --
\ Given the address of a library structure, load the library.
  dup >libmask @
  if  dup >libmask @ loadLibMask !  then
  dup >libname LoadLibrary swap >libaddr !  ; doNotSin

: isRTLD_Now_Global	\ --
  RTLD_NOW_GLOBAL lib-mask !  ;
[then]

[defined] Target_386_OSX [if]
(( \ from /usr/include/dlfcn.h 10.7
#define RTLD_LAZY	0x1
#define RTLD_NOW	0x2
#define RTLD_LOCAL	0x4
#define RTLD_GLOBAL	0x8
))
1 constant RTLD_LAZY
$000A constant RTLD_NOW_GLOBAL	\ -- x
: init-lib	\ libstr --
\ Given the address of a library structure, load the library.
  dup >libname LoadLibrary swap >libaddr !  ; doNotSin

: isRTLD_Now_Global	\ --
  RTLD_NOW_GLOBAL lib-mask !  ;
[then]

: clear-lib	\ libstr --
\ *G Unload the given library and zero its load address.
  dup >libaddr @ FreeLibrary drop  >libaddr off
; doNotSin

: clear-libs    \ --
\ *G Clear all library addresses.
  lib-link
  begin
    @ dup
  while
    0 over >libaddr !
    >liblink
  repeat
  drop
; \ doNotSin

: init-libs     \ --
\ *G Release and reload the required libraries.
  clear-libs  lib-link
  begin
    @ dup
  while
    dup init-lib  >liblink
  repeat
  drop
;
' init-libs AtCold

: find-libfunction	\ z-addr -- address|0
\ *G Given a zero terminated function name, attempt to find the
\ ** function somewhere within the already active libraries.
  >r  lib-link
  begin					\ -- link ; R: -- z$
    @ dup
  while                 		\ -- struct ; R: -- z$
    dup >libaddr @ r@ GetProcAddress dup \ -- struct addr|0 addr|0 ; R: -- z$
    if  nip  r> drop exit  endif
    drop >liblink
  repeat
  drop  r> drop 0
;

: .Libs         \ --
\ *G Display the list of declared libraries.
  lib-link
  begin
    @ dup
  while
    dup >libname cr .z$
    out @ 31 and 32 swap - spaces
    dup >libaddr @ .lword
    >liblink
  repeat
  drop
;

: #BadLibs	\ -- u
\ *G Return the number of declared libraries that have not yet been
\ ** loaded.
  0 lib-link
  begin
    @ dup
  while
    dup >libaddr @ 0= if
      swap 1+ swap
    then
    >liblink
  repeat
  drop
;

: .BadLibs         \ --
\ *G Display a list of declared libraries that have not yet been
\ ** loaded.
  0 lib-link
  begin
    @ dup
  while
    dup >libaddr @ 0= if
      dup >libname cr .z$
      swap 1+ swap
    then
    >liblink
  repeat
  drop
  cr . ." Unresolved Libraries"
;

: Library:      \ "<name>" -- ; -- loadaddr|0
\ *G Register a new library by name.
\ ** If *\fo{LibRedefs?} is set to zero, redefinitions are silently
\ ** ignored.
\ ** Use in the form:
\ *C   LIBRARY: <name>
\ *P Executing *\fo{<name>} later will return its load address.
\ ** This is useful when checking for libraries that may not be
\ ** present. After definition, the library is the first one
\ ** searched by import declarations.
  LibRedefs? 0= if			\ ignore redefinitions?
    >in @ parse-name search-context	\ already defined?
    if  drop drop exit  endif
    >in !
  endif
  >in @  get-current  InExternals?	\ save >IN, which wordlist?
  if  Externals.wid set-current  then	\ -- >in wid
  create
    set-current  >in !			\ restore wordlist and >IN
    here				\ start of  structure
    lib-link link,			\ link to previous library
    0 ,					\ load address, filled in later
    lib-mask @ ,  lib-mask off		\ mask for dlopen(), 0 = use default
    bl word $>z,			\ lay name as zero terminated string
    init-lib
  does>
    >libaddr @
;

: topLib	\ libstr --
\ *G Make the library structure the top/first in the library
\ ** search order.
  lib-link  2dup delLink  AddLink  ;

: firstLib	\ "<name>" --
\ *G Make the library first in the library search order. Use during
\ ** interpretation in the form:
\ *C   FirstLib <name>
\ *P to make the library first in the search order. This is useful
\ ** when you know that there may be several functions of the
\ ** same name in different libraries.
  ' >body topLib  ;

: [firstLib]	\ "<name>" --
\ *G Make the library first in the library search order. Use during
\ ** compilation in the form:
\ *C   [firstLib] <name>
\ *P to make the library first in the search order. This is useful
\ ** when you know that there may be several functions of the
\ ** same name in different libraries.
  ' >body postpone literal  postpone topLib
; immediate

previous definitions


\ ======================
\ *N Mac OS X extensions
\ ======================
\ *P The phrase *\fo{Framework <name.framework>} creates two Forth words,
\ ** one for the library access, the other to make that library top in
\ ** the search order. For example:
\ *C   framework Cocoa.framework
\ *P produces two words
\ *C   Cocoa.framework/Cocoa
\ *C   Cocoa.framework
\ *P The first word is the library definition itself, which
\ ** behaves in the normal VFX Forth way, returning its load
\ ** address or zero if not loaded. The second word forces
\ ** the library to be top/first in the library search order.
\ ** Thanks to Roelf Toxopeus.

\ *P As of OSX 10.7, *\fo{FRAMEWORK} (actually *\b{dlopen()})
\ ** will search for frameworks in all the default Frameworks
\ ** directories:
\ *(
\ *B /Library/Frameworks
\ *B /System/Library/Frameworks
\ *B ~/Library/Frameworks
\ *)

[defined] Target_386_OSX [if]

also forth definitions

: framework	\ --
\ *G Build the two framework words. See above for more details.
\ ** If *\fo{LibRedefs?} is set to zero, redefinitions are silently
\ ** ignored.
  {: | buff[ #256 ] -- :}
  LibRedefs? 0= if			\ ignore redefinitions?
    >in @ parse-name search-context	\ already defined?
    if  drop drop exit  endif
    >in !
  endif
  >in @
  s" Library: " buff[ place		\ build library: name.framework/name
  parse-name 2dup buff[ append		\ Library: name.framework
  s" /" buff[ append			\ Library: name.framework/
  #10 - buff[ append			\ Library: name.framework/name
  buff[ count evaluate
  >in !
  create
    lib-link @ ,			\ address of last library structure
  does>
    @ toplib
;

previous definitions

[then]


\ *******************
\ *S Function Imports
\ *******************
\ *P Function declarations in shared libraries are compiled into
\ ** the *\fo{EXTERNALS} vocabulary. They form a single linked
\ ** list. When a new function is declared, the list of previously
\ ** declared libraries is scanned to find the function. If the
\ ** function has already been declared, the new definition is
\ ** ignored if *\fo{ExternRedefs?} is set to zero. Otherwise,
\ ** the new definition overrides the old one as is usual
\ ** in Forth.

\ *P In VFX Forth, *\fo{ExternRedefs?} is zero by default.

(( for DocGen
variable import-func-link	\ -- addr
\ *G Anchors the chain of imported functions in shared libraries.
))

[defined] Target_386_Windows [if]
: resolve-libfunction   \ z-addr -- address|0
\ +G Look up a definition in loaded libraries and return XT or 0.
\ +* Automatically attempts to find a version with 'A' appended for
\ +* Windows.
  { | tn[ MAX_PATH ] -- }
  [ also system ]
  dup find-libfunction dup		\ look for raw name
  if  nip exit  then
  drop
  tn[ MAX_PATH erase			\ look for name with 'A' appended
  zcount tn[ swap move
  [char] A tn[ zcount + c!
  tn[ find-libfunction
  [ previous ]
;
[else]
: resolve-libfunction   \ z-addr -- address|0
  [ also system ]
  find-libfunction			\ look for raw name
  [ previous ]
;
[then]

: resolveImport	\ struct --
\ Resolve the imported function whose structure is given.
  dup >funcname resolve-libfunction swap >funcaddr !  ;

also forth definitions
: ExternLinked	\ c-addr u -- address|0
\ *G Given a string, attempt to find the named function in  the
\ ** already active libraries. Returns zero when the function is
\ ** not found.
  { | temp[ 256 ] -- }
  255 min temp[ zplace
  temp[ resolve-libfunction
;

: init-imports  \ --
\ *G Initialise Import libraries. *\fo{INIT-IMPORTS} is called by
\ ** the system cold chain.
  import-func-link @
  begin
    dup
  while
    dup resolveImport
    >funclink @
  repeat
  drop
;
' init-imports AtCold
previous definitions


\ ********************************
\ +S Import parsing and generation
\ ********************************

\ ======================
\ +N Data and structures
\ ======================

\ These are constants used as THROW codes with associated text messages.
SysErrdef err_ImpType	"Invalid type in EXTERN: import"
SysErrDef err_CGsize	"Invalid size in EXTERN: argument preparation"
SysErrDef err_RetType	"Invalid return type"
SysErrDef err_RetSize	"Invalid return size"

\ argument types - BOOL could be considered a form of UINT, but
\ is O/S specific.
0 constant SINTtype	\ -- n ; default is signed int
1 constant UINTtype	\ -- n ; signed int
2 constant BOOLtype	\ -- n ; C boolean
3 constant FLOATtype	\ -- n ; float/double/ext ....

struct /argItem	\ -- len
  int ai.Size		\ argument size in bytes, 0=void, 1=byte/char, 2=short, 4=int ...
  int ai.type		\ 0=uint, 1=sint, 2=bool, 3=float
  int ai.FrameOff	\ offset on operating system frame to data
  int ai.PSPoff		\ offset on Forth parameter stack as if TOS uncached
end-struct
#32 /argitem * constant /argList	\ size of the argument list, max 32 items


\ Operating system dependent items. These VALUEs are set to
\ defaults at the start of each external import declaration.

0 value CalleeCleaned?	\ -- flag
\ 0 = "C", 1 = "PASCAL", used for cleanup only. If the calling
\ mechanism preserves the Forth stack pointers, this value is not
\ needed.
16 value FrameAlignment	\ -- u
\ Set to alignment of stack frame in memory. Must be a power of two.
4 value FrameBackup	\ -- u
\ If the stack must be aligned after the call, set this to the
\ number of byes used by the call
true value AlignInFrame? \ -- flag
\ True if items on the stack frame are padded for data alignment.
true value REQUIRE_NREV	\ -- flag
\ Set true if arguments are reversed by default (C argument order),
\ i.e. the leftmost argument in the argument declaration list is
\ on the top of the O/S stack.
true value L>R?		\ -- flag
\ Set true when the Forth stack order matches the argument
\ declaration order.
0 value ObjPtr?		\ -- flag
\ True if an object-oriented call is required, i.e. a hidden
\ "this" pointer is used. The location of "this" is compiler and
\ OS dependent.
\   0 = none
\   1 = VC++, pointer in ECX
\   2 = gcc, pointer on top, but below struct pointer (see below)
0 value StructRet?	\ -- flag
\ Set this true if the import returns a structure and requires a
\ hidden structure pointer. The location of the structure pointer
\ is compiler and OS dependent.
\   0 = none
\   1 = VC++
\   2 = gcc
0 value varargs?	\ -- flag
\ Set this true if the parameter list is of variable length.

defer setDefExt	\ --
\ Set the call type defaults in the VALUEs above.

#256 buffer: importName		\ name of DLL function
#256 buffer: externName		\ name of Forth word
variable usesFloats		\ non-zero if FP arguments or return ; SFP006
variable NumArgs		\ number of input arguments
variable NumInts		\ number of arguments on Forth data stack
variable NumFloats		\ number of arguments on Forth Float stack
variable /DataFrame		\ total size of data frame with padding
variable /ForthFrame		\ number of bytes taken from Forth stack
/argItem buffer: ReturnRes	\ structure for return data
/argList buffer: ArgList	\ argument data during compilation

0 value LastImport		\ address of current/last import structure

: .ArgType	\ n --
  case
    SINTtype of  ." SINT"  endof
    UINTtype of  ." UINT"  endof
    BOOLtype of  ." BOOL"  endof
    FLOATtype of  ." Float"  endof
      ." ???"
  endcase
;

: .ArgData	\ ^ai --
\ Display the argument data
  cr ." Size: " dup ai.size @ dup 0 .r
  0= if
    drop  ."  (void)"
  else
    ." , Type: " dup ai.Type @ .ArgType
    ." , PSP: " dup ai.PSPoff @ 0 .r
    ." , Frame: " ai.FrameOff @ 0 .r
  endif
;

: ArgList[]	\ u -- addr
\ Return the address of the uth item in argList
  /argItem * argList +  ;

: .ArgList	\ --
\ Display the calculated argument and return data.
  cr ." Arguments"  numArgs @ 0
  ?do  i ArgList[] .ArgData  loop
  cr ." --" cr ." Returns"
  ReturnRes .ArgData
;

: CalcSource	\ ^ai --
\ Generate the source Forth data for the given argument.
  dup ai.type @ FLOATtype = if
    drop  numFloats incr
  else
    /ForthFrame @ over ai.PSPoff !
    ai.size @ aligned /ForthFrame +!
    numInts incr
  endif
; doNotSin

: CalcForthOff	\ --
\ Calculate the offsets of data items on the Forth input stack.
\ The Forth order is only affected by the choice of L>R or R>L
\ ordering. By default we use L>R.
  numArgs @ if
    L>R? if
      0 numArgs @ 1-
      do  i ArgList[] CalcSource  -1 +loop
    else
      numArgs @ 0
      do  i ArgList[] CalcSource  loop
    endif
  endif
; doNotSin

: AlignFrame	\ n --
\ Force frame alignment of a item of the given size to an N byte
\ boundary where N is a power of two.
  /DataFrame @ FrameBackup +		\ offset w.r.t frame after call
  over 1- +  swap negate and		\ -- dp'
  FrameBackup - /DataFrame !
; doNotSin

: ?AlignFrame	\ size --
\ Force frame alignment of a item of the given size to an N byte
\ boundary where N is a power of two. Ignore void items.
  ?dup if
    aligned AlignInFrame?
    if  AlignFrame  else  drop  endif
  endif
; doNotSin

: CalcDest	\ ^ai --
\ Generate the destination frame data for the given argument.
  dup ai.size @ ?AlignFrame
  /DataFrame @ over ai.FrameOff !
  ai.size @ aligned /DataFrame +!
; doNotSin

: CalcFrameOff	\ --
\ Calculate the O/S stack offsets. These are from the C-style
\ argument list, and so are unaffected by R>L, which only affects
\ the source offsets on the Forth stack with respect to the
\ declaration list.
  REQUIRE_NREV if
    numArgs @ 0
    ?do  i ArgList[] CalcDest  loop
  else
    numArgs @ if
      0 numArgs @ 1-
      do  i ArgList[] CalcDest  -1 +loop
    endif
  endif
; doNotSin

: initOffsets	\ --
\ Initialise the stack and frame offsets required.
  numInts off  numFloats off  /DataFrame off  /ForthFrame off
; doNotSin


\ ******************
\ +S Code generation
\ ******************

\ ========
\ +N Tools
\ ========

: [a		\ -- ; start of assembler sequence
  also asm-access  ;  immediate

: a]            \ -- ; end of assembler sequence
  previous  ;  immediate

: [a]		\ -- ; flush asm sequence
  [ also asm-core ] asm-end asm-start [ previous ]  ;	\ flush assembler


\ ==============================
\ +N Prologue, call and epilogue
\ ==============================
\ The process of making the external call is to:
\ 1) Save Forth system registers on the return (ESP) stack.
\ 2) If required save the FP state.
\ 3) Preserve the Forth TOS (normally cached in EBX) on the
\    deep stack so that the Forth stack is all in memory.
\ 4) Preserve ESP by extending the deep Forth stack.
\ 5) Adjust the return stack (ESP) to operating system requirements
\    with space allocated for the function arguments.
\    This may involve aligment to a 16 byte boundary.
\ 6) Copy the Forth and FP parameters to the ESP stack locations
\    allowing for the calling convention.
\ 7) Call the external function
\ 8) Restore ESP for "C" call convention
\ 9) Save the return data and process EBX for void returns
\ 10) Restore the NDP as required
\ 11) Restore the Forth stack
\ 12) Restore Forth registers

2 cells constant /PSPextend	\ -- u
\ The number of bytes by which the Forth stack is dropped to
\ extend it. The high cell contains the cached TOS. The bottom
\ cell (offset 0) contains the saved ESP.
\ MUST BE at least the size of a LongLong.
/PSPextend cell - constant /PSPtos	\ -- u
\ The offset from the dropped Forth stack to the cell containing
\ TOS.

: FrameDrop	\ -- n
\ The amount by which the frame is dropped before alignment
  /DataFrame @ FrameAlignment + negate  ;

: FrameMask	\ -- mask
\ The mask applied to ESP after FrameDrop has been applied.
  FrameAlignment negate  ;

: -FrameCall	\ -- -n
\ The number of bytes that allow for the call data after the
\ frame has been dropped.
  FrameBackup negate  ;

: -ReturnForth	\ n -- n-x
\ Remove the size of data returned on the Forth data stack.
  ReturnRes ai.Size @ aligned -  ;

: #PSPrestore	\ -- n
\ generate code to restore TOS for void/float returns. This is
\ the number of bytes added to restore the Forth frame.
  /ForthFrame @				\ size of Forth stack arguments
  returnRes ai.size @ if
    case  ReturnRes ai.Type @ 		\ Return type
      SINTtype of  -ReturnForth  endof
      UINTtype of  -ReturnForth  endof
      BOOLtype of  -ReturnForth  endof
    endcase
  endif
  /PSPextend +				\ frame overhead, >= largest return type
;

: ^efn		\ -- addr
\ address holding function address
  LastImport >funcaddr  ;

[defined] Target_386_Windows [if]
#108 constant /fsave	\ -- u
\ space required to save the NDP state
/fsave negate constant -/fsave	\ -- u

also Forth definitions
(( \ moved to STARTUP.FTH ; SFP009
defer preExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls without floating point parameters or return
\ ** items. It is executed at the start of the external
\ ** call before any parameter processing.
  assign noop to-do preExtCall
defer postExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls without floating point parameters or return
\ ** items. It is executed at the end of the external
\ ** call after return data processing.
  assign noop to-do postExtCall
))
\ SFP006...
defer preFPExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls with floating point parameters or return
\ ** items. . It is executed at the start of the external
\ ** call before any parameter processing.
  assign noop to-do preFPExtCall
defer postFPExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls with floating point parameters or return
\ ** items. It is executed at the end of the external
\ ** call after return data processing.
  assign noop to-do postFPExtCall
\ ...SFP006
previous definitions
[then]

: prologue,	\ --
\ Lay the call entry prologue
[defined] Target_386_Windows [if]
  usesFloats @ if			\ SFP006
    [a  call  [] ['] preFPExtCall 5 +  a] [a]	\ pre call hook
  else
    [a  call  [] ['] preExtCall 5 +  a] [a]	\ pre call hook
  endif
[then]
  [a
\ save Forth registers ; MPE005
    push  esi				\ Win: required
    push  edi
\ preserve ESP and TOS
    lea   ebp, /PSPextend ( 8 ) negate [ebp]	\ save EBX and ESP
    mov   0 [ebp], esp			\ after call, ESP will be restored
    mov   /PSPtos ( 4 ) [ebp], ebx	\ save TOS, easier from memory if double
  a] [a]
  FrameAlignment if
    \ make a frame on ESP and align it to OS convention, 16 byte aligned less 4 bytes
    [a
      lea   eax, FrameDrop [esp]	\ compile time constant
      and   eax, # FrameMask		\ 16 byte align
      lea   esp, FrameBackup [eax]	\ allow for size of call
    a] [a]
  else
    FrameDrop if
    [a
      lea   esp, FrameDrop [esp]	\ compile time constant
    a] [a]
    endif
  endif
; doNotSin

: generateCall	\ --
\ Lay the code to call the external function, and clean up.
  [a
\ Call external C/PASCAL proc
    cld
    call  ^efn []			\ indirect through pointer
    cld
  a] [a]
  CalleeCleaned? 0= if			\ C style call
    [a  mov   esp, 0 [ebp]  a] [a]	\ prologue saved ESP, used for C.
  endif
; doNotSin

: epilogue,	\ --
\ Restore the Forth and O/S stacks.
\ Forth data stack restoration
  #PSPrestore ?dup if
    >r  [a lea   ebp, r> [ebp] a] [a]	\ adjust Forth PSP stack: 0-4+8=4
  endif
\ restore Forth registers
  [a
    pop   edi
    pop   esi
  a] [a]
\ restore NDP stack
[defined] Target_386_Windows [if]
  usesFloats @ if			\ SFP006
    [a  call  [] ['] postFPExtCall 5 +  a] [a]	\ post call hook
  else
    [a  call  [] ['] postExtCall 5 +  a] [a]	\ post call hook
  endif
[then]
; doNotSin


\ ============================
\ +N Copy Forth stack to frame
\ ============================

: CopyS8	\ srcoff destoff --
\ Copy a signed 8 bit item from srcoff [EBP] to destoff [ESP]
  >r >r					\ R: -- destoff srcoff
  [a  movsx  EAX, BYTE a] r> [a [EBP] a] [a]
  [a  mov  a]  r> [a [ESP], EAX a] [a]
;

: CopyS16	\ srcoff destoff --
\ Copy a signed 16 bit item from srcoff [EBP] to destoff [ESP]
  >r >r					\ R: -- destoff srcoff
  [a  movsx  EAX, WORD a] r> [a [EBP] a] [a]
  [a  mov  a]  r> [a [ESP], EAX a] [a]
;

: CopyU8	\ srcoff destoff --
\ Copy an unsigned 8 bit item from srcoff [EBP] to destoff [ESP]
  >r >r					\ R: -- destoff srcoff
  [a  movzx  EAX, BYTE a] r> [a [EBP] a] [a]
  [a  mov  a]  r> [a [ESP], EAX a] [a]
;

: CopyU16	\ srcoff destoff --
\ Copy an unsigned 16 bit item from srcoff [EBP] to destoff [ESP]
  >r >r					\ R: -- destoff srcoff
  [a  movzx  EAX, WORD a] r> [a [EBP] a] [a]
  [a  mov  a]  r> [a [ESP], EAX a] [a]
;

: CopyX32	\ srcoff destoff --
\ Copy a cell from srcoff [EBP] to destoff [ESP]
  >r >r					\ R: -- destoff srcoff
  [a  mov   EAX, a] r> [a [EBP] a] [a]
  [a  mov  a]  r> [a [ESP], EAX a] [a]
;

: CopyX64-F	\ srcoff destoff --
\ Copy a 64 bit double integer in Forth format from srcoff [EBP]
\ to destoff [ESP]
  2dup 4 + CopyX32  swap 4 + swap CopyX32
;

: CopyX64-C	\ srcoff destoff --
\ Copy a 64 bit double integer in C format from srcoff [EBP]
\ to destoff [ESP]
  2dup CopyX32  swap 4 + swap 4 + CopyX32
;

: offsets	\ ^ai -- srcoff destoff
\ Extract the base offsets from the structure. The source offset
\ is assumed to be on the PSP/EBP stack and is adjusted to be based
\ from the saved TOS.
  dup ai.PSPoff @ /PSPtos +  swap ai.FrameOff @
;

: CopySINT	\ ^ai --
\ Compile code to copy TOS to the frame as an signed INT32/64.
\ with any required promotion.
  case  dup ai.size @
    1 of  offsets CopyS8  endof
    2 of  offsets CopyS16  endof
    4 of  offsets CopyX32  endof
    8 of  offsets CopyX64-F  endof
     err_CGsize throw
  endcase
;

: CopyUINT	\ ^ai --
\ Compile code to copy TOS to the frame as a UINT32/64.
\ with any required promotion.
  case  dup ai.size @
    1 of  offsets CopyU8  endof
    2 of  offsets CopyU16  endof
    4 of  offsets CopyX32  endof
    8 of  offsets CopyX64-F  endof
     err_CGsize throw
  endcase
;

: CopyBOOL	\ ^ai --
\ Compile code to copy TOS to the frame as a BOOL.
\ with any required promotion/demotion.
  offsets CopyU8
;

: CopyFLOAT	\ ^ai --
\ Compile code to copy FTOS to the frame as a float or double
  [ FPSystem 1 = [if]   \ external float stack
    ] [a    \ pop float from external float stack into the FPU
      mov   eax, FSP-OFFSET [esi]   \ get FP stack pointer
      fld   fword 0 [eax]           \ push FNOS to FPU
      lea   eax, FPCELL [eax]	      \ update stack pointer
      mov   FSP-OFFSET [esi], eax
    a] [a] [            
  [then] ]
  case  dup ai.size @
    4 of  >r  [a fstp float a]      r> ai.FrameOff @ [a [esp] a] [a]  endof
    8 of  >r  [a fstp double a]     r> ai.FrameOff @ [a [esp] a] [a]  endof
    10 of >r  [a fstp extended a]   r> ai.FrameOff @ [a [esp] a] [a]  endof
       err_CGsize throw
  endcase
;

: CopyArg	\ ^ai --
\ Compile code to copy an item from Forth to the calling frame
\ with any required promotion.
  case  dup ai.type @
    UINTtype of  CopyUINT  endof
    SINTtype of  CopySINT  endof
    BOOLtype of  CopyBOOL  endof
    FLOATtype of  CopyFloat  endof
      err_ImpType throw
  endcase
;

: CopyFrame	\ --
\ Copy the arguments from the Forth stack to the O/S stack with
\ any required promotion/demotion.
  L>R? REQUIRE_NREV xor 0= if
    numArgs @ if
      0 numArgs @ 1-
      do  i ArgList[] CopyArg  -1 +loop
    endif
  else
    numArgs @ 0
    ?do  i ArgList[] CopyArg  loop
  endif
;


\ ================
\ +N Return result
\ ================

: restoreTOS	\ --
\ For void and float return values, TOS must be restored.
  [a  mov  ebx,  a]  /PSPtos /ForthFrame @ +  [a [EBP] a] [a]
;

: retLongLongF	\ --
\ Return a long long in Forth format.
  [a
    mov  ebx, edx			\ most significant  -> TOS
    mov  #PSPrestore [ebp], eax		\ least significant -> NOS
  a] [a]
;

: ReturnSINT	\ --
\ Return a signed int.
  case  ReturnRes ai.size @
    1 of  [a  movsx  ebx, al  a] [a]  endof
    2 of  [a  movsx  ebx, ax  a] [a]  endof
    4 of  [a  mov  ebx, eax  a] [a]  endof
    8 of  retLongLongF  endof
        err_RetSize throw
  endcase
;

: ReturnUINT	\ --
\ Return an unsigned int.
  case  ReturnRes ai.size @
    1 of  [a  movzx  ebx, al  a] [a]  endof
    2 of  [a  movzx  ebx, ax  a] [a]  endof
    4 of  [a  mov  ebx, eax  a] [a]  endof
    8 of  retLongLongF  endof
        err_RetSize throw
  endcase
;

: ReturnBOOL	\ --
\ Return a BOOL as a single byte.
  [a  movzx  ebx, al  a] [a]  ;

: returnFLOAT	\ -- ; return float/double
\ With the float in ST0, it's already where we want it.
\ For a float return, we must still restore EBX correctly.
  RestoreTOS  ;

: returnData	\ -- ; process return value
\ Do any necessary demotion, or lose return result for VOID.
\ This happens before the epilogue code so that the saved frame
\ is available.
  returnRes ai.size @ if	\ non-void
    case  ReturnRes ai.Type @ 		\ Return type
      SINTtype of  ReturnSINT  endof
      UINTtype of  ReturnUINT  endof
      BOOLtype of  ReturnBOOL  endof
      FLOATtype of  returnFLOAT  endof
        err_RetType throw
    endcase
  else				\ void
    RestoreTOS
  endif
; doNotSin


\ ====================
\ +N Import generation
\ ====================

: comp-extern	\ xt --
\ Compile a child of EXTERN:.
  doCall,  discard-sinline
;

: set-comp-extern	\ xt --
\ Set COMP-EXTERN as the compiler of the given XT.
  >code-len  ['] comp-extern over !  cell+ off
; doNotSin

variable FirstLine#	\ -- addr ; SFP022
\ Holds line number of the first line

: setFirstLine	\ --
  line# @ FirstLine# !
;

: MakeColon	\ -- xt ; SFP022
  line# @ >r  FirstLine# @ line# !	\ use first line number for header
  ExternName count (:)			\ make header and start definition
  r> line# !
  last-colon-xt @			\ return xt we have just made
; doNotSin

: MakeNormal	\ --
\ Make the word that calls a normal imported function.
  MakeColon >r				\ save xt we have just made ; SFP022
  prologue,
  copyFrame generateCall returnData
  epilogue,
  postpone ;				\ finish definition
  r> set-comp-extern			\ set its compiler.
; doNotSin

: MakeVarCall	\ --
\ Make the word that calls a varargs imported function.
  MakeColon >r				\ save xt we have just made ; SFP022
  l>r? if
    ^efn postpone literal  postpone @	\ x1..xn n funcaddr --
    postpone varXcall			\ varXcall ; C style param order
  else
    ^efn postpone literal  postpone @	\ x1..xn n funcaddr --
    postpone swap  postpone nxcall	\ swap nxcall ; PASCAL style param order
  endif
  ReturnRes ai.size @ 0=
  if  postpone drop  endif
  postpone ;				\ finish definition
  r> set-comp-extern			\ set its compiler.
; doNotSin

: MakeImport	\ --
\ Make the word that calls the imported function.
  varargs?
  if  MakeVarCall  else  MakeNormal  endif
; doNotSin

: MakeImpVar	\ -- ; SFP017
\ Make the word that returns a variable's address
  ExternName count (:)			\ make header and start definition
  ^efn postpone literal  postpone @	\ variable address
  postpone ;				\ finish definition
; doNotSin

: ?warnExtRedef	\ -- ; SFP017
\ Warn if redefinitions are to be reported.
  ExternWarnings? if
    cr ." WARNING: Redefinition of Extern: " ExternName $.
  then
; doNotSin

: importEntry,	\ -- ; SFP017
\ lay the import list entry
  align
  here -> LastImport			\ save structure address
  import-func-link link,		\ link to import chain
  0 ,					\ holds the function address
  importName $>z,			\ import name counted + 0 terminated
; doNotSin

: GenerateImport        \ --
\ The following structure is built and must match /funcstr:
\ cell	link to previous import in library
\ cell	holds address of function to XCALL
\ z$	0-terminated ImportName of function (case sensitive)
\ cell	pointer to second cell, for a future inline code generator)
\ colon definition
\ cr ." GenerateImport 1 " key? drop
\ Don't do anything if this function already exists and import
\ redefinitions are to be ignored.
  ExternName count Externals.wid search-wordlist if
    drop  ?warnExtRedef  ExternRedefs? 0= if	\ SFP017
      ExternWarnings?
      if  ."  ignored"  then
      exit
    then
  then
\ ." 2 " key? drop
  importEntry,				\ Build import list entry ; SFP017

\ Calculate the stack and frame offsets
\ ." 3 " key? drop
  varargs? 0=
  if  initOffsets CalcForthOff CalcFrameOff  endif

\ Build the colon definition that interprets the function
\ ." 4 " key? drop
  align  ^efn ,			\ points to function address cell of import structure
  InExternals? if
    get-current  Externals.wid set-current
    MakeImport
    set-current
  else
    MakeImport
  endif
\ ." 5 " key? drop
  LastImport resolveImport		\ Resolve the import we have just made
\ ." 6 " key? drop
;
+short-branches
\ ...SFP004

: genExternVar	\ -- ; SFP017
\ Generate an external variable
  ExternName count Externals.wid search-wordlist if
    drop  ?warnExtRedef  ExternRedefs? 0=
    if  exit  then
  then
  importEntry,				\ Build import list entry
\ Build the colon definition that interprets the function
  align  ^efn ,				\ points to function address cell of import structure
  InExternals? if
    get-current  Externals.wid set-current
    MakeImpVar
    set-current
  else
    MakeImpVar
  endif
  LastImport resolveImport		\ Resolve the import we have just made
;


\ =================
\ Argument handling
\ =================

0 value argSIZE		\ in bytes
0 value argTYPE		\ 0 = integer or bool
0 value argDEFSIGN	\ 0 = unsigned, 1 = signed, for ints < 4 bytes
-1 value argREQSIGN	\ 0 = unsigned, 1 = signed, -1 no request made
0 value argISPOINTER	\ 0 = no, 1 = this is a pointer

: next-item	\ c-addr u char -- 'c-addr 'u c-addr1 u1
\ Return the remaining string and the leftmost item delimited by
\ char. Both strings have leading and trailing spaces removed.
  >r 2dup r> scan			\ ca1 u1 ca2 u2 --
  2swap swap >r				\ ca2 u2 u1 -- ; R: ca1 --
  over - >r				\ ca2 u1 -- ; R: ca1 u1 --
  1 /string -white  2r> -white
; doNotSin

: checkPtr	\ caddr len -- caddr' len' ; SFP013 SFP023
\ The string is a name (no spaces). Check if either or both the
\ leading and trailing characters are '*', and if so mark the
\ argument as a pointer.
  begin
    dup 1 > while			\ -- caddr len
    over c@ [char] * = while
      1 to argISPOINTER  1 /string
  repeat then
  begin
    dup 1 > while
    2dup + 1- c@ [char] * = while	\ check trailing '*'
      1 to argISPOINTER  1-
  repeat then
; doNotSin
((
: checkPtr	\ caddr len -- caddr' len' ; SFP013
\ The string is a name (no spaces). Check if either or both the
\ leading and trailing characters are '*', and if so mark the
\ argument as a pointer.
  dup 1 > if
    over c@ [char] * = if		\ check leading '*'
      1 to argISPOINTER  1 /string
    endif
  endif
  dup 1 > if
    2dup + 1- c@ [char] * = if		\ check trailing '*'
      1 to argISPOINTER  1-
    endif
  endif
;
))

-short-branches
: parse-arg     \ c-addr u --
   4 to argSIZE
   0 to argTYPE				\ default to int
   0 to argDEFSIGN
  -1 to argREQSIGN
   0 to argISPOINTER

  begin
    -leading dup 0>
  while
    \ c-addr u --
    bl next-item checkPtr		\ SFP013
    ['] types voc>wid search-wordlist
    \ -- c-addr-rem u-rem xt flag | c-addr-rem u-rem 0
    dup 0=
    if  ['] noop swap  then		\ Use NOOP if not found
    \ -- c-addr-rem u-rem xt flag
    0= 2 pick 0> and err_impType ?throw	\ bail if token not found and wasn't last!
    execute
  repeat
  2drop

  argREQSIGN -1 =			\ if no sign set,
  if  argDEFSIGN to argREQSIGN  then	\  use default
  argISPOINTER if                       \ if pointer then override to use
    0 to argTYPE			\ treat as int
    0 to argREQSIGN                     \ unsigned cell as data type
    4 to argSIZE			\ use CELL instead?
  then
  argTYPE FLOATtype =			\ SFP006
  if  usesFloats on  endif
; doNotSin
+short-branches

: delimiter?    \ char -- flag
\ Return true if the character is a type delimiter
  dup [char] * =			\ pointer
  if  drop  true exit  then
  dup bl =				\ space
  if  drop  true exit  then
  dup 9 =				\ tab ; SFP017
  if  drop  true exit  then
  drop false
;

: splitRet&Name	\ -- c-addr u' c-addr1 u1
\ Get the return type and function name from the input stream.
\   DWORD Pascal  GetLastError( void );
\ ----------------------------^
\ Split the string at the last delimiter, so that caddr/u'
\ contains the return type info and caddr1/u1 contains the
\ function name.
\ ---------------^
\ parse the return type and function name
  [char] ( word count -trailing		\ -- c-addr u ; return type, call conv, name )
\ 2dup type cr key? drop
\ find last delimiter
  2dup + 1 -			\ -- c-addr u ^last
  begin
    dup c@ delimiter? 0=
  while
    1-
  repeat
  1+			\ -- c-addr u c-addr1
\ calculate strings
  dup 3 pick -          \ -- c-addr u c-addr1 u'
  swap rot		\ -- c-addr u' c-addr1 u
  2 pick -		\ -- c-addr u' c-addr1 u-u'
; doNotSin

: setArgData	\ ^ai --
  argSIZE over ai.size !
  argTYPE 0= if				\ default is int/bool
    argREQSIGN
    if  SINTtype  else  UINTtype  endif
    swap ai.type !
  else
    argTYPE swap ai.type !
  endif
; doNotSin

: ?refill	\ --
\ Perform REFILL and throw on error.
  refill 0= #-411 ?throw  ;

: parse*/	\ caddr len -- caddr' len --
\ Parse out a C comment of the form "/* ... */", returning the
\ following string. May parse multiple lines.
  begin
    s" */" search 0=			\ look for terminating "*/"
   while
    2drop  ?refill source
  repeat
  2 /string -white			\ step over "/", strip white space
;

: toEOL		\ --
  #tib @ >in !  ;

: stripLeadingComment	\ caddr len -- caddr' len'
\ Remove leading C style comments from the string. The first
\ character is not white space.
  dup 2 <
  if  exit  endif
  over s" //" s=			\ if string starts with //
  if  toEOL  drop 0  exit  endif	\ set length to zero
  over s" /*" s=			\ if string starts with /*
  if  parse*/  toEOL  endif
;

: stripTrailingComment	\ caddr len -- caddr' len'
\ Remove trailing C style comments from the string. Any leading
\ comment has already been removed. All trailing comments are
\ assumed to extend to the end of the line.
  dup 2 <
  if  exit  endif
  2dup s" //" search
  if  nip - -white  toEOL  exit  endif
  2drop  2dup s" /*" search
  if  nip - -white  toEOL  exit  endif
  2drop
;

-short-branches
: ExtractArgs	\ caddr u --
\ The input string is the return type information. Then parse the
\ rest of the line after the leading '(' character.

  -white parse-arg			\ parse the return type
  ReturnRes setArgData

  0 numArgs !
  begin
    [char] ) parse		        \ -- caddr len
    'tib @ >in @ 1- 0 max + c@ >r	\ terminator
    begin
      -leading dup 0>
    while				\ c-addr u --
      stripLeadingComment dup 0>
    while
      [char] , next-item
      stripTrailingComment dup if
        parse-arg				\ next argument to trailing , or )
        numArgs @ ArgList[] setArgData	\ save data in argument array
        1 numArgs +!
      else
        2drop
      endif
    repeat then
    2drop
    r> [char] ) <>
   while
    ?refill
  repeat
  numArgs @ 1 = if			\ special case, #args=1 and argsize=0 ; SFP007
    arglist @ 0= if			\ indicates void list
      numArgs off
    endif
  endif
  0 word drop				\ discard rest of line
; doNotSin
+short-branches

variable <ShowExtData>

: ?ShowExtData	\ --
  <ShowExtData> @ if
    cr cr ExternName count type .ArgList
  endif
; doNotSin

: isSingleName	\ caddr len -- ; SFP020
\ Set as name of Forth word and DLL function.
  2dup importName place			\ set name of DLL function
  ExternName place			\ set name of Forth word
; doNotSin

: SingleName	\ "name" -- ; SFP020
\ G Get a name as the name of the Forth word and the DLL function.
  parse-name isSingleName
;


\ =============
\ +N Public API
\ =============

(( for DocGen
: InExternals	\ --
\ *G External imports are created in the *\fo{EXTERNALS} vocabulary.
: InCurrent	\ --
\ *G External imports are created in the wordlist specified by
\ ** *\fo{CURRENT}.
))
also forth definitions

: Extern:	\ "text" --
\ *G Declare an external API reference. See the syntax above.
\ ** The Forth word has the same name as the function in the
\ ** library, but the Forth word name is *\b{not} case-sensitive.
\ ** The length of the function's name may not be longer than a
\ ** Forth word name. For example:
\ *C   Extern: DWORD Pascal GetLastError( void );
  setFirstLine				\ SFP022
  splitRet&Name
  isSingleName     			\ -- c-addr u ; leaves return type info
  usesFloats off  setDefExt		\ set default declaraction type ; SFP006
  ExtractArgs  GenerateImport
  ?ShowExtData
;

: AliasedExtern:	\ "forthname" "text" --
\ *G Like *\fo{EXTERN:} but the declared external API reference
\ ** is called by the explicitly specified *\fo{forthname}.
\ ** The Forth word name follows and then the API name.
\ ** Used to avoid name conflicts, e.g.
\ *C AliasedExtern: saccept int accept( HANDLE, void *, unsigned int *);
\ *P which references the Winsock *\fo{accept} function but gives
\ ** it the Forth name *\fo{SACCEPT}. Note that here we use the
\ ** fact that formal parameter names are optional.
  setFirstLine				\ SFP022
  parse-name ExternName place		\ process Forth name
  splitRet&Name importName place	\ -- c-addr' u'
  usesFloats off  setDefExt		\ set default declaration type ; SFP006
  ExtractArgs GenerateImport
  ?ShowExtData
;

: LocalExtern:	\ "forthname" "text" --
\ *G As *\fo{AliasedExtern:}, but the import is always built into
\ ** the *\fo{CURRENT} wordlist.
  InExternals?   0 -> InExternals?
  AliasedExtern:
  to InExternals?
;

: extern	\ "text" --
\ *G An alias for *\fo{EXTERN:}.
  extern:  ;

\ SFP017...
: ExternVar	\ "<name>" -- ; ExternVar <name>
\ *G Used in the form
\ *C   ExternVar <name>
\ *P to find a variable in a DLL or shared library. When executed,
\ ** *\fo{<name>} returns its address.
  SingleName  genExternVar		\ generate variable ; SFP020
;

: AliasedExternVar	\ "<forthname>" "<dllname>" --
\ *G Used in the form
\ *C   AliasedExternnVar <forthname> <varname>
\ *P to find a variable in a DLL or shared library. When executed,
\ ** *\fo{<forthname>} returns its address.
  parse-name ExternName place		\ process Forth name
  parse-name importName place		\ variable name
  genExternVar				\ generate variable
;
\ ...SFP017

: +DebugExterns	\ --
  <ShowExtData> on  ;
: -DebugExterns	\ --
  <ShowExtData> off  ;

: .Externs	\ -- ; display EXTERNs
\ *G Display a list of the external API calls.
  0 import-func-link
  begin
    @ dup halt? 0= and
   while				\ -- count item
    cr  dup >funcname .z$
    out @ #31 and #32 swap - spaces
    dup >funcaddr @ .lword
    swap 1+ swap
  repeat
  drop
  cr . ." Externs"
;

: #BadExterns	\ -- u
\ *G Silently return the number of unresolved external API calls.
  0 import-func-link
  begin
    @ dup
   while				\ -- count item
    dup >funcaddr @ 0= if
      swap 1+ swap
    endif
  repeat
  drop
;

: .BadExterns	\ --
\ *G Display a list of any external API calls that have not been
\ ** resolved.
  0 import-func-link
  begin
    @ dup halt? 0= and
   while				\ -- count item
    dup >funcaddr @ 0= if
      cr  dup >funcname .z$
      swap 1+ swap
    endif
  repeat
  drop
  cr . ." Unresolved Externs"
;

: func-pointer	\ xt -- addr
\ *G Given the XT of a word defined by *\fo{EXTERN:} or friends,
\ ** returns the address that contains the run-time address.
  >link cell - @
;

: func-loaded?	\ xt -- addr|0
\ *G Given the XT of a word defined by *\fo{EXTERN:} or friends,
\ ** returns the address of the DLL function in the DLL,
\ ** or 0 if the function has not been loaded/imported yet.
  >link cell - @ @
;

defer func-not-loaded	\ c-addr u --
\ Client special
  assign 2drop to-do func-not-loaded

: all-func-loaded?	\ -- flag
\ Client special
  true >R
  import-func-link @
  begin
    dup
  while
    dup >funcaddr @ 0= if
      dup >funcname zcount func-not-loaded
      r> drop false >r
    then
    @
  repeat
  drop r>
;

previous definitions


\ ******************************
\ *S Pre-Defined parameter types
\ ******************************
\ *P The types known by the system are all found in the vocabulary
\ ** *\fo{TYPES}. You can add new ones at will. Each *\fo{TYPE}
\ ** definition modifies one or more of the following *\fo{VALUE}s.                        )
\ *D argSIZE      Size in bytes of data type.
\ *D argDEFSIGN   Default sign of data type if no override is supplied.
\ *D argREQSIGN   Sign OverRide. This and the previous use 0 = unsigned
\ **              and 1 = signed.
\ *D argISPOINTER 1 if type is a pointer, 0 otherwise

\ *P Each *\fo{TYPES} definition can either set these flags
\ ** directly or can be made up of existing types.

\ *P Note that you should explicitly specify a calling convention
\ ** for every function defined.


\ ======================
\ *N Calling conventions
\ ======================

also types definitions

: "C"           \ --
\ *G Set Calling convention to "C" standard. Arguments are
\ ** reversed, and the caller cleans up the stack.
  0 to CalleeCleaned?  TRUE to Require_NRev
;

: "PASCAL"      \ --
\ *G Set the calling convention to the "PASCAL" standard as used
\ ** by Pascal compilers. Arguments are *\b{not} reversed, and the
\ ** called routine cleans up the stack.
\ ** This is *\b{not} the same as *\fo{PASCAL} below.
  1 to CalleeCleaned?  FALSE to Require_NRev
;

: PASCAL        \ --
\ *G Set the calling convention to the Windows PASCAL standard.
\ ** Arguments are reversed in C style, but the called routine
\ ** cleans up the stack. This is the standard Win32 API calling
\ ** convention. N.B. There are exceptions!
\ ** This convention is also called "stdcall" and "winapi" by
\ ** Microsoft, and is commonly used by Fortran programs.
\ ** This is *\b{not} the same as *\fo{"PASCAL"} above.
  1 to CalleeCleaned?  TRUE to Require_NRev
;

: WinApi	\ --
\ *G A synonym for *\fo{PASCAL}.
  PASCAL
;

: StdCall	\ --
\ *G A synonym for *\fo{PASCAL}.
  PASCAL
;

: VC++		\ --
\ *G Defines the calling convention as being for a C++ member
\ ** function which requires "this" in the ECX register.
\ ** The function must be defined with an explicit this
\ ** pointer (void * this). Because exported VC++ member
\ ** functions can have either "C" or "PASCAL" styles, the this
\ ** pointer must be positioned so that it is leftmost when
\ ** reversed (C/WINAPI/StdCall style) or is rightmost when
\ ** not reversed ("PASCAL" style). See also the later section
\ ** on interfacing to C++ DLLs.
  1 to ObjPtr?
;

: R>L	\ --
\ *G By default, arguments are assumed to be on the Forth stack
\ ** with the top item matching the rightmost argument in the
\ ** declaration so that the Forth parameter order matches that
\ ** in the C-style declaration.
\ ** *\fo{R>L} reverses this.
  FALSE to L>R?
;

: L>R	\ --
\ *G By default, arguments are assumed to be on the Forth stack
\ ** with the top item matching the rightmost argument in the
\ ** declaration so that the Forth parameter order matches that
\ ** in the C-style declaration.
\ ** *\fo{L>R} confirms this.
  TRUE to L>R?
;

previous definitions


\ ==============
\ *N Basic Types
\ ==============

also types definitions

: unsigned      \ --
\ *G Request current parameter as being unsigned.
  0 to argREQSIGN  ;

: signed        \ --
\ *G Request current parameter as being signed.
  1 to argREQSIGN  ;

: int           \ --
\ *G Declare parameter as integer. This is a signed 32 bit quantity
\ ** unless preceeded by *\fo{unsigned}.
  4 to argSIZE  1 to argDEFSIGN  ;

: char          \ --
\ *G Declare parameter as character. This is a signed 8 bit quantity
\ ** unless preceeded by *\fo{unsigned}.
  1 to argSIZE  1 to argDEFSIGN  ;

: void          \ --
\ *G Declare parameter as void. A *\fo{VOID} parameter has no
\ ** size. It is used to declare an empty parameter list, a null
\ ** return type or is combined with *\fo{*} to indicate a generic
\ ** pointer.
  0 to argSIZE  0 to argDEFSIGN  ;

: *		\ --
\ *G Mark current parameter as a pointer.
  1 to argISPOINTER  ;
: **		\ --
\ *G Mark current parameter as a pointer.
  1 to argISPOINTER  ;
: ***		\ --
\ *G Mark current parameter as a pointer.
  1 to argISPOINTER  ;

: const ;	\ --
\ *G Marks next item as *\b{constant} in C terminology. Ignored
\ ** by VFX Forth.

: int32		\ --
\ *G A 32bit signed quantity.
  4 to argSIZE  1 to argDEFSIGN  ;

: int16		\ --
\ *G A 16 bit signed quantity.
   2 to argSIZE  1 to argDEFSIGN  ;

: int8		\ --
\ *G An 8 bit signed quantity.
   1 to argSIZE  1 to argDEFSIGN  ;

: uint32	\ --
\ *G 32bit unsigned quantity.
  unsigned int  ;

: uint16	\ --
\ *G 16bit unsigned quantity.
  unsigned int  2 to argSIZE  ;

: uint8		\ --
\ *G 8bit unsigned quantity.
  1 to argSIZE  0 to argDEFSIGN  ;

: LongLong	\ --
\ *G A 64 bit signed or unsigned integer. At run-time, the argument
\ ** is taken from the Forth data stack as a normal Forth double
\ ** with the top item on the top of the data stack.
  8 to argSIZE  1 to argDEFSIGN  ;

: LONG          int  ;
\ *G A 32 bit signed quantity.

: SHORT		\ --
\ *G For most compilers a *\b{short} is a 16 bit signed item,
\ ** unless preceded by *\fo{unsigned}.
  2 to argSIZE  1 to argDEFSIGN  ;

: BYTE		\ --
\ *G An 8 bit unsigned quantity.
  1 to argSIZE  0 to argDEFSIGN  ;

: float		\ --
\ *G 32 bit float.
  4 to argSIZE  0 to argDEFSIGN  FLOATtype to argTYPE  ;

: double	\ --
\ *G 64 bit float.
  8 to argSIZE  0 to argDEFSIGN  FLOATtype to argTYPE  ;

: bool1		\ --
\ *G One byte boolean.
  1 to argSIZE  0 to argDEFSIGN  BOOLtype to argTYPE  ;
: bool4		\ --
\ *G Four byte boolean.
  int  ;

: ...		\ --
\ *G The parameter list is of unknown size. This is an indicator
\ ** for a C varargs call. Run-time support for this varies between
\ ** operating system implementations of VFX Forth. Test, test,
\ ** test.
  1 to varargs?
;

previous definitions


\ ================
\ *N Windows Types
\ ================
\ *P The following parameter types are non "C" standard and are used by
\ ** Windows in function declarations. They are all defined in terms
\ ** of existing types.

[defined] Target_386_Windows [IF]

: (setDefExt)	\ --
\ set up the defaults for EXTERN: calls.
  0 to FrameAlignment  0 to FrameBackup  0 to AlignInFrame?
  TRUE to REQUIRE_NREV  1 to CalleeCleaned?
  TRUE to L>R?
  0 to ObjPtr?  0 to StructRet?  0 to varargs?
;
assign (setDefExt) to-do setDefExt

also types definitions

: OSCALL	PASCAL  ;
\ *G Used for portable code to avoid three sets of declarations.
\ ** For Windows, this is a synonym for *\fo{PASCAL} and under
\ ** Linux and other Unices this is a synonym for *\fo{"C"}.
: DWORD         unsigned int  ;
\ *G 32 bit unsigned quantity.
: WORD          unsigned int  2 to argSIZE  ;
\ *G 16 bit unsigned quantity.
: HANDLE        void *  ;
\ *G HANDLEs under Windows are effectively pointers.
: HMENU         handle  ;
\ *G A Menu HANDLE.
: HDWP          handle  ;
\ *G A DEFERWINDOWPOS structure Handle.
: HWND          handle  ;
\ *G A Window Handle.
: HDC           handle  ;
\ *G A Device Context Handle.
: HPEN          handle  ;
\ *G A Pen Handle.
: HINSTANCE     handle  ;
\ *G An Instance Handle.
: HBITMAP       handle  ;
\ *G A Bitmap Handle.
: HACCEL        handle  ;
\ *G An Accelerator Table Handle.
: HBRUSH        handle  ;
\ *G A Brush Handle.
: HMODULE       handle  ;
\ *G A module handle.
: HENHMETAFILE  handle  ;
\ *G A Meta File Handle.
: HFONT         handle  ;
\ *G A Font Handle.
: HRESULT       DWORD   ;
\ *G A 32bit Error/Warning code as returned by various COM/OLE calls.
: LPPOINT       void *  ;
\ *G Pointer to a POINT structure.
: LPACCEL       void *  ;
\ *G Pointer to an ACCEL structure.
: LPPAINTSTRUCT void *  ;
\ *G Pointer to a PAINTSTRUCT structure.
: LPSTR         void *  ;
\ *G Pointer to a zero terminated string buffer which may be modified.
: LPCTSTR       void *  ;
\ *G Pointer to a zero terminated string constant.
: LPCSTR        void *  ;
\ *G Another string pointer.
: LPTSTR        void *  ;
\ *G Another string pointer.
: LPDWORD       void *  ;
\ *G Pointer to a 32 bit DWORD.
: LPRECT        void *  ;
\ *G Pointer to a RECT structure.
: LPWNDPROC     void *  ;
\ *G Pointer to a WindowProc function.
: PLONG         long *  ;
\ *G Pointer to a long (signed 32 bit).
: ATOM          word  ;
\ *G An identifier used to represent an atomic string in the OS table.
\ ** See *\b{RegisterClass()} in the Windows API for details.
: WPARAM        dword  ;
\ *G A parameter type which used to be 16 bit but under Win32 is an
\ ** alias for DWORD.
: LPARAM        dword  ;
\ *G Used to mean LONG-PARAMETER (i.e. 32 bits, not 16 as under Win311)
\ ** and is now effectively a DWORD.
: UINT          dword  ;
\ *G Windows type for unsigned INT.
: BOOL          int  ;
\ *G Windows Boolean type. 0 is false and non-zero is true.
: LRESULT       int  ;
\ *G Long-Result, under Win32 this is basically an integer.
: colorref      DWORD  ;
\ *G A packed encoding of a color made up of 8 bits RED, 8 bits GREEN,
\ ** 8 bits BLUE and 8 bits ALPHA.
: SOCKET	dword  ;
\ *G Winsock socket reference.
\ JD_024...
: CURRENCYFMT   void * ;
\ *G Contains information that defines the format of a currency string.
: ENUMRESNAMEPROC void * ;
\ *G An application-defined callback function used with the EnumResourceNames
\ ** and EnumResourceNamesEx functions.
: FILETIME      void * ;
\ *G Contains a 64-bit value representing the number of 100-nanosecond intervals
\ ** since January 1, 1601 (UTC).
: HGLOBAL       void * ;
\ *G A handle to the global memory object.
: HRSRC         void * ;
\ *G A handle to a resource.
: LANGID        void * ;
\ *G A language identifier.
: LCID          void * ;
\ *G A locale identifier.
: LCTYPE        void * ;
\ *G A locale information type.
: LOCALE_ENUMPROC void * ;
: LONG_PTR      void * ;
\ *G A signed long type for pointer precision. Use when casting a pointer to a
\ ** long to perform pointer arithmetic.
: LP            void * ;
\ *G A long pointer.
: LPBOOL        void * ;
\ *G A pointer to a BOOL.
: LPCWSTR       void * ;
\ *G A pointer to a constant null-terminated string of 16-bit Unicode characters.
: LPFILETIME    void * ;
\ *G A pointer to a FILETIME structure.
: LPMEMORYSTATUS  void * ;
\ *G A pointer to a MEMORYSTATUS structure.
: LPMODULEENTRY32 void * ;
\ *G A pointer to a MODULEENTRY32 structure.
: LPOSVERSIONINFO void * ;
\ *G A pointer to a OSVERSIONINFO structure.
: LPOVERLAPPED  void * ;
\ *G A pointer to a OVERLAPPED structure.
: LPWSTR        void * ;
\ *G A pointer to a null-terminated string of 16-bit Unicode characters.
: LPVOID        void * ;
\ *G A pointer to any type.
: LPCVOID       void * ;
\ *G A pointer to a constant of any type.
: MSG           void * ;
\ *G Contains message information from a thread's message queue.
: NORM_FORM     void * ;
\ *G Specifies the supported normalization forms.
: NUMBERFMT     void * ;
\ *G Contains information that defines the format of a number string.
: PACTCTX       void * ;
\ *G Pointer to an ACTCTX structure that contains information about the
\ ** activation context to be created.
: PBOOL         void * ;
\ *G A pointer to a BOOL.
: PDWORD        void * ;
\ *G A pointer to a DWORD.
: PHANDLE       void * ;
\ *G A pointer to a HANDLE.
: PVOID         void * ;
\ *G A pointer to any type.
: PULARGE_INTEGER void * ;
\ *G A pointer to a ULARGE_INTEGER structure.
: SIZE_T*       void * ;
: SIZE_T        Dword  ;
\ *G The maximum number of bytes to which a pointer can point. Use for a count
\ ** that must span the full range of a pointer.
: SYSTEMTIME    void * ;
\ *G Specifies a date and time, using individual members for the month, day,
\ ** year, weekday, hour, minute, second, and millisecond. The time is either
\ ** in coordinated universal time (UTC) or local time, depending on the
\ ** function that is being called.
: ULONG_PTR     void * ;
\ *G An unsigned LONG_PTR.
: VA_LIST       void * ;
\ *G A variable argument list.
: LPWIN32_FIND_DATA     void * ;
\ *G A pointer to a WIN32_FIND_DATA structure.
: LPTPMPARAMS           void * ;
\ *G A pointer to a TPMPARAMS structure.
: CODEPAGE_ENUMPROC     void * ;
\ *G An application-defined callback function that processes enumerated code page
\ ** information provided by the EnumSystemCodePages function. The
\ ** CODEPAGE_ENUMPROC type defines a pointer to this callback function.
: LPPROCESSENTRY32      void * ;
\ *G A pointer to a PROCESSENTRY32 structure.
: LPPROGRESS_ROUTINE    void * ;
\ *G The LPPROGRESS_ROUTINE type defines a pointer to this callback function.
\ ** CopyProgressRoutine is a placeholder for the application-defined function
\ ** name.
: LPSECURITY_ATTRIBUTES void * ;
\ *G A pointer to a SECURITY_ATTRIBUTES structure.
: LPSYSTEMTIME  void * ;
\ *G A pointer to a SYSTEMTIME structure.
: LPTCH         void * ;
\ *G A pointer to the environment block.
: LPTIME_ZONE_INFORMATION       void * ;
\ *G A pointer to a TIME_ZONE_INFORMATION structure.
: PMEMORY_BASIC_INFORMATION     void * ;
\ *G A pointer to a MEMORY_BASIC_INFORMATION structure.
: LPBY_HANDLE_FILE_INFORMATION  void * ;
\ *G A pointer to a BY_HANDLE_FILE_INFORMATION structure.
: DEVMODE       void * ;
\ *G The DEVMODE data structure contains information about the initialization
\ ** and environment of a printer or a display device.
: FONTENUMPROC  void * ;
\ *G A pointer to the application defined callback function.
: HGDIOBJ       void * ;
\ *G A handle to the graphics object.
: HPALETTE      void * ;
\ *G A handle to a logical palette.
: HRGN          void * ;
\ *G Handle to a region.
: LINEDDAPROC   void * ;
\ *G The LineDDAProc function is an application-defined callback function.
: LOGBRUSH      void * ;
\ *G The LOGBRUSH structure defines the style, color, and pattern of a physical
\ ** brush.
: LOGFONT       void * ;
\ *G The LOGFONT structure defines the attributes of a font.
: LOGPALETTE    void * ;
\ *G The LOGPALETTE structure defines a logical palette.
: LOGPEN        void * ;
\ *G The LOGPEN structure defines the style, width, and color of a pen.
: LPENHMETAHEADER       void * ;
\ *G A pointer to an ENHMETAHEADER structure that receives the header record.
: LPFONTSIGNATURE       void * ;
\ *G Pointer to a FONTSIGNATURE data structure.
: LPINT         void * ;
\ *G A pointer to an INT.
: LPLOGFONT     void * ;
\ *G A pointer to a LOGFONT structure.
: LPPALETTEENTRY        void * ;
\ *G A pointer to a PALETTEENTRY structure.
: LPSIZE        void * ;
\ *G A pointer to a SIZE structure.
: LPTEXTMETRIC  void * ;
\ *G A pointer to a TEXTMETRIC structure.
: POINT         void * ;
\ *G The POINT structure defines the x- and y- coordinates of a point.
: RECT          void * ;
\ *G The RECT structure defines the coordinates of the upper-left and
\ ** lower-right corners of a rectangle.
: DLGPROC       void * ;
\ *G Application-defined callback function used with the CreateDialog and
\ ** DialogBox families of functions.
: DRAWSTATEPROC void * ;
\ *G The DrawStateProc function is an application-defined callback function
\ ** that renders a complex image for the DrawState function.
: DWORD_PTR     void * ;
\ *G A DWORD_PTR is an unsigned long type used for pointer precision.
: GRAYSTRINGPROC        void * ;
\ *G A pointer to the application-defined function.
: HCONV         void * ;
\ *G A conversation handle.
: HCONVLIST     void * ;
\ *G A handle to the conversation list.
: HCURSOR       void * ;
\ *G A cursor handle.
: HDDEDATA      void * ;
\ *G A handle to a DDE object.
: HHOOK         void * ;
: HICON         void * ;
\ *G A handle to a Icon.
: HKL           void * ;
\ *G A handle to a keyboard layout.
: HMONITOR      void * ;
\ *G A handle to the display monitor.
: HOOKPROC      void * ;
\ *G HookProc is a placeholder for an application-defined name.
: HSZ           void * ;
\ *G A handle to the string that specifies the service name of the server
\ ** application with which a conversation is to be established.
: INT_PTR       void * ;
\ *G A signed integer type for pointer precision. Use when casting a pointer
\ ** to an integer to perform pointer arithmetic.
: LPBYTE        void * ;
\ *G A pointer to a BYTE.
: LPCDLGTEMPLATE        void * ;
\ *G A pointer to a DLGTEMPLATE structure.
: LPCMENUINFO   void * ;
\ *G A pointer to a MENUINFO structure.
: LPCRECT       void * ;
\ *G A pointer to a RECT structure.
: LPCSCROLLINFO void * ;
\ *G A pointer to a SCROLLINFO structure.
: LPDRAWTEXTPARAMS      void * ;
\ *G A pointer to a DRAWTEXTPARAMS structure.
: LPINPUT       void * ;
\ *G An array of INPUT structures.
: LPMENUITEMINFO        void * ;
\ *G A pointer to a MENUITEMINFO structure.
: LPMONITORINFO void * ;
\ *G A pointer to a MONITORINFO or MONITORINFOEX structure that receives
\ ** information about the specified display monitor.
: LPMSG         void * ;
\ *G A pointer to a MSG structure.
: LPMSGBOXPARAMS        void * ;
\ *G A pointer to a MSGBOXPARAMS structure.
: LPSCROLLINFO  void * ;
\ *G Pointer to a SCROLLINFO structure.
: LPTRACKMOUSEEVENT     void * ;
\ *G A pointer to a TRACKMOUSEEVENT structure
: LPWNDCLASSEX  void * ;
\ *G A pointer to a WNDCLASSEX structure.
: MONITORENUMPROC       void * ;
\ *G A MonitorEnumProc function is an application-defined callback function.
: PAINTSTRUCT   void * ;
\ *G The PAINTSTRUCT structure contains information for an application. This
\ ** information can be used to paint the client area of a window owned
\ ** by that application.
: PCOMBOBOXINFO void * ;
\ *G A pointer to a COMBOBOXINFO structure.
: PCONVCONTEXT  void * ;
\ *G A pointer to the CONVCONTEXT structure.
: PCONVINFO     void * ;
\ *G A pointer to the CONVINFO structure.
: PFLASHWINFO   void * ;
\ *G A pointer to a FLASHWINFO structure.
: PFNCALLBACK   void * ;
\ *G A pointer to the application-defined DDE callback function.
: PICONINFO     void * ;
\ *G A pointer to an ICONINFO structure.
: PROCESS_DPI_AWARENESS void * ;
\ *G PROCESS_DPI_AWARENESS enumeration.
: PSECURITY_QUALITY_OF_SERVICE  void * ;
\ *G A pointer to a SECURITY_QUALITY_OF_SERVICE data structure.
: SECURITY_QUALITY_OF_SERVICE   void * ;
\ *G The SECURITY_QUALITY_OF_SERVICE data structure contains information used
\ ** to support client impersonation.
: TCHAR         void * ;
\ *G A Win32 character string that can be used to describe ANSI, DBCS, or
\ ** Unicode strings.
: WNDCLASSEX    void * ;
\ *G The WNDCLASSEX structure is similar to the WNDCLASS structure. There are
\ ** two differences. WNDCLASSEX includes the cbSize member, which specifies
\ ** the size of the structure, and the hIconSm member, which contains a handle
\ ** to a small icon associated with the window class.
: WNDENUMPROC   void * ;
\ *G A pointer to an application-defined callback function.
: LPNETRESOURCE void * ;
\ *G A pointer to the NETRESOURCE structure.
: LPHANDLE      void * ;
\ *G A pointer to a handle.
: LPSHFILEOPSTRUCT      void * ;
\ *G A pointer to an SHFILEOPSTRUCT structure.
: LPBROWSEINFO  void * ;
\ *G  A pointer to a BROWSEINFO structure.
: SHELLEXECUTEINFO      void * ;
\ *G A structure that contains information used by ShellExecuteEx.
: REFKNOWNFOLDERID      void * ;
\ *G A reference to the KNOWNFOLDERID.
: PIDLIST_ABSOLUTE      void * ;
\ *G The ITEMIDLIST is absolute and has been allocated, as indicated by its
\ ** being non-constant.
: PCIDLIST_ABSOLUTE     void * ;
\ *G The ITEMIDLIST is absolute and constant.
: PWSTR         void * ;
\ *G A pointer to a null-terminated string of 16-bit Unicode characters.
: LPPRINTER_DEFAULTS    void * ;
\ *G A pointer to a PRINTER_DEFAULTS structure.
: PDEVMODE      void * ;
\ *G A pointer to a DEVMODE data structure.
\ ...JD_024
: __in  ;
\ *G Microsoft header annotation.
: __inout  ;
\ *G Microsoft header annotation.
: __out  ;
\ *G Microsoft header annotation.
\ SFP013...
: __in_opt  ;
\ *G Microsoft header annotation.
: __inout_opt  ;
\ *G Microsoft header annotation.
: __out_opt  ;
\ *G Microsoft header annotation.
: _in_  ;
\ *G Microsoft header annotation.
: _inout_  ;
\ *G Microsoft header annotation.
: _out_  ;
\ *G Microsoft header annotation.
: _in_opt_  ;
\ *G Microsoft header annotation.
: _out_opt_  ;
\ *G Microsoft header annotation.
\ ...SFP013
\ JD_024...
: _Reserved_   ;
\ *G Microsoft header annotation.
: [in]  ;
\ *G Microsoft header annotation.
\ ...JD_024
previous definitions

[THEN]          \ Target_386_Windows


\ ==============
\ *N Linux Types
\ ==============

[defined] Target_386_Linux [if]

: (setDefExt)	\ --
\ set up the Linux defaults for EXTERN: calls.
  0 to FrameAlignment  0 to FrameBackup  0 to AlignInFrame?
  TRUE to REQUIRE_NREV  0 to CalleeCleaned?
  TRUE to L>R?
  0 to ObjPtr?  0 to StructRet?  0 to varargs?
;
assign (setDefExt) to-do setDefExt

also types definitions
: OSCALL	"C"  ;
\ *G Used for portable code to avoid three sets of declarations.
\ ** For Windows, this is a synonym for *\fo{PASCAL} and under
\ ** Linux this is a synonym for *\fo{"C"}.
: FILE		uint32  ;
\ *G Always use as *\fo{FILE * stream}.
: DIR		uint32  ;
\ *G Always use as *\fo{DIR * stream}.
: size_t	uint32  ;
\ *G Linux type for unsigned INT.
: off_t	uint32  ;
\ *G Linux type for unsigned INT.
: int32_t	int32  ;
\ *G Synonym for *\fo{int32}.
: int16_t	int16  ;
\ *G Synonym for *\fo{int16}.
: int8_t	int8  ;
\ *G Synonym for *\fo{int8}.
: uint32_t	uint32  ;
\ *G Synonym for *\fo{uint32}.
: uint16_t	uint16  ;
\ *G Synonym for *\fo{uint16}.
: uint8_t	uint8  ;
\ *G Synonym for *\fo{uint8}.
: time_t	uint32  ;
\ *G Number of seconds since midnight UTC of January 1, 1970.
: clock_t	uint32  ;
\ *G Processor time in terms of CLOCKS_PER_SEC.
: pid_t		int32  ;
\ *G Process ID.
: uid_t		uint32  ;
\ *G User ID.
: mode_t	uint32  ;
\ *G File mode.
previous definitions

[then]		\ Target_386_Linux

\ =================
\ *N Mac OS X Types
\ =================

[defined] Target_386_OSX [if]

: (setDefExt)	\ --
\ set up the Mac OS X defaults for EXTERN: calls.
  #16 to FrameAlignment  0 to FrameBackup  0 to AlignInFrame?
  TRUE to REQUIRE_NREV  0 to CalleeCleaned?
  TRUE to L>R?
  0 to ObjPtr?  0 to StructRet?  0 to varargs?
;
assign (setDefExt) to-do setDefExt

also types definitions
: OSCALL	"C"  ;
\ *G Used for portable code to avoid three sets of declarations.
\ ** For Windows, this is a synonym for *\fo{PASCAL} and under
\ ** OS X this is a synonym for *\fo{"C"}.
: FILE		uint32  ;
\ *G Always use as *\fo{FILE * stream}.
: DIR		uint32  ;
\ *G Always use as *\fo{DIR * stream}.
: size_t	uint32  ;
\ *G Unix type for unsigned INT.
: off_t	uint32  ;
\ *G Unix type for unsigned INT.
: int32_t	int32  ;
\ *G Synonym for *\fo{int32}.
: int16_t	int16  ;
\ *G Synonym for *\fo{int16}.
: int8_t	int8  ;
\ *G Synonym for *\fo{int8}.
: uint32_t	uint32  ;
\ *G Synonym for *\fo{uint32}.
: uint16_t	uint16  ;
\ *G Synonym for *\fo{uint16}.
: uint8_t	uint8  ;
\ *G Synonym for *\fo{uint8}.
: time_t	uint32  ;
\ *G Number of seconds since midnight UTC of January 1, 1970.
: clock_t	uint32  ;
\ *G Processor time in terms of CLOCKS_PER_SEC.
: pid_t		int32  ;
\ *G Process ID.
: uid_t		uint32  ;
\ *G User ID.
: mode_t	uint32  ;
\ *G File mode.
previous definitions

[then]		\ Target_386_OSX


\ **********************
\ *S Compatibility words
\ **********************
\ *P These words are mainly for users converting code from other
\ ** Forth systems.

: skipTo(	\ -- ; )
\ Step forward to a space-delimited '('. )
  begin
    parse-name dup 0= abort" missing ("	\ error at end of line ; )
    s" (" compare 0=			\ look for '('; )
  until
;

: parse-params	\ -- #in #out
\ Parse a parameter list of the form:
\   ( a b c d -- e f )
  skipTo(				\ scan up to '('    )
  0 begin				\ -- u
    parse-name  2dup s" --" compare	\ compare leaves zero flag when equal !
   while				\ -- u caddr len
    s" ..." compare if			\ -- u
      dup 0 >=				\ if not varargs        (* not ...  -rt *)
      if  1+  endif			\  count up
    else
      drop -1				\ #in=-1 for varargs    (* is ...  -rt *)
    endif
  repeat
  2drop														(* get rid of dupped word+count -rt *)
  0 begin
    parse-name s" )" compare
   while
     1+
  repeat
;

: setVoid	\ struct --
  0 over ai.Size !
  UINTtype over ai.Type !
  0 over ai.FrameOff !			\ offset on operating system frame to data
  0 swap ai.PSPoff !			\ offset on Forth parameter stack as if TOS uncached
;

: setInt32	\ struct --
  4 over ai.Size !
  SINTtype over ai.Type !
  0 over ai.FrameOff !			\ offset on operating system frame to data
  0 swap ai.PSPoff !			\ offset on Forth parameter stack as if TOS uncached
;

: setInt64	\ struct --
  8 over ai.Size !
  SINTtype over ai.Type !
  0 over ai.FrameOff !			\ offset on operating system frame to data
  0 swap ai.PSPoff !			\ offset on Forth parameter stack as if TOS uncached
;

: setReturn	\ #out --
\ set the return data
  case
    0 of  ReturnRes setVoid  endof
    1 of  ReturnRes setInt32  endof
    2 of  ReturnRes setInt64  endof
      -1 abort" Bad return data
  endcase
;

: setArgs	\ #in #out --
\ Generate the data handling structures. Varargs are indicated
\ by #in=-1.
  over 0< if
    setReturn  drop  1 to varargs?
  else
    setReturn  0 to varargs?  dup numArgs ! 0
    ?do  i ArgList[] setInt32  loop
  endif
;

\ *P This section provides shared library imports in the form:
\ *C   function: foo  ( a b c d -- x )
\ *P where the brackets *\b{must} be space delimited. Imports use
\ ** the default calling convention for the operating system.

also forth definitions

: FUNCTION:	\ "<name>" "<parameter list>" --
\ *G Generate a reference to an external function. The Forth name
\ ** is the same as the name of the external function.
\ ** Use in the form:
\ *C  function: foo1 ( a b c d -- )
\ *C  function: foo2 ( a b c d -- e )
\ *C  function: foo3 ( a b c d -- el eh )
\ *P The returned value may be 0, 1 or 2 items corresponding to
\ ** void, int/long and long long on most 32 bit systems.
  setFirstLine				\ SFP022
  singleName				\ name of Forth word and DLL func ; SFP020
  usesFloats off  setDefExt		\ set default declaraction type
  parse-params setArgs
  GenerateImport
  ?ShowExtData
;

: ASCALL:	\ "<synonym-name>" "<name>" "<parameter list>" --
\ *G Generate a reference to an external function. The Forth name
\ ** is not the same as the name of the external function.
\ ** Use in the form:
\ *C  ascall: forthname funcname ( a b c d -- e )
  setFirstLine				\ SFP022
  parse-name ExternName place		\ set name of Forth word
  parse-name ImportName place		\ set name of DLL function
  usesFloats off  setDefExt		\ set default declaraction type
  parse-params setArgs
  GenerateImport ?ShowExtData
;

: GLOBAL:	\ "<name>" --
\ *G Generate a reference to an external variable.
\ ** Use in the form:
\ *C  global: varname
  singleName genExternVar		\ generate variable ; SFP020
;

previous definitions


\ **************************
\ *S Using the Windows hooks
\ **************************
\ *P The hooks *\fo{preExtCall} and *\fo{postExtCall} are
\ ** *\fo{DEFER}red words into which you can plug actions that
\ ** will be run before and after any external call. They are
\ ** principally used:
\ *(
\ *B To save and restore the NDP state when using screen and printer
\ ** drivers that do not obey all the Windows rules.
\ *B To save and restore the NDP state and you want the NDP state
\ ** preserved regardless of any consequences. Although this is safe,
\ ** the system overhead is greater than that of preserving your
\ ** floats in variables or locals as required.
\ *B Installing error handlers that work with nested callbacks.
\ *)

\ *P The hooks *\fo{preFPExtCall} and *\fo{postFPExtCall} are
\ ** compiled into calls with floating point parameters or return
\ ** values. They do not affect the NDP state.

\ *P The examples below illustrate both actions.

\ ===============================
\ *N Deferred words and variables
\ ===============================

also forth definitions
(( for DocGen
defer preExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls. It is executed at the start of the external
\ ** call before any parameter processing.
  assign noop to-do preExtCall
defer postExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls. It is executed at the end of the external
\ ** call after return data processing.
  assign noop to-do postExtCall
defer preFPExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls with floating point parameters or return
\ ** items. It is executed at the start of the external
\ ** call before any parameter processing.
  assign noop to-do preFPExtCall
defer postFPExtCall	\ --
\ *G *\b{Windows only}. A hook provided for debugging and extending
\ ** external calls with floating point parameters or return
\ ** items. It is executed at the end of the external
\ ** call after return data processing.
))
variable XcallSaveNDP?	\ -- addr
\ *G Set true when imports must save and restore the NDP state.
\ ** Windows only. From build 2069 onwards, the default behaviour
\ ** for Windows includes saving and restoring the FPU state.
\ ** This can be inhibited by clearing *\fo{XcallSaveNDP?}
\ ** before execution.
  1 XcallSaveNDP? !
variable abort-code	\ -- addr
\ *G Holds error code for higher level routines, especially
\ ** *\fo{RECOVERY} below. Windows versions only.
  abort-code off
variable aborting?	\ -- addr
\ *G Holds a flag to indicate whether error recovery should be
\ ** performed by a calling routine.
  aborting? off
defer xcall-fault	\ -- ; handles errors in winprocs
\ *G Used by application code in the *\fo{DEFER}red words
\ ** *\fo{preExtCall} and *\fo{postExtCall} above to install
\ ** user-defined actions.
  assign noop to-do xcall-fault
previous definitions


\ ===================
\ *N Default versions
\ ===================

[defined] Target_386_Windows [if]

also forth definitions

\ *[
code PreExtern	\ -- ; R: -- sys
\ Clears the abort code and saves the NDP state if XcallSaveNDP?
\ is set.
  mov   dword ptr abort-code , # 0	\ no previous abort code
  cmp	  [] XcallSaveNDP? , # 0	\ Win: required
  nz, if,
    pop     eax
    lea     esp, -/fsave [esp]
    fsave   0 [esp]
    push    eax
  endif,
  ret
end-code
assign preExtern to-do preExtCall

code PostExtern	\ -- ; R: sys --
\ Restore the NDP state if XcallSaveNDP? is set and test the
\ abort code.
  cmp   [] XcallSaveNDP? , # 0		\ required
  nz, if,
    pop     eax
    frstor  0 [esp]
    lea     esp, /fsave [esp]
    push eax
  endif,
  \ Detecting faults in nested callbacks.
  cmp   dword ptr abort-code , # 0	\ test previous aborting code
  nz, if,
    call  [] ' xcall-fault 5 +		\ execute xcall-fault if set
  endif,
  ret
end-code
assign postExtern to-do postExtCall

code PreFPExtern	\ -- ; R: -- sys ; SFP006
\ Clears the abort code.
  mov   dword ptr abort-code , # 0	\ no previous abort code
  ret
end-code
assign preFPExtern to-do preFPExtCall

code PostFPExtern	\ -- ; R: sys -- ; SFP006
\ Test the abort code.
  cmp   dword ptr abort-code , # 0	\ test previous aborting code
  nz, if,
    call  [] ' xcall-fault 5 +		\ execute xcall-fault if set
  endif,
  ret
end-code
assign postFPExtern to-do postFPExtCall

\ *]

: DefaultExterns	\ --
\ *G Set the default PRE and POST EXTERN handlers.
  assign preExtern to-do preExtCall
  assign postExtern to-do postExtCall
  assign preFPExtern to-do preFPExtCall
  assign postFPExtern to-do postFPExtCall
;
previous definitions

[then]


\ ====================
\ *N Protected EXTERNs
\ ====================
\ *P Protected EXTERNs allow VFX Forth to recover when a crash
\ ** occurs inside a Windows call and the Forth registers have
\ ** been corrupted. For example
\ *C   255 0 GetCurrentDirectory
\ *P will crash because an address of zero is invalid. Protected
\ ** EXTERNs save the Forth registers befor making the call so
\ ** that exception handlers can restore VFX Forth to a known
\ ** state.

[defined] Target_386_Windows [if]

also system definitions

struct /SCBdata	\ -- len
\ Length of data saved for a protected callback or Extern.
  int scb.xt		\ xt of callback handler
  int scb.ESP		\ ESP on entry
  int scb.EBP		\ EBP on entry
  int scb.ESI		\ ESI on entry
  int scb.EDI		\ EDI on entry
end-struct

/SCBdata buffer: XcallBuffer	\ -- addr
\ Saved data for protected EXTERNs.

also forth definitions

\ *[
code PreProtExtern	\ -- ; R: -- sys
\ Clears the abort code and saves the NDP state if XcallSaveNDP?
\ is set.
  mov    edx, # XcallBuffer		\ where the saved data goes
  mov    eax, 0 [esp]			\ return address
  sub    eax, # 6			\ xt of EXTERN (call [] prexx)
  mov    0 scb.xt [edx], eax		\ save it
  lea    eax, 4 [esp]			\ RSP on entry
  mov    0 scb.esp [edx], eax
  mov    0 scb.ebp [edx], ebp
  mov    0 scb.esi [edx], esi
  mov    0 scb.edi [edx], edi

  mov   dword ptr abort-code , # 0	\ no previous abort code
  cmp	  [] XcallSaveNDP? , # 0	\ Win: required
  nz, if,
    pop     eax				\ return address
    lea     esp, -/fsave [esp]
    fsave   0 [esp]
    push    eax
  endif,
  ret
end-code

code PostProtExtern	\ -- ; R: sys --
\ Restore the NDP state if XcallSaveNDP? is set and test the
\ abort code.
  mov   dword ptr XcallBuffer scb.xt , # 0  \ reset Extern in progress
  cmp   [] XcallSaveNDP? , # 0		\ required
  nz, if,
    pop     eax				\ return address
    frstor  0 [esp]
    lea     esp, /fsave [esp]
    push eax
  endif,
  \ Detecting faults in nested callbacks.
  cmp   dword ptr abort-code , # 0	\ test previous aborting code
  nz, if,
    call  [] ' xcall-fault 5 +		\ execute xcall-fault if set
  endif,
  ret
end-code

code PreProtFPExtern	\ -- ; R: -- sys ; SFP006
\ Clears the abort code.
  mov    edx, # XcallBuffer		\ where the saved data goes
  mov    eax, 0 [esp]			\ return address
  sub    eax, # 6			\ xt of EXTERN (call [] prexx)
  mov    0 scb.xt [edx], eax		\ save it
  lea    eax, 4 [esp]			\ RSP on entry
  mov    0 scb.esp [edx], eax
  mov    0 scb.ebp [edx], ebp
  mov    0 scb.esi [edx], esi
  mov    0 scb.edi [edx], edi

  mov   dword ptr abort-code , # 0	\ no previous abort code
  ret
end-code

code PostProtFPExtern	\ -- ; R: sys -- ; SFP006
\ Test the abort code.
  mov   dword ptr XcallBuffer scb.xt , # 0	\ reset Extern in progress
  cmp   dword ptr abort-code , # 0	\ test previous aborting code
  nz, if,
    call  [] ' xcall-fault 5 +		\ execute xcall-fault if set
  endif,
  ret
end-code
\ *]

: ProtectedExterns	\ --
\ *G Set the protected PRE and POST EXTERN handlers.
  assign preProtExtern to-do preExtCall
  assign postProtExtern to-do postExtCall
  assign preProtFPExtern to-do preFPExtCall
  assign postProtFPExtern to-do postFPExtCall
;
previous previous definitions

[then]


\ **************************
\ *S Interfacing to C++ DLLs
\ **************************
\ *N Caveats
\ *P These notes were written after testing on Visual C++ v6.0.
\ ** Don't blame us if the rules change!

\ *N Example code
\ *P The example code may be found in the directory EXAMPLES\VC++.
\ ** Because of the inordinate amount of time we spent wandering
\ ** around inside debuggers to get this far, we recommend that
\ ** you adopt a cooperative and investigative attitude when
\ ** requesting technical support on this topic.

\ *N Accessing constructors and destructors
\ *P Example code for accessing the constructor of class is
\ ** provided in *\i{TRYCPP.FTH} which accesses the class DllTest
\ ** in *\i{DLLTEST.CPP}.
\ *P Since C++ is supposed to provide a higher level of abstraction,
\ ** apparently simple operations may generate reams of code. So it
\ ** is with the equivalent of
\ *C   pClass = new SomeClass;
\ *P The actual code generated may/will be a call to a function new
\ ** to generate an object structure (not a single cell) followed
\ ** by passing the return value from new to the class constructor.

\ *P The class constructor (in C++ CDllTest::CDllTest()) is not normally
\ ** exported from C++ without some extra characters being added to
\ ** the name. For example, the reference to it in the example code is:
\ *C   extern: PASCAL void * ??0CDLLTest@@QAE@XZ( void );
\ *P This function is not directly callable because it has
\ ** to be passed the result of the *\fo{new} operator. To solve this
\ ** problem *\i{DLLTest.dll} contains a helper function *\fo{CallNew}
\ ** which is passed the address of the constructor for the class.
\ ** This is redefined as *\fo{NEW} for normal use.
\ *E \ C++ Helpers
\ ** extern: PASCAL void * CallNew( void * );
\ ** extern: PASCAL void CallDelete( void * this);

\ *E \ CDLLTest class specific
\ ** extern: PASCAL void * ??0CDLLTest@@QAE@XZ( void );
\ **
\ ** 0 value CDLLTest	\ -- class|0
\ **
\ ** : InitCDLLTest	\ -- ; initialise the CPP interface
\ **   ['] ??0CDLLTest@@QAE@XZ func-loaded? -> CDLLTest
\ ** ;
\ **
\ ** : New	\ class -- *obj|0
\ **   CallNew
\ ** ;
\ **
\ ** : Delete	\ *obj --
\ **   CallDelete
\ ** ;

\ *P The word *\fo{INITCDLLTEST} gets the address of the constructor for the class,
\ ** and NEW then runs the CallNew function which executes the
\ ** C++ new operator and calls the constructor. Unfortunately, you will
\ ** have to do this for each class that use in the DLL. What is returned
\ ** by CallNew is an object pointer. This is not the object itself, but
\ ** the address of another (undocumented) data structure. It can be used
\ ** as the this pointer for all following member function calls.

\ *P Once you have finished with the onject, you must relase its
\ ** resources using the delete method (the destructor). This is
\ ** implemented in VC++ by passing the object pointer to the
\ ** delete function. This is performed by the CallDelete function
\ ** exported from the DLL. Again, the Forth word DELETE provides
\ ** syntactic sugar by just calling CallDelete.

\ =============================
\ *N Accessing member functions
\ =============================
\ *P A Visual C++ member function exported from a DLL requires
\ ** the "this" pointer in the ECX register. This can be achieved
\ ** using the following form:
\ *E extern: VC++ PASCAL BOOL TestWindow1( void * this, char * ch, int n, int nbyte );
\ *P The function must be defined with an explicit this
\ ** pointer (void * this). Because exported VC++ member
\ ** functions can have either C or "PASCAL" styles, the this
\ ** pointer must be positioned so that it is leftmost when
\ ** reversed (C/PASCAL/WINAPI/StdCall/APIENTRY style) or is
\ ** rightmost when not reversed ("PASCAL" style).

\ *E extern: PASCAL VC++ BOOL GetHello( void * this, char * buff, int len );
\ ** extern: PASCAL VC++ BOOL TestWindow1( void * this, char * ch, int n, int nbyte );
\ ** extern: PASCAL VC++ BOOL TestWindow2( void * this, void * pvoid, int ndword, int nlong );
\ **
\ ** 0 value CDLLTest	\ -- constructor/class
\ **
\ ** : InitCDLLTest	\ --;  Initialise the CPP interface
\ **   ['] ??0CDLLTest@@QAE@XZ func-loaded? to CDLLTest
\ ** ;
\ **
\ ** create Magic#  $AAAA5555 ,	\ -- addr
\ **
\ ** #64 buffer: StringBuff	\ -- ; buffer for GetHello
\ **
\ ** : TestCDLLTest	\ -- ; test CDLLTest interface
\ **   InitCDLLTest  CDLLTest if
\ **     cr ." Initialisation succeeded"
\ **     CDLLTest new ?dup if
\ **       cr ." new succeeded"
\ **       dup StringBuff #64 GetHello drop
\ **       cr ." GetHello returns: " StringBuff .z$
\ **       dup Magic# 4 5 TestWindow1 drop
\ **       dup Magic# #20 #30 TestWindow2 drop
\ **       delete
\ **       cr ." delete done"
\ **     else
\ **       cr ." new failed"
\ **     endif
\ **   else
\ **     cr ." Initialisation failed"
\ **   endif
\ ** ;
\ **

\ *P Please note that the actual code in TRYCPP.FTH may/will be
\ ** different as we extend the facilities. See the source code
\ ** itself!

\ =================================
\ *N Accessing third party C++ DLLs
\ =================================
\ *P Most third party C++ DLLs are provided with C header files which
\ ** define the interfaces. Study of these will provide the information
\ ** you need to determine how to access them.
\ *P For simple C++ classes, the DllTest.dll file can be used
\ ** to provide constructor and destructor access. Note that classes with multiple
\ ** constructors will export these as functions with the same basic
\ ** name differentiated by the name mangling.

\ *P The DLL *\i{Fth2VC60.dll} contains new and delete access for use
\ ** with other DLLs. Note that the third party DLLs must be
\ ** compatible with VC++ v6.0. The example file *\i{EXAMPLES\VC++\USECPP.FTH}
\ ** demonstrates using *\i{Fth2VC60.dll}.

\ *E library: Fth2VC60.dll
\ **
\ ** extern: PASCAL void * FTH2CPPNew( void * constructor);
\ ** extern: PASCAL void FTH2CPPDelete( void * this);
\ **
\ ** : New		\ *class -- *obj|0
\ **   FTH2CPPNew
\ ** ;
\ **
\ ** : Delete	\ *obj --
\ **   FTH2CPPDelete
\ ** ;
\ **

\ *P If you are using an incompatible compiler or DLL, create a
\ ** similar support DLL for that compiler. You can use the source
\ ** code for *\i{Fth2VC60.dll} as an example.


\ ******************
\ *S Changes at v4.3
\ ******************
\ *P The guts of the *\fo{EXTERN:} mechanism have been rewritten
\ ** to provide more features and to support more operating systems.

\ =====================
\ *N Additional C types
\ =====================
\ *P The following C data types are now supported:
\ *(
\ *B Float - a 32 bit floating point item.
\ *B Double - a 64 bit floating point item
\ *B LongLong - a 64 bit integer. These are taken from and
\ ** returned to the Forth data stack as Forth double numbers
\ ** with the high portion topmost on the stack.
\ *)

\ *P Floating point numbers are taken from the NDP floating
\ ** point unit. This is directly compatible with the the Forth
\ ** floating point pack in *\i{Lib\x86\Ndp387.fth}.

\ =========================
\ *N More Operating Systems
\ =========================
\ *P The requirements of newer operating systems, especially
\ ** those for 64-bit operation, are more stringent for things
\ ** like data alignment. Consequently the underlying mechanism
\ ** has changed.

\ ================
\ *N Miscellaneous
\ ================
\ *P These notes are probably only relevant for code that has
\ ** carnal knowledge of the VFX Forth internals.
\ *(
\ *B The *\fo{XCALL} primitive has been removed and is replaced
\ ** by *\fo{NXCALL}.
\ *B The compile time code generation is completely different and
\ ** there is no centralised despatch mechanism.
\ *B Some faciliies provided by *\i{Lib\Win32\SafeCallback.fth}
\ ** are now built in to the Windows system. You *\b{must} use
\ ** the new version of *\i{SafeCallback.fth}.
\ *)

\ *P The word *\fo{NXCALL} is provided for constructing your own
\ ** import mechanisms, but it only deals with single-cell
\ ** arguments and provides no type safety at all. It is used
\ ** internally by VFX Forth in the first stage build of a
\ ** console-mode kernel.

(( for DocGen
code NXCALL     \ i*x addr i -- res
\ *G Calls the operating system function at *\i{addr} with *\i{i}
\ ** arguments, returning the result *\i{res}. As far as the
\ ** operating systems is concerned, *\i{i*x} appear on the CPU
\ ** return stack pointed to by ESP, and the return value is taken
\ ** from EAX. After executing *\fo{NXCALL} the return value *\i{res}
\ ** is the contents of the EAX register.
end-code
))


\ *********
\ Test code
\ *********

((
\ OSX format test code
: OSXDefExt	\ --
\ set up the Mac OS X defaults for EXTERN: calls.
  #16 to FrameAlignment  4 to FrameBackup  1 to AlignInFrame?
  TRUE to REQUIRE_NREV  0 to CalleeCleaned?
  0 to ObjPtr?  0 to StructRet?
;
: LinDefExt	\ --
\ set up the Linux defaults for EXTERN: calls.
  0 to FrameAlignment  0 to FrameBackup  0 to AlignInFrame?
  TRUE to REQUIRE_NREV  0 to CalleeCleaned?
  0 to ObjPtr?  0 to StructRet?
;

assign OSXDefExt to-do setDefExt

extern: int nanosleep( void * req, void * rem );

: Sleep	\ ms -- ior
  { | tspec[ 2 cells ] -- }
  #1000 /mod				\ -- rem quotient
  tspec[ 0 + !				\ seconds
  #1000000 * tspec[ cell + !		\ ns
  tspec[ 0 nanosleep
;
assign LinDefExt to-do setDefExt
))

previous definitions


\ ======
\ *> ###
\ ======

decimal

((
[14:06:48] Willem Botha:
: FIND-LIB                                           ( addr cnt --- addr|false )
   zFILENAME: %zsfile
   zFILENAME: %zdfile
   <to> %zsfile
   [ ALSO Extern.Voc ]
  lib-link
  begin
    @ dup
  while
    dup >libname ZCOUNT <to> %zdfile
    <count> %zdfile <count> %zsfile FILES-NAMES-EQUAL?
    IF EXIT THEN
    >liblink
  repeat
  drop
  False
  [ PREVIOUS ]
  ;

: FREE-LIBRARY                                                  ( addr cnt --- ) 06/05/1311:31WJB
   zFILENAME: %zfile 06/05/1311:20WJB
   L-VAR: %addr 06/05/1311:30WJB
   <to> %zfile 06/05/1311:20WJB
  [ ALSO Extern.Voc ] 06/05/1309:39WJB
   <count> %zfile FIND-LIB <to> %addr 06/05/1311:30WJB
   %addr 0= 06/05/1311:30WJB
   IF S" DLL" <+ext> %zfile 06/05/1311:31WJB
      <count> %zfile FIND-LIB <to> %addr 06/05/1311:30WJB
   THEN 06/05/1311:31WJB
   %addr BOOLEAN 06/05/1311:31WJB
   IF 10/05/1312:20WJB
        %addr LIB>-HANDLE BOOLEAN 10/05/1312:21WJB
        IF   %addr LIB>-HANDLE FreeLibrary 10/05/1312:21WJB
             IF   %addr >libaddr OFF 06/05/1311:39WJB
             ELSE <count> %zfile >ABORT-FNAME$ 06/05/1311:42WJB
                  S" Free Library" >ABORT-FUNC$ 06/05/1311:42WJB
                  ERR_LAST_OPERATION_FAILED ERROR 06/05/1311:41WJB
             THEN 06/05/1311:28WJB
        THEN 10/05/1312:21WJB
   THEN 06/05/1311:21WJB
  [ PREVIOUS ] 06/05/1309:39WJB
  ; 06/05/1311:19WJB))
