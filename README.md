# vlc-hide-eadir-synology

Hide Synology `@eaDir` directories from VLC's playlist.

## The problem

Every shared folder on a Synology NAS contains an `@eaDir` directory with
thumbnails and indexing metadata. Inside it, Synology creates
subdirectories named **exactly like your media files**:

```
Movies/
├── movie.mp4                                  ← the real video
└── @eaDir/
    ├── movie.mp4/                             ← a DIRECTORY, not a file
    │   └── SYNOINDEX_MEDIA_INFO
    └── SYNOPHOTO_THUMB_M.jpg
```

Open `Movies/` in VLC and it expands the tree recursively, so the playlist
fills up with unplayable duplicates. Because `@eaDir` sorts before most
names, VLC often tries to play one of them first and throws
`VLC is unable to open the MRL ...`.

VLC's "ignored extensions" setting does not help here: the bogus entry is a
directory whose name ends in `.mp4`, so it passes any extension filter. The
directory itself has to be filtered out by name.

## What this does

A small Lua interface script that periodically removes playlist entries
that live under an `@eaDir` component.

It **never touches the disk.** The only removal call it makes is
`vlc.playlist.delete()`, which drops an entry from the playlist. Your files
and the `@eaDir` folders on the NAS are left exactly as they are.

Whole path components are matched, not substrings, so a file that merely
happens to have `@eaDir` in its name is kept. Both `@eaDir` and the
percent-encoded `%40eaDir` form that VLC uses in URIs are recognised.

## Requirements

VLC 3.x. Developed and tested on VLC 3.0.23 (Debian 13, NAS mounted over
NFS). It relies on the Lua interface API (`vlc.playlist.get/delete`), which
changed in VLC 4 — it will not work there unmodified.

## Install

```sh
mkdir -p ~/.local/share/vlc/lua/intf
cp noeadir.lua ~/.local/share/vlc/lua/intf/
```

On Windows use `%APPDATA%\vlc\lua\intf\`, on macOS
`~/Library/Application Support/org.videolan.vlc/lua/intf/`.

Then tell VLC to load it as an extra interface. In
`~/.config/vlc/vlcrc`, find the `extraintf=` line and set:

```ini
extraintf=luaintf{intf=noeadir}
```

Restart VLC. To verify, open `Tools → Messages`, set verbosity to 2 and
look for `[noeadir]`.

### If you already use another Lua interface script

This is the part that trips people up: **VLC only honours a single
`lua-intf` value**, so you cannot just add a second script there. Use the
inline module syntax to give each interface its own script:

```ini
extraintf=luaintf{intf=noeadir}:luaintf{intf=your-other-script}
```

Both run as independent interfaces. The same works on the command line:

```sh
vlc --extraintf 'luaintf{intf=noeadir}:luaintf{intf=your-other-script}'
```

## Tuning

`POLL_INTERVAL` at the top of the script (default 200 ms) is how often the
playlist is swept.

## Known limitation

The filter runs *after* VLC has populated the playlist. On a very large
folder, VLC may briefly attempt to open an `@eaDir` entry in the fraction
of a second before it is removed, showing a transient error. Lowering
`POLL_INTERVAL` shrinks that window.

## License

MIT — see [LICENSE](LICENSE).
