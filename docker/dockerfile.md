# VERSION AVEC QUALIMAP DEPUIS GITLAB
# Dockerfile pour environnement bioinformatique complet
# Auteur: Marwa ZIDI

FROM ubuntu:22.04

# Variables d'environnement
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/vep/ensembl-vep:${PATH}"

# ============================================================================
# 1. INSTALLATION DES DÉPENDANCES SYSTÈME DE BASE
# ============================================================================
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    openssl \
    curl \
    ca-certificates \
    wget \
    git \
    build-essential \
    unzip \
    procps \
    libncurses5-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    autoconf \
    automake \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 2. INSTALLATION DE NODE.JS
# ============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# ============================================================================
# 3. INSTALLATION DE PYTHON ET JUPYTER
# ============================================================================
RUN pip3 install --upgrade pip setuptools wheel
RUN npm install -g configurable-http-proxy
RUN pip3 install jupyterlab notebook

# ============================================================================
# 4. INSTALLATION DES PACKAGES PYTHON POUR BIOINFORMATIQUE
# ============================================================================
RUN pip3 install \
    biopython \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scipy \
    pysam \
    scikit-learn \
    plotly

# ============================================================================
# 5. INSTALLATION DES DÉPENDANCES PERL
# ============================================================================
RUN apt-get update && apt-get install -y \
    libdbi-perl \
    libdbd-mysql-perl \
    libarchive-zip-perl \
    perl \
    cpanminus \
    libmysqlclient-dev \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 5b. INSTALLATION DE HTSLIB (pour Bio::DB::HTS)
# ============================================================================
RUN cd /tmp && \
    wget https://github.com/samtools/htslib/releases/download/1.21/htslib-1.21.tar.bz2 && \
    tar -xjf htslib-1.21.tar.bz2 && \
    cd htslib-1.21 && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    cd /tmp && rm -rf htslib-1.21*

RUN ldconfig

# ============================================================================
# 5c. INSTALLATION DES MODULES PERL
# ============================================================================
RUN cpanm --notest Archive::Zip DBI
RUN cpanm --notest Bio::DB::HTS || echo "Bio::DB::HTS installation échouée - VEP fonctionnera en mode réduit"
RUN cpanm --notest DBD::mysql || echo "DBD::mysql installation échouée - fonctionnalité MySQL non disponible"

# ============================================================================
# 6. INSTALLATION DE JAVA (OpenJDK 25)
# ============================================================================
RUN apt-get update && apt-get install -y \
    wget \
    fonts-dejavu \
    fonts-liberation \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    wget https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.tar.gz && \
    mkdir -p /opt/jdk && \
    tar -xzf jdk-25_linux-x64_bin.tar.gz -C /opt/jdk && \
    rm jdk-25_linux-x64_bin.tar.gz && \
    ln -s /opt/jdk/jdk-25* /opt/jdk/current

ENV JAVA_HOME=/opt/jdk/current
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ============================================================================
# 6b. INSTALLATION DE R 4.2.2
# ============================================================================
RUN apt-get update && apt-get install -y \
    dirmngr \
    gnupg \
    apt-transport-https \
    software-properties-common \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

RUN apt-get update && apt-get install -y r-base=4.2.2-1.2204.0 r-base-dev=4.2.2-1.2204.0 \
    || apt-get install -y r-base r-base-dev

RUN R -e "install.packages(c('readr', 'dplyr', 'tidyr', 'stringr'), repos='https://cran.rstudio.com/', version=c('2.1.5', '1.1.4', '1.3.1', '1.5.1'))" || \
    R -e "install.packages(c('readr', 'dplyr', 'tidyr', 'stringr'), repos='https://cran.rstudio.com/')"

RUN R -e "install.packages('BiocManager', repos='https://cran.rstudio.com/')" && \
    R -e "BiocManager::install('vcfR', version='1.15.0')" || \
    R -e "BiocManager::install('vcfR')"

# ============================================================================
# 6c. INSTALLATION DES KERNELS JUPYTER (R et Bash)
# ============================================================================
# Installation du kernel R pour Jupyter
RUN R -e "install.packages('IRkernel', repos='https://cran.rstudio.com/')" && \
    R -e "IRkernel::installspec(user = FALSE)"

# Installation du kernel Bash pour Jupyter
RUN pip3 install bash_kernel && \
    python3 -m bash_kernel.install

# ============================================================================
# 7. INSTALLATION DE BWA v0.7.17-r1188
# ============================================================================
RUN cd /tmp && \
    wget https://github.com/lh3/bwa/releases/download/v0.7.17/bwa-0.7.17.tar.bz2 && \
    tar -xjf bwa-0.7.17.tar.bz2 && \
    cd bwa-0.7.17 && \
    make CFLAGS="-g -Wall -Wno-unused-function -O2 -fcommon" && \
    cp bwa /usr/local/bin/ && \
    cd /tmp && rm -rf bwa-0.7.17*

# ============================================================================
# 8. INSTALLATION DE SAMTOOLS v1.21
# ============================================================================
RUN cd /tmp && \
    wget https://github.com/samtools/samtools/releases/download/1.21/samtools-1.21.tar.bz2 && \
    tar -xjf samtools-1.21.tar.bz2 && \
    cd samtools-1.21 && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    cd /tmp && rm -rf samtools-1.21*

