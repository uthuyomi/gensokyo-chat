Param(
  [Parameter(Mandatory=$true)][string]$Job,
  [Parameter(Mandatory=$false)][string]$Input,
  [Parameter(Mandatory=$false)][string]$Output
)

$ErrorActionPreference = "Stop"

function Resolve-BlenderExe {
  if ($env:BLENDER_EXE -and (Test-Path -LiteralPath $env:BLENDER_EXE)) {
    return $env:BLENDER_EXE
  }

  $candidates = @(
    "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
    "C:\Program Files\Blender Foundation\Blender\blender.exe"
  )

  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }

  throw "BLENDER_EXE が未設定か blender.exe が見つかりません。`$env:BLENDER_EXE` に blender.exe のフルパスを設定してください。"
}

function Parse-ArgsFallback {
  Param([string[]]$Rest)
  $out = @{
    Input = $null
    Output = $null
  }

  for ($i = 0; $i -lt $Rest.Length; $i++) {
    $k = $Rest[$i]
    if ($k -in @("--input","-i","-Input")) {
      if ($i + 1 -lt $Rest.Length) { $out.Input = $Rest[$i + 1]; $i++; continue }
    }
    if ($k -in @("--output","-o","-Output")) {
      if ($i + 1 -lt $Rest.Length) { $out.Output = $Rest[$i + 1]; $i++; continue }
    }
  }
  return $out
}

if (-not $Input -or -not $Output) {
  $parsed = Parse-ArgsFallback -Rest $args
  if (-not $Input) { $Input = $parsed.Input }
  if (-not $Output) { $Output = $parsed.Output }
}

if (-not $Input) { throw "input is required. Use: --input <path> (or -Input <path>)" }
if (-not $Output) { throw "output is required. Use: --output <path> (or -Output <path>)" }

$blender = Resolve-BlenderExe
$root = Resolve-Path (Join-Path $PSScriptRoot "..\\..") | Select-Object -ExpandProperty Path
$jobPy = Join-Path $PSScriptRoot ("jobs\" + $Job + ".py")

if (-not (Test-Path -LiteralPath $jobPy)) {
  throw "Unknown job '$Job'. Expected: scan or idle. Missing file: $jobPy"
}

Write-Host "[blender] exe: $blender"
Write-Host "[blender] job: $Job"
Write-Host "[blender] input: $Input"
Write-Host "[blender] output: $Output"

$absInput = Join-Path $root $Input
$absOutput = Join-Path $root $Output

if (-not (Test-Path -LiteralPath $absInput)) {
  throw "Input not found: $absInput"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $absOutput) | Out-Null

& $blender --background --factory-startup --python $jobPy -- --input $absInput --output $absOutput
