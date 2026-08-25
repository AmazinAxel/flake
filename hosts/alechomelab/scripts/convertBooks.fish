#!/usr/bin/env fish
#
# Convert any new or updated EPUB in /media/books into .compiled/<stem>/.
# Triggered by the book-convert.path unit whenever the directory changes.

set -l BOOKS /media/books
set -l COMPILED $BOOKS/.compiled

test -d $BOOKS; or exit 0
mkdir -p $COMPILED

for epub in $BOOKS/*.epub $BOOKS/*.EPUB
    test -f $epub; or continue

    set -l stem (basename $epub | string replace -ir '\.epub$' '')
    set -l out $COMPILED/$stem
    set -l wgb $out/book.wgb

    # Skip unless missing or the source is newer — this unit fires on every
    # directory change, including the ones it causes itself.
    if test -f $wgb; and test $wgb -nt $epub
        continue
    end

    # Convert into a staging dir and move into place. A partially written book
    # must never be visible: the reader may be syncing concurrently, and it
    # takes any directory containing book.wgb as complete.
    set -l tmp (mktemp -d $COMPILED/.tmp.XXXXXX)
    if epub2wgb -q -o $tmp $epub; and test -f $tmp/$stem/book.wgb
        rm -rf $out
        mv $tmp/$stem $out
        chmod -R a+rX $out

        # A stored reading position indexes into a specific book.wgb, so it is
        # meaningless against a rebuilt one. Dropping it costs a bookmark;
        # keeping it would silently resume at the wrong place.
        #
        # Done through the webserver rather than by editing .sync.json here:
        # the server is the file's only writer, so there is no torn-write race
        # between two processes, and it already does this atomically.
        #
        # The name goes in the body, not the path: book names contain spaces
        # ("the hobbit"), and curl rejects those in a URL outright — every
        # single call failed with "Malformed input to a URL function". Encoding
        # them by hand in fish is worse than just not putting them in the URL.
        curl -fsS -m 5 -X POST --data-urlencode "dir=$stem" \
            http://localhost/booksync/dropped >/dev/null
        or echo "warn: could not drop stored position for $stem" >&2

        echo "converted $stem"
    else
        echo "FAILED $stem" >&2
    end
    rm -rf $tmp
end
