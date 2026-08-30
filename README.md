# CTS

Herramienta interna de consulta. Se publica **cifrada**: el contenido íntegro
viaja dentro de un único payload AES-256-CBC con clave derivada por
PBKDF2-SHA256 (100.000 iteraciones), que el navegador descifra con Web Crypto
tras introducir la contraseña. La clave se recuerda por dispositivo en
`localStorage`, así que solo se pide la primera vez.

Es instalable como aplicación en escritorio y móvil.

## Cómo regenerar

1. Editar **`index-src.html`** (fuente en claro, no se sube al repositorio).
2. Cifrar:

```
powershell -ExecutionPolicy Bypass -File .\build-secure.ps1 -Password "LA_CONTRASEÑA"
```

Esto genera `index.html`, que es lo único que se publica.

Los iconos se regeneran con `gen-icons.ps1`.

> `index-src.html` y `datos.js` están en `.gitignore` a propósito: contienen el
> contenido en claro. No los subas nunca al repositorio.
