Param(
  [int]$Port = 8080
)
$root = (Get-Location).Path
$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)
try {
  $listener.Start()
  Write-Host "Serving $root at $prefix"
} catch {
  Write-Host "Failed to start listener: $($_.Exception.Message)"
  exit 1
}
while ($true) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    $path = $req.Url.AbsolutePath
    if ($path -eq "/") { $path = "/index.html" }
    $local = Join-Path $root ($path.TrimStart('/').Replace('/','\'))
    if (Test-Path $local) {
      try {
        $bytes = [System.IO.File]::ReadAllBytes($local)
        switch ([System.IO.Path]::GetExtension($local).ToLower()) {
          ".html" { $res.ContentType = "text/html; charset=utf-8" }
          ".css"  { $res.ContentType = "text/css; charset=utf-8" }
          ".js"   { $res.ContentType = "application/javascript; charset=utf-8" }
          ".json" { $res.ContentType = "application/json; charset=utf-8" }
          ".svg"  { $res.ContentType = "image/svg+xml" }
          ".png"  { $res.ContentType = "image/png" }
          ".jpg"  { $res.ContentType = "image/jpeg" }
          ".jpeg" { $res.ContentType = "image/jpeg" }
          ".woff2" { $res.ContentType = "font/woff2" }
          Default { $res.ContentType = "application/octet-stream" }
        }
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
      } catch {
        $res.StatusCode = 500
        $msg = [System.Text.Encoding]::UTF8.GetBytes($_.Exception.Message)
        $res.OutputStream.Write($msg, 0, $msg.Length)
      }
    } else {
      $res.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
      $res.OutputStream.Write($msg, 0, $msg.Length)
    }
    $res.OutputStream.Close()
  } catch {
    Write-Host $_.Exception.Message
  }
}
