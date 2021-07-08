# dmp2mml
Converts one or more 4-operator FM instrument patches from **DefleMask** .DMP files into a **Professional Music Driver (PMD) Music Macro Language** (.MML) file for use in *PMD68* (Yamaha YM2151), *PMD88/PMD98* (Yamaha YM2203/YM2608), and *PMDTOWNS* (Yamaha YM2612) music files. The contents of the resulting MML file may be copied and directly pasted onto your music file’s MML source code, or you may indirectly include the output MML file into your MML music code via an `#Include` statement above every music command.

Authors: @OPNA2608 and @SilSinn9801<br>
License: Public Domain

Requires: Lua interpreter version 5.3 or higher; does not properly run under 5.1 or lower; untested under 5.2.

Usage under UNIX, Linux, or MacOS X:
> ```dmp2mml.lua "dmpfile_1" [ "dmpfile_2" [...] ] [ > mmlfile ]```

Usage under Windows (Command Prompt; assumes Lua interpreter is named lua.exe):
> ```lua dmp2mml.lua "dmpfile_1" [ "dmpfile_2" [...] ] [ > mmlfile ]```

Usage under Windows (PowerShell; also assumes Lua interpreter is named lua.exe):
> ```.\lua dmp2mml.lua "dmpfile_1" [ "dmpfile_2" [...] ] [ > mmlfile ]```

Parameters:
> `dmpfile`: DefleMask instrument patch file (`.DMP`) or *stdin* (`-`)<br>
> `mmlfile`: PMD68/88/98/TOWNS list of instrument patches (`.MML`)

If no `mmlfile` parameter is supplied, the MML conversion will be output to *stdout* (the terminal screen).
