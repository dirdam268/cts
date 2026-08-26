# Franquicias cláusula a cláusula

Comparador de las condiciones contractuales de las enseñas de supermercado
(Carrefour, DIA, Eroski, Caprabo, Coviran, Charter, SPAR, SUMA, Miquel, UNIDE,
Covalco, Condis, Simply City) extraídas de sus contratos, adendas y dossieres.

Tres vistas: fichas por enseña, comparador cruzado de 16 cláusulas y un buscador
por lenguaje natural sobre las cláusulas indexadas. Todo se resuelve en el
navegador: no hay servidor ni llamadas externas.

## Publicación

La aplicación se publica **cifrada**. El contenido íntegro (app + base de datos de
cláusulas) viaja dentro de un único payload AES-256-CBC con clave derivada por
PBKDF2-SHA256 (100.000 iteraciones), que el navegador descifra con Web Crypto tras
introducir la contraseña. La clave se recuerda por dispositivo en `localStorage`,
de modo que solo se pide la primera vez.

## Cómo regenerar

1. Editar **`index-src.html`** (fuente en claro, no se sube al repositorio).
2. Cifrar:

```
powershell -ExecutionPolicy Bypass -File .\build-secure.ps1 -Password "LA_CONTRASEÑA"
```

Esto genera `index.html`, que es lo único que se publica.

> `index-src.html` y `datos.js` están en `.gitignore` a propósito: contienen las
> cláusulas en claro. No los subas nunca al repositorio.
