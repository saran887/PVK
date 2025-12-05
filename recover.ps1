$blobs = Get-Content D:\pkv2\blobs.txt
$recovered = 0

foreach ($blob in $blobs) {
    try {
        $content = git cat-file -p $blob 2>$null
        if ($content -match "^import|^library|^part of|^class |^enum |^mixin ") {
            # This looks like a Dart source file
            # Try to determine filename from imports or class names
            if ($content -match "file:///D:/pkv2/lib/(.+\.dart)") {
                $filepath = "D:\pkv2\lib\" + $matches[1]
                $dir = Split-Path -Parent $filepath
                if (!(Test-Path $dir)) {
                    New-Item -ItemType Directory -Path $dir -Force | Out-Null
                }
                $content | Out-File -FilePath $filepath -Encoding UTF8
                Write-Host "Recovered: $filepath"
                $recovered++
            }
        }
    }
    catch {
        # Skip errors
    }
}

Write-Host "Total files recovered: $recovered"
