# dmp2mml
Converts one or more 4-operator FM instrument patches from **DefleMask** .DMP files into a **Professional Music Driver (PMD) Music Macro Language** (.MML) file for use in *PMD68* (Yamaha YM2151), *PMD88/PMD98* (Yamaha YM2203/YM2608), and *PMDTOWNS* (Yamaha YM2612) music files. The contents of the resulting MML file may be copied and directly pasted onto your music file’s MML source code, or you may indirectly include the output MML file into your MML music code via an `#Include` statement above every music command.

Authors: @OPNA2608 and @SilSinn9801<br>
License: Public Domain

Usage:
> ```dmp2mml.lua dmpfile_1 [ dmpfile_2 [...] ] [ > mmlfile ]```

Parameters:
> `dmpfile`: DefleMask instrument patch file (`.DMP`) or *stdin* (`-`)<br>
> `mmlfile`: PMD68/88/98/TOWNS list of instrument patches (`.MML`)

If no `mmlfile` parameter is supplied, the MML conversion will be output to *stdout* (the terminal screen).