# ============================================================================
# 9. INSTALLATION DE FASTQC v0.12.1
# ============================================================================
RUN cd /opt && \
    wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip && \
    unzip fastqc_v0.12.1.zip && \
    rm fastqc_v0.12.1.zip && \
    chmod +x /opt/FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc

# ============================================================================
# 10. INSTALLATION DE QUALIMAP v2.3 DEPUIS GITLAB
# ============================================================================
ARG GITLAB_QUALIMAP_URL="https://gitlab.dsi.universite-paris-saclay.fr/marwa.zidi/qualimap_v2.3/-/raw/main/qualimap_v2.3.zip?ref_type=heads&inline=false"

RUN cd /opt && \
    wget "${GITLAB_QUALIMAP_URL}" -O qualimap_v2.3.zip && \
    unzip qualimap_v2.3.zip && \
    rm qualimap_v2.3.zip && \
    chmod +x /opt/qualimap_v2.3/qualimap && \
    ln -s /opt/qualimap_v2.3/qualimap /usr/local/bin/qualimap

# ============================================================================
# 11. INSTALLATION DE VARSCAN v2.4.6
# ============================================================================
RUN mkdir -p /opt/varscan && \
    cd /opt/varscan && \
    wget https://github.com/dkoboldt/varscan/releases/download/v2.4.6/VarScan.v2.4.6.jar && \
    echo '#!/bin/bash\njava -jar /opt/varscan/VarScan.v2.4.6.jar "$@"' > /usr/local/bin/varscan && \
    chmod +x /usr/local/bin/varscan

# ============================================================================
# 12. INSTALLATION DE VEP v88.9
# ============================================================================
RUN cd /opt && \
    git clone https://github.com/Ensembl/ensembl-vep.git && \
    cd ensembl-vep && \
    git checkout release/88 && \
    perl INSTALL.pl --AUTO a --SPECIES homo_sapiens --ASSEMBLY GRCh38 --NO_UPDATE --NO_HTSLIB --NO_TEST

# ============================================================================
# 13. INSTALLATION DE VNC ET COMPOSANTS GRAPHIQUES
# ============================================================================
RUN apt-get update && apt-get install -y \
    x11vnc \
    xvfb \
    fluxbox \
    xterm \
    novnc \
    websockify \
    net-tools \
    tigervnc-standalone-server \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# 14. INSTALLATION D'IGV v2.16.2
# ============================================================================
RUN cd /opt && \
    wget https://data.broadinstitute.org/igv/projects/downloads/2.16/IGV_2.16.2.zip && \
    unzip IGV_2.16.2.zip && \
    rm IGV_2.16.2.zip && \
    chmod +x /opt/IGV_2.16.2/igv.sh

# ============================================================================
# 15. CONFIGURATION VNC
# ============================================================================
RUN mkdir -p /root/.vnc && \
    echo "BIOINFO" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# ============================================================================
# 16. CONFIGURATION DU MENU FLUXBOX
# ============================================================================
RUN mkdir -p /root/.fluxbox && \
    echo '[begin] (Fluxbox Menu)' > /root/.fluxbox/menu && \
    echo '    [exec] (Terminal) {xterm -bg black -fg white -fa "Monospace" -fs 12}' >> /root/.fluxbox/menu && \
    echo '    [exec] (IGV) {/opt/IGV_2.16.2/igv.sh}' >> /root/.fluxbox/menu && \
    echo '    [separator]' >> /root/.fluxbox/menu && \
    echo '    [submenu] (Applications)' >> /root/.fluxbox/menu && \
    echo '        [exec] (Terminal) {xterm}' >> /root/.fluxbox/menu && \
    echo '        [exec] (IGV) {/opt/IGV_2.16.2/igv.sh}' >> /root/.fluxbox/menu && \
    echo '    [end]' >> /root/.fluxbox/menu && \
    echo '    [separator]' >> /root/.fluxbox/menu && \
    echo '    [config] (Configuration)' >> /root/.fluxbox/menu && \
    echo '    [submenu] (Styles)' >> /root/.fluxbox/menu && \
    echo '        [stylesdir] (/usr/share/fluxbox/styles)' >> /root/.fluxbox/menu && \
    echo '    [end]' >> /root/.fluxbox/menu && \
    echo '    [separator]' >> /root/.fluxbox/menu && \
    echo '    [restart] (Restart)' >> /root/.fluxbox/menu && \
    echo '    [exit] (Exit)' >> /root/.fluxbox/menu && \
    echo '[end]' >> /root/.fluxbox/menu

# ============================================================================
# 17. Add data
# ============================================================================

RUN mkdir -p /data \
 && cd /data \
 && wget -qO - "https://filesender.renater.fr/download.php?token=4e63e984-11ff-4200-abcb-8db151559b97&files_ids=66356009" \
 | tar -xzv


# ============================================================================
# 18. COPIE DU WRAPPER SCRIPT
# ============================================================================
COPY wrapper_script.sh /usr/local/bin/wrapper_script.sh
RUN chmod +x /usr/local/bin/wrapper_script.sh

# ============================================================================
# 19. CONFIGURATION FINALE
# ============================================================================
EXPOSE 8888 6080

WORKDIR /root

# ============================================================================
# 20. POINT D'ENTRÉE
# ============================================================================
ENTRYPOINT ["/bin/bash", "/usr/local/bin/wrapper_script.sh"]
