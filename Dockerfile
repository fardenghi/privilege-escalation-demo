FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalar utilidades esenciales para la demo y el análisis
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    findutils \
    procps \
    file \
    curl \
    wget \
    vim \
    nano \
    sudo \
    less \
    iproute2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Crear el usuario no privilegiado 'alumno' (UID 1000) acorde al PDF de la cátedra
RUN useradd -m -u 1000 -s /bin/bash alumno && \
    echo "alumno:alumno" | chpasswd

# Crear un archivo de prueba en /root con permisos estrictos (600) para verificar acceso elevado en la demo
RUN echo "CONFIDENCIAL: Demostración exitosa de escalamiento de privilegios (Caso 1 - SUID)" > /root/prueba_admin.txt && \
    chmod 600 /root/prueba_admin.txt

# Configuración del Caso 1 (PDF sección 4.1):
# Asignar el bit SUID al binario /usr/bin/find (permisos resultantes: -rwsr-xr-x)
RUN chmod u+s /usr/bin/find

# Copiar linpeas.sh al directorio de inicio de alumno para la auditoría automatizada
COPY tools/linpeas.sh /home/alumno/linpeas.sh
RUN chmod +x /home/alumno/linpeas.sh && \
    chown alumno:alumno /home/alumno/linpeas.sh

# Crear una configuración errónea de SUDOers para poder ejecutar vim con sudo (como root -> escape con :terminal)
RUN echo "alumno ALL=(ALL) NOPASSWD: /usr/bin/vim" > /etc/sudoers.d/alumno \
	&& echo "alumno ALL=(ALL) NOPASSWD: /usr/bin/cat" >> /etc/sudoers.d/alumno \
	&& echo "alumno ALL=(ALL) NOPASSWD: /usr/bin/echo" >> /etc/sudoers.d/alumno \
    && chmod 0440 /etc/sudoers.d/alumno


# Establecer usuario y directorio de trabajo por defecto
USER alumno
WORKDIR /home/alumno

CMD ["/bin/bash"]
