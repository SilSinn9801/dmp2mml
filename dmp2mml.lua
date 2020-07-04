#!/usr/bin/env lua

--[[
  dmp2mml: Converts one or more 4-op FM instrument patches from DefleMask DMP
           files into a Professional Music Driver (PMD) Music Macro Language
           (MML) file for use in PMD68 (YM2151), PMD88/PMD98 (YM2203/YM2608),
           and PMDTOWNS (YM2612) music files.
  Authors: OPNA2608 (オップナー2608#6983)
           Silent Sinner in Scarlet (SilSinn9801#0413)
  License: Public Domain
  Usage:   lua dmp2mml.lua dmpfile_1 [dmpfile_2 [...] ]
           lua dmp2mml.lua dmpfile_1 [dmpfile_2 [...] ] > mmlfile
  Parameters:
    dmpfile: DefleMask instrument patch file (.DMP)
    mmlfile: PMD68/88/98/TOWNS list of instrument patches (.MML)
]]

local stdinprocessed = false

if (#arg == 0) then
  print ("Usage: dmp2mml.lua dmpfile_1 [dmpfile_2 [...] ] [> mmlfile]")
  os.exit (0)
end

for n, dmpfile in ipairs (arg) do

  -- If regular file, open
  -- If STDIN, only use once & silently ignore further repetitions of "-"
  local filestdin = (dmpfile == "-")
  if (not filestdin or not stdinprocessed) then
    local dmpfilehandle = nil
    if not filestdin then
      dmpfilehandle = io.open (dmpfile, "rb")
    else
      dmpfilehandle = io.stdin
      stdinprocessed = true
    end

    local function abort (message)
      io.stderr:write ("ERROR: " .. message .. "\n")
      if (io.type (dmpfilehandle) == "file" and dmpfilehandle ~= io.stdin) then
        dmpfilehandle:close()
      end
      os.exit (1)
    end

    if not dmpfilehandle then
      abort ("Failed to open file '" .. dmpfile .. "'.")
    end

    local dmpversion = string.byte (dmpfilehandle:read (1))

    --Check DefleMask file version; currently targeting only formats 10 & 11
    if (dmpversion ~= 0x0a and dmpversion ~= 0x0b) then
      abort (string.format (
        "File version mismatch. Expected 10 or 11 (0x0a/0x0b), got %d (0x%02x)",
        dmpversion, dmpversion
      ))
    end
										
    --File format 11 specifies target sound system; file format 10 doesn't.
    local dmpsystem = 0x02  --Assume default value if format 10
    if (dmpversion == 0x0b) then
      dmpsystem = string.byte (dmpfilehandle:read (1))
      --Check target system: only YM2612 (2) and YM2151 (8) systems supported
      if (dmpsystem ~= 0x02 and dmpsystem ~= 0x08) then
        abort (string.format (
          "System mismatch. Expecting 2 or 8 (0x02/0x08), got %d (0x%02x).",
          dmpsystem, dmpsystem
        ))
      end
    end

    local dmptype = string.byte (dmpfilehandle:read (1))

    --Check instrument type; we are only interested in FM instruments (type 1)
    if (dmptype ~= 0x01) then
      abort (string.format (
        "Instrument type mismatch. Expecting 1 (0x01), got %d (0x%02x).",
        dmptype, dmptype
      ))
    end

    --Read instrument parameters LFO, FB, ALG, & LFO2
    local dmpLFO  = string.byte (dmpfilehandle:read (1))
    local dmpFB   = string.byte (dmpfilehandle:read (1))
    local dmpALG  = string.byte (dmpfilehandle:read (1))
    local dmpLFO2 = string.byte (dmpfilehandle:read (1))
    --PMDMML only allows FB & ALG in instrument patches; LFO & LFO2 are ignored.
    print ("; nm  ag  fb")
    print (string.format ("@%03d %03d %03d", n, dmpALG, dmpFB))

    --Number of FM operators
    --YM2612 (SMD) & YM2151 are four-operator chips.
    local dmpNumSlots = 4
    --List of FM operator slots to be populated
    local dmpFMOPslot = {}
    --YM2612 SSG-EG status flag
    local dmpHasSSGEG = false

    for i=1,dmpNumSlots do
      --[[
        Each DMP FM operator has the following parameters defined in this order:
        MULT:  %d
        TL:    %d
        AR:    %d
        DR:    %d
        SL:    %d
        RR:    %d
        AM:    %d
        RS:    %d
        DT:    %d
        D2R:   %d
        SSGEG: %d
      ]]
      local dmpOPar = {}
      --Read FM operator parameters MULT to SSGEG for each operator slot
      dmpOPar.MULT   = string.byte (dmpfilehandle:read (1))
      dmpOPar.TL     = string.byte (dmpfilehandle:read (1))
      dmpOPar.AR     = string.byte (dmpfilehandle:read (1))
      dmpOPar.DR     = string.byte (dmpfilehandle:read (1))
      dmpOPar.SL     = string.byte (dmpfilehandle:read (1))
      dmpOPar.RR     = string.byte (dmpfilehandle:read (1))
      dmpOPar.AM     = string.byte (dmpfilehandle:read (1))
      dmpOPar.RS     = string.byte (dmpfilehandle:read (1))
      dmpOPar.DT     = string.byte (dmpfilehandle:read (1))
      dmpOPar.D2R    = string.byte (dmpfilehandle:read (1))
      dmpOPar.SSGEG  = string.byte (dmpfilehandle:read (1))
      --Enable SSG-EG status flag if at least one SSGEG parameter is nonzero
      if (dmpOPar.SSGEG > 0) then dmpHasSSGEG = true
      end
      --Write FM operator parameters to selected slot
      dmpFMOPslot[i] = dmpOPar
    end

    dmpfilehandle:close()

    --[[
      DefleMask FM operators are defined in slot order 1, 3, 2, 4, but
      in PMDMML FM operators are defined in slot order 1, 2, 3, 4.
      Also, DefleMask muxes DT/DT2 parameters for YM2151 into a single DT field;
      we must demux both params using bitwise-AND & right-shift operations.
    ]]
    local opOrder = {1, 3, 2, 4}
    if (dmpsystem == 0x08) then
      --PMD68 MML instruments for YM2151
      print ("; ar  dr  sr  rr  sl  tl  ks  ml  dt dt2 ams")
      for _, op in ipairs (opOrder) do
        print (string.format (
          " %03d %03d %03d %03d %03d %03d %03d %03d %03d %03d %03d",
          dmpFMOPslot[op]["AR"],dmpFMOPslot[op]["DR"],dmpFMOPslot[op]["D2R"],
          dmpFMOPslot[op]["RR"],dmpFMOPslot[op]["SL"],dmpFMOPslot[op]["TL"],
          dmpFMOPslot[op]["RS"],dmpFMOPslot[op]["MULT"],
          dmpFMOPslot[op]["DT"]&0x0F,dmpFMOPslot[op]["DT"]>>4,
          dmpFMOPslot[op]["AM"]
        ))
      end
    else
      --PMD88 & PMD98 MML instruments for YM2203 & YM2608;
      --also PMDTOWNS MML instruments for YM2612

      --SSGEG parameter is not defined in MML instrument patches per se,
      --so if detected, print it instead as a side comment for each slot.
      if (dmpHasSSGEG) then
        print ("; ar  dr  sr  rr  sl  tl  ks  ml  dt ams ;seg")
        for _, op in ipairs (opOrder) do
          print (string.format (
            " %03d %03d %03d %03d %03d %03d %03d %03d %03d %03d ;%03d",
            dmpFMOPslot[op]["AR"],dmpFMOPslot[op]["DR"],dmpFMOPslot[op]["D2R"],
            dmpFMOPslot[op]["RR"],dmpFMOPslot[op]["SL"],dmpFMOPslot[op]["TL"],
            dmpFMOPslot[op]["RS"],dmpFMOPslot[op]["MULT"],
            dmpFMOPslot[op]["DT"],dmpFMOPslot[op]["AM"],dmpFMOPslot[op]["SSGEG"]
          ))
        end
      else
        print ("; ar  dr  sr  rr  sl  tl  ks  ml  dt ams")
        for _, op in ipairs (opOrder) do
          print (string.format (
            " %03d %03d %03d %03d %03d %03d %03d %03d %03d %03d",
            dmpFMOPslot[op]["AR"],dmpFMOPslot[op]["DR"],dmpFMOPslot[op]["D2R"],
            dmpFMOPslot[op]["RR"],dmpFMOPslot[op]["SL"],dmpFMOPslot[op]["TL"],
            dmpFMOPslot[op]["RS"],dmpFMOPslot[op]["MULT"],
            dmpFMOPslot[op]["DT"],dmpFMOPslot[op]["AM"]
          ))
        end
      end
    end

    print()
  end
end

os.exit (0)
