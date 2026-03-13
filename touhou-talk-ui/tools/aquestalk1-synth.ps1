param(
  [Parameter(Mandatory = $true)][string]$Text,
  [Parameter(Mandatory = $true)][int]$Speed,
  [Parameter(Mandatory = $true)][string]$Aqtk1DllDir,
  [Parameter(Mandatory = $true)][string]$Aqk2kDllDir,
  [Parameter(Mandatory = $true)][string]$Aqk2kDicDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Ensure stdout is UTF-8 so Node can decode JSON reliably.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (!(Test-Path -LiteralPath $Aqtk1DllDir)) { throw "aqtk1 dll dir not found: $Aqtk1DllDir" }
if (!(Test-Path -LiteralPath $Aqk2kDllDir)) { throw "aqk2k dll dir not found: $Aqk2kDllDir" }
if (!(Test-Path -LiteralPath $Aqk2kDicDir)) { throw "aqk2k dic dir not found: $Aqk2kDicDir" }

$env:PATH = "$Aqtk1DllDir;$Aqk2kDllDir;$env:PATH"

Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class AqKanji2Koe {
  [DllImport("AqKanji2Koe.dll", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Ansi)]
  public static extern IntPtr AqKanji2Koe_Create(string pathDic, out int err);

  [DllImport("AqKanji2Koe.dll", CallingConvention = CallingConvention.StdCall)]
  public static extern void AqKanji2Koe_Release(IntPtr h);

  [DllImport("AqKanji2Koe.dll", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Unicode)]
  public static extern int AqKanji2Koe_Convert_utf16(IntPtr h, string kanji, StringBuilder koe, int nBufKoe);
}

public static class AquesTalk {
  [DllImport("AquesTalk.dll", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Unicode)]
  public static extern IntPtr AquesTalk_Synthe_Utf16(string koe, int speed, out int size);

  [DllImport("AquesTalk.dll", CallingConvention = CallingConvention.StdCall)]
  public static extern void AquesTalk_FreeWave(IntPtr wav);
}

public static class AqTts {
  public static string ConvertToKoe(string text, string dicDir) {
    int err;
    IntPtr h = AqKanji2Koe.AqKanji2Koe_Create(dicDir, out err);
    if (h == IntPtr.Zero) throw new Exception("AqKanji2Koe_Create failed: " + err);
    try {
      var koe = new StringBuilder(16384);
      int rc = AqKanji2Koe.AqKanji2Koe_Convert_utf16(h, text, koe, koe.Capacity);
      if (rc != 0) throw new Exception("AqKanji2Koe_Convert_utf16 failed: " + rc);
      return koe.ToString();
    } finally {
      AqKanji2Koe.AqKanji2Koe_Release(h);
    }
  }

  public static string SynthesizeWavBase64FromKoe(string koe, int speed) {
    int size;
    IntPtr wav = AquesTalk.AquesTalk_Synthe_Utf16(koe, speed, out size);
    if (wav == IntPtr.Zero) throw new Exception("AquesTalk_Synthe_Utf16 failed: " + size);
    try {
      var bytes = new byte[size];
      Marshal.Copy(wav, bytes, 0, size);
      return Convert.ToBase64String(bytes);
    } finally {
      AquesTalk.AquesTalk_FreeWave(wav);
    }
  }
}
"@

$koe = [AqTts]::ConvertToKoe($Text, $Aqk2kDicDir)
$b64 = [AqTts]::SynthesizeWavBase64FromKoe($koe, $Speed)

$obj = [ordered]@{
  b64 = $b64
  koe = $koe
}

$json = $obj | ConvertTo-Json -Compress
[Console]::Write($json)
