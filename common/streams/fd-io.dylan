module: file-descriptors
author: ram+@cs.cmu.edu
synopsis: This file implements Unix FD I/O 
copyright: See below.
rcs-header: $Header: /home/housel/work/rcs/gd/src/common/streams/fd-io.dylan,v 1.5 1996/08/10 20:20:29 nkramer Exp $

//======================================================================
//
// Copyright (c) 1994  Carnegie Mellon University
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports, questions, comments, and suggestions should be sent by
// E-mail to the Internet address "gwydion-bugs@cs.cmu.edu".
//
//======================================================================
//

method () => ();
#if (compiled-for-x86-win32)
  c-include("errno.h");
#else
  c-include("unistd.h");
#endif
  c-include("fcntl.h");
  c-include("string.h");
end();
  
define /* exported */ constant fd-seek-set :: <integer>
  = c-expr(int:, "SEEK_SET");

define /* exported */ constant fd-seek-current :: <integer>
  = c-expr(int:, "SEEK_CUR");

define /* exported */ constant fd-seek-end :: <integer>
  = c-expr(int:, "SEEK_END");


define /* exported */ constant fd-o_rdonly :: <integer>
 = c-expr(int:, "O_RDONLY");

define /* exported */ constant fd-o_wronly :: <integer>
 = c-expr(int:, "O_WRONLY");

define /* exported */ constant fd-o_rdwr :: <integer>
 = c-expr(int:, "O_RDWR");

define /* exported */ constant fd-o_creat :: <integer>
 = c-expr(int:, "O_CREAT");

define /* exported */ constant fd-o_trunc :: <integer>
 = c-expr(int:, "O_TRUNC");

define /* exported */ constant fd-o_excl :: <integer>
 = c-expr(int:, "O_EXCL");

define /* exported */ constant fd-enoent :: <integer>
 = c-expr(int:, "ENOENT");

define /* exported */ constant fd-eexist :: <integer>
 = c-expr(int:, "EEXIST");

define /* exported */ constant fd-eacces :: <integer>
 = c-expr(int:, "EACCES");


define /* exported */ generic fd-open
    (name :: <byte-string>, mode :: <integer>)
 => (fd :: false-or(<integer>), errno :: false-or(<integer>));

define /* exported */ generic fd-close (fd :: <integer>)
 => (success :: <boolean>, errno :: false-or(<integer>));

define /* exported */ generic fd-read
    (fd :: <integer>, buf :: <buffer>, start :: <integer>,
     buf-end :: <integer>)
 => (nbytes :: false-or(<integer>), errno :: false-or(<integer>));

define /* exported */ generic fd-write
    (fd :: <integer>, buf :: <buffer>, start :: <integer>,
     buf-end :: <integer>)
 => (nbytes :: false-or(<integer>), errno :: false-or(<integer>));

define /* exported */ generic fd-seek
    (fd :: <integer>, offset :: <integer>,
     whence :: <integer>)
 => (newpos :: false-or(<integer>), errno :: false-or(<integer>));


define /* exported */ generic fd-input-available? (fd :: <integer>)
 => (available :: <boolean>, errno :: false-or(<integer>));

define /* exported */ generic fd-sync-output (fd :: <integer>)
 => (success :: <boolean>, errno :: false-or(<integer>));

define /* exported */ generic fd-error-string (num :: <integer>) 
 => res :: <byte-string>;


// Actual methods:


// Fetch errno if the "result" is negative, otherwise return the result & #f
//
define inline method results (okay :: <integer>, result :: <object>) 
    => (res :: <object>, errno :: false-or(<integer>));
  if (okay < 0)
    values(#f, c-expr(int:, "errno"));
  else
    values(result, #f);
  end if;
end method;


// Allocate a buffer to hold a string, and fill it with the string contents and
// a final 0 (null).  Return the address of the data.
//
define method string->c-string (str :: <byte-string>)
    => res :: <raw-pointer>;
  let ssize = str.size;
  let sbuf = make(<buffer>, size: ssize + 1);
  for (i :: <integer> from 0 below ssize)
    sbuf[i] := as(<integer>, str[i]);
  end for;
  sbuf[ssize] := 0;
  buffer-address(sbuf);
end method;


define inline method fd-open
    (name :: <byte-string>, flags :: <integer>)
 => (fd :: false-or(<integer>), errno :: false-or(<integer>));
  let real-flags =
#if (newlines-are-CRLF)
     logior(flags, c-expr(int:, "O_BINARY"));
#else
     flags;
#endif
  let res = call-out("open", int:,
		     ptr: string->c-string(name),
		     int: real-flags,
		     int: #o666);
  results(res, res);
end method;


define inline method fd-close (fd :: <integer>)
 => (success :: <boolean>, errno :: false-or(<integer>));
  let res = call-out("close", int:, int: fd);
  results(res, #t);
end method;


define inline method fd-read
    (fd :: <integer>, buf :: <buffer>, start :: <integer>,
     buf-end :: <integer>)
 => (nbytes :: false-or(<integer>), errno :: false-or(<integer>));
  let res = call-out("read", int:, int: fd, ptr: buffer-address(buf) + start,
		     int: buf-end - start);
  results(res, res);
end method;


define inline method fd-write
    (fd :: <integer>, buf :: <buffer>, start :: <integer>,
     buf-end :: <integer>)
 => (nbytes :: false-or(<integer>), errno :: false-or(<integer>));
  let res = call-out("write", int:, int: fd, ptr: buffer-address(buf) + start,
		     int: buf-end - start);
  results(res, res);
end method;


define inline method fd-seek
    (fd :: <integer>, offset :: <integer>,
     whence :: <integer>)
 => (newpos :: false-or(<integer>), errno :: false-or(<integer>));
  let res = call-out("lseek", int:, int: fd, long: offset, int: whence);
  results(res, res);
end method;


define method fd-input-available? (fd :: <integer>)
 => (available :: <boolean>, errno :: false-or(<integer>));
  values(#t, #f); // ### hack
end method;

define method fd-sync-output (fd :: <integer>)
 => (success :: <boolean>, errno :: false-or(<integer>));
  values(#t, #f); // ### hack
end method;

define method fd-error-string (num :: <integer>) 
 => res :: <byte-string>;
  let ptr = call-out("strerror", #"ptr", #"int", num);
  let len = call-out("strlen", #"int", #"ptr", ptr);
  let res = make(<byte-string>, size: len);
  for (i from 0 below res.size)
    res[i] := as(<character>, pointer-deref(#"unsigned-char", ptr, i));
  end for;
  res;
end method;
