# trivial-scgi
SCGI library for Common Lisp. This repository is an archive copy.
The files were retrieved from http://www.randallsquared.com/download/scgi/ as
linked to from a *Linux Journal* article:
[Faster Web Applications with SCGI](https://www.linuxjournal.com/article/9310).

All files in this repository are in the public domain.

---

Excerpt from [trivial-scgi-0.2c.lisp](./trivial-scgi-0.2c.lisp):

Releases of trivial-scgi will track trivial-sockets releases on which they
depend. Any improvement to this package will be released with a letter upgrade
(e.g. 0.2g), but no numerical upgrade until trivial-sockets by Daniel Barlow
moves to a new version.

This package depends on trvial-sockets, which you can find through this link:
http://www.cliki.net/trivial-sockets (if not, please let me know so I can
update this).

SCGI is a fast, simple replacement for traditional CGI, in the mode of FastCGI,
but easier to implement. There exists a mod_scgi for Apache 1 and 2, and a CGI
translator for those sites unable to access Apache directly. More information
can be found here: http://www.mems-exchange.org/software/scgi/.

This file contains no code, explicitly or by inclusion, from the SCGI codebase,
and was produced by reference to http://python.ca/nas/scgi/protocol.txt.

To use, read the docstring for `WITH-SCGI-SERVER`, and documentation for your
copy of SCGI. An example is provided that works with the examples in the SCGI
package noted above.

No threading or other multi-processing support is included in this. Such things
are currently beyond the scope of trivial-sockets, and therefore this package.
If you need to use this with multi-processing, you'll want to pass
`:INPUT :STREAM` to `WITH-SCGI-SERVER`, so that it doesn't try to output to and
clean up the request stream itself.

If you're building a web application from scratch, you might well want to use
mod_lisp (http://www.fractalconcept.com/). This package is for those who already
have projects which are using CGI and want to convert relatively painlessly, or
who are comfortable with developing in a CGI-centric way, or who may find
themselves deploying in situations where they have no control over the web
server (and so require CGI), but who would like to use the same code in their
CGI and non-CGI systems. The SCGI package mentioned above contains a CGI-to-SCGI
translator for just this purpose.

Changes:
* 0.2a initial release
* 0.2b added an option to `WITH-SCGI-SERVER` to get the stream, rather than a
  vector, to ease working with uploaded files added rationale
* 0.2c added more rationale ;)
  * messed around with support for `WITH-SCGI-SERVER`'s body handling the stream
    itself
  * exported `EXAMPLE`, `ASCII-CODE`, and `CODE-ASCII`
  * Added a `:PORT` keyword to `EXAMPLE`
