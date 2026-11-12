$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($PSScriptRoot)
$prefix = 'http://127.0.0.1:8765/'
$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Start-Process $prefix
    Write-Host "Site aberto em $prefix. Feche esta janela para encerrar o servidor."

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
        if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }

        $file = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $file.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            $context.Response.StatusCode = 403
            $context.Response.Close()
            continue
        }

        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            $context.Response.StatusCode = 404
            $context.Response.Close()
            continue
        }

        $context.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
        $context.Response.Headers["Pragma"] = "no-cache"
        $context.Response.ContentType = switch ([IO.Path]::GetExtension($file).ToLowerInvariant()) {
            '.html' { 'text/html; charset=utf-8' }
            '.jpg'  { 'image/jpeg' }
            '.jpeg' { 'image/jpeg' }
            '.png'  { 'image/png' }
            '.svg'  { 'image/svg+xml' }
            '.css'  { 'text/css; charset=utf-8' }
            '.js'   { 'text/javascript; charset=utf-8' }
            default { 'application/octet-stream' }
        }
        $bytes = [IO.File]::ReadAllBytes($file)
        $context.Response.ContentLength64 = $bytes.Length
        $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $context.Response.Close()
    }
}
finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
}
