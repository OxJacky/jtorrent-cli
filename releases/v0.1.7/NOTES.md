Failed downloads now exit immediately and report the server’s failure reason. Torrents that exceed your plan’s size limit show the limit and upgrade guidance instead of remaining on a failed progress bar until Ctrl+C.

- Recognizes the server’s `FAILED` status as terminal while retaining support for `ERROR`.
- Removes the unfinished local download folder and preserves existing files.

Update with `brew update && brew upgrade jtorrent`.
