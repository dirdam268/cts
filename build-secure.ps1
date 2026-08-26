param(
  [Parameter(Mandatory=$true)][string]$Password,
  [string]$Src = "index-src.html",
  [string]$Out = "index.html"
)
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$srcPath = Join-Path $dir $Src

# 1) Leer la app en claro y anteponer un sello para verificar el descifrado
$plainBytes = [System.IO.File]::ReadAllBytes($srcPath)
$sentinel = [System.Text.Encoding]::UTF8.GetBytes("FRQ_OK|")
$data = New-Object byte[] ($sentinel.Length + $plainBytes.Length)
[Array]::Copy($sentinel, 0, $data, 0, $sentinel.Length)
[Array]::Copy($plainBytes, 0, $data, $sentinel.Length, $plainBytes.Length)

# 2) Derivar clave (PBKDF2-SHA256) y cifrar (AES-256-CBC)
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = New-Object byte[] 16; $rng.GetBytes($salt)
$iv   = New-Object byte[] 16; $rng.GetBytes($iv)
$iter = 100000
$kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, $iter, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$key = $kdf.GetBytes(32)
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize = 256; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'; $aes.Key = $key; $aes.IV = $iv
$encryptor = $aes.CreateEncryptor()
$ct = $encryptor.TransformFinalBlock($data, 0, $data.Length)

$payload = @{
  v = 1; iter = $iter
  salt = [Convert]::ToBase64String($salt)
  iv   = [Convert]::ToBase64String($iv)
  ct   = [Convert]::ToBase64String($ct)
} | ConvertTo-Json -Compress

# 3) Pantalla de acceso (descifra en el navegador con Web Crypto)
$gate = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Franquicias cláusula a cláusula</title>
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#7d2a2f">
<meta name="robots" content="noindex, nofollow">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Franquicias">
<link rel="icon" href="icons/favicon-32.png" sizes="32x32">
<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Spectral:wght@500;600&family=IBM+Plex+Sans:wght@400;500&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
  :root{
    --paper:#f6f5f1; --surface:#fffefb; --ink:#191b1a; --ink2:#5b5f5c; --ink3:#8b8f8a;
    --rule:#dcd9d0; --accent:#7d2a2f;
    --serif:"Spectral",Georgia,serif;
    --sans:"IBM Plex Sans",-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
    --mono:"IBM Plex Mono",ui-monospace,Consolas,monospace;
  }
  @media (prefers-color-scheme:dark){
    :root{ --paper:#14161a; --surface:#1b1e23; --ink:#ecebe5; --ink2:#a7aba7; --ink3:#7b807e;
           --rule:#2f343b; --accent:#e09a90; }
  }
  *{box-sizing:border-box; margin:0; padding:0}
  body{
    font-family:var(--sans); background:var(--paper); color:var(--ink);
    min-height:100vh; display:flex; align-items:center; justify-content:center; padding:20px;
  }
  .gate{
    background:var(--surface); border:1px solid var(--rule); border-radius:3px;
    padding:36px 30px; width:100%; max-width:380px;
    border-top:3px solid var(--accent);
  }
  .eyebrow{
    font-family:var(--mono); font-size:10.5px; text-transform:uppercase; letter-spacing:.12em;
    color:var(--ink3); margin-bottom:10px;
  }
  h1{
    font-family:var(--serif); font-weight:600; font-size:27px; line-height:1.15;
    letter-spacing:-.02em; margin-bottom:8px;
  }
  .sub{font-size:13.5px; color:var(--ink2); margin-bottom:26px; line-height:1.5}
  label{
    display:block; font-family:var(--mono); font-size:10.5px; text-transform:uppercase;
    letter-spacing:.1em; color:var(--ink3); margin-bottom:7px;
  }
  input{
    width:100%; border:1px solid var(--rule); border-radius:2px; background:var(--paper);
    color:var(--ink); padding:12px 14px; font-family:var(--sans); font-size:16px;
    outline:none; margin-bottom:14px;
  }
  input:focus{border-color:var(--accent)}
  button{
    width:100%; background:var(--accent); border:0; color:#fffefb; border-radius:2px;
    padding:13px; font-family:var(--mono); font-weight:500; font-size:12px;
    text-transform:uppercase; letter-spacing:.12em; cursor:pointer;
  }
  button:disabled{opacity:.55; cursor:default}
  .err{color:var(--accent); font-size:13px; font-weight:500; margin-top:14px; min-height:18px}
  .foot{
    margin-top:24px; padding-top:18px; border-top:1px solid var(--rule);
    font-size:11.5px; color:var(--ink3); line-height:1.6;
  }
  .foot a{color:var(--accent); font-weight:500; text-decoration:none}
</style>
</head>
<body>
<div class="gate">
  <div class="eyebrow">Documentación reservada</div>
  <h1>Franquicias cláusula a cláusula</h1>
  <div class="sub">Condiciones contractuales de las enseñas de supermercado. Acceso restringido.</div>
  <label for="pw">Contraseña</label>
  <input id="pw" type="password" autocomplete="current-password" autofocus>
  <button id="go">Entrar</button>
  <div class="err" id="err"></div>
  <div class="foot">¿Olvidaste la contraseña?<br><a href="mailto:bordetass@gmail.com?subject=Acceso%20Franquicias">Escribe a bordetass@gmail.com</a></div>
</div>
<script>
const PAYLOAD = __PAYLOAD__;
const b64 = s => Uint8Array.from(atob(s), c => c.charCodeAt(0));

async function decryptApp(password) {
  const salt = b64(PAYLOAD.salt), iv = b64(PAYLOAD.iv), ct = b64(PAYLOAD.ct);
  const km = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey']);
  const key = await crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations: PAYLOAD.iter, hash: 'SHA-256' },
    km, { name: 'AES-CBC', length: 256 }, false, ['decrypt']
  );
  const buf = await crypto.subtle.decrypt({ name: 'AES-CBC', iv }, key, ct);
  const text = new TextDecoder().decode(buf);
  if (!text.startsWith('FRQ_OK|')) throw new Error('sello');
  return text.slice(7);
}

async function enter() {
  const btn = document.getElementById('go');
  const err = document.getElementById('err');
  const pw = document.getElementById('pw').value;
  if (!pw) { err.textContent = 'Introduce la contraseña.'; return; }
  btn.disabled = true; err.textContent = 'Descifrando…';
  try {
    const html = await decryptApp(pw);
    // Recordar en este dispositivo: solo se pide la primera vez
    try { localStorage.setItem('frq_pw', pw); } catch(_) {}
    document.open(); document.write(html); document.close();
  } catch (e) {
    try { localStorage.removeItem('frq_pw'); } catch(_) {}
    err.textContent = 'Contraseña incorrecta.';
    btn.disabled = false;
  }
}

document.getElementById('go').addEventListener('click', enter);
document.getElementById('pw').addEventListener('keydown', e => { if (e.key === 'Enter') enter(); });

// Si ya se validó antes en este dispositivo, entrar directo sin preguntar
const saved = (() => { try { return localStorage.getItem('frq_pw'); } catch(_) { return null; } })();
if (saved) {
  document.getElementById('pw').value = saved;
  enter();
}

// Permite instalar la app en el escritorio o en el móvil
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(()=>{}));
}
</script>
</body>
</html>
'@

$gate = $gate.Replace('__PAYLOAD__', $payload)
$outPath = Join-Path $dir $Out
[System.IO.File]::WriteAllText($outPath, $gate, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("OK -> {0} generado. Datos cifrados: {1} KB" -f $Out, [math]::Round($ct.Length/1024))
