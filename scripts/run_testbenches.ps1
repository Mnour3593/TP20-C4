# Requires: iverilog, vvp, and gtkwave available in PATH
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "src"
$gtkwaveDir = Join-Path $root "scripts\gtkwave"
$gtkwaveCounter = Join-Path $gtkwaveDir "tb_counter.gtkw"
$gtkwaveSequence = Join-Path $gtkwaveDir "tb_sequence_detector.gtkw"

Push-Location $src
try {
    $iverilog = "iverilog"
    $vvp = "vvp"
    $gtkwave = "gtkwave"

    & $iverilog -g2012 -s tb_counter -o tb_counter.vvp tb_counter.v universal_counter.v
    & $vvp tb_counter.vvp
    Start-Process -NoNewWindow -FilePath $gtkwave -ArgumentList @("-a", $gtkwaveCounter, "tb_counter.vcd")

    & $iverilog -g2012 -s tb_sequence_detector -o tb_sequence_detector.vvp tb_sequence_detector.v sequence_detector.v
    & $vvp tb_sequence_detector.vvp
    Start-Process -NoNewWindow -FilePath $gtkwave -ArgumentList @("-a", $gtkwaveSequence, "tb_sequence_detector.vcd")
}
finally {
    Pop-Location
}
