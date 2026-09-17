# vlc-hide-eadir-synology

*[English](README.md) · **Italiano***

Nasconde alla playlist di VLC le directory `@eaDir` dei NAS Synology.

## Il problema

Ogni cartella condivisa di un NAS Synology contiene una directory `@eaDir`
con miniature e metadati dell'indicizzazione. Al suo interno Synology crea
sottodirectory chiamate **esattamente come i file multimediali**:

```
Film/
├── film.mp4                                   ← il video vero
└── @eaDir/
    ├── film.mp4/                              ← una DIRECTORY, non un file
    │   └── SYNOINDEX_MEDIA_INFO
    └── SYNOPHOTO_THUMB_M.jpg
```

Se apri `Film/` in VLC, la cartella viene espansa in modo ricorsivo e la
playlist si riempie di doppioni illeggibili. Siccome `@eaDir` precede in
ordine alfabetico la maggior parte dei nomi, spesso VLC prova a riprodurne
uno per primo e mostra `VLC non è in grado di aprire il MRL ...`.

L'opzione "estensioni ignorate" di VLC qui non serve: la voce spuria è una
directory il cui nome finisce in `.mp4`, quindi supera qualunque filtro
sulle estensioni. La directory va filtrata per nome.

## Cosa fa

Un piccolo script di interfaccia Lua che rimuove periodicamente dalla
playlist le voci che si trovano sotto un componente `@eaDir`.

**Non tocca mai il disco.** L'unica chiamata di rimozione è
`vlc.playlist.delete()`, che elimina la voce dalla playlist. I tuoi file e
le cartelle `@eaDir` sul NAS restano esattamente dove sono.

Il confronto avviene su componenti interi del percorso, non su
sottostringhe: un file che per caso contiene `@eaDir` nel nome viene
mantenuto. Sono riconosciute sia la forma `@eaDir` sia quella codificata
`%40eaDir` che VLC usa nelle URI.

## Requisiti

VLC 3.x. Sviluppato e provato su VLC 3.0.23 (Debian 13, NAS montato via
NFS). Si basa sull'API Lua delle interfacce (`vlc.playlist.get/delete`),
cambiata in VLC 4: lì non funziona senza modifiche.

## Installazione

```sh
mkdir -p ~/.local/share/vlc/lua/intf
cp noeadir.lua ~/.local/share/vlc/lua/intf/
```

Su Windows usa `%APPDATA%\vlc\lua\intf\`, su macOS
`~/Library/Application Support/org.videolan.vlc/lua/intf/`.

Poi indica a VLC di caricarlo come interfaccia aggiuntiva. In
`~/.config/vlc/vlcrc`, cerca la riga `extraintf=` e imposta:

```ini
extraintf=luaintf{intf=noeadir}
```

Riavvia VLC. Per verificare, apri `Strumenti → Messaggi`, imposta la
verbosità a 2 e cerca `[noeadir]`.

### Se usi già un altro script di interfaccia Lua

È qui che ci si incastra: **VLC onora un solo valore `lua-intf`**, quindi
non basta aggiungerci un secondo script. Serve la sintassi inline dei
moduli, che assegna a ciascuna interfaccia il proprio script:

```ini
extraintf=luaintf{intf=noeadir}:luaintf{intf=tuo-altro-script}
```

Girano come interfacce indipendenti. Lo stesso vale da riga di comando:

```sh
vlc --extraintf 'luaintf{intf=noeadir}:luaintf{intf=tuo-altro-script}'
```

## Regolazione

`POLL_INTERVAL`, in cima allo script (predefinito 200 ms), è l'intervallo
tra un controllo della playlist e il successivo.

## Limite noto

Il filtro agisce *dopo* che VLC ha popolato la playlist. Su cartelle molto
grandi VLC può tentare per una frazione di secondo di aprire una voce
`@eaDir` prima che venga rimossa, mostrando un errore passeggero.
Abbassare `POLL_INTERVAL` riduce questa finestra.

## Licenza

MIT — vedi [LICENSE](LICENSE).
