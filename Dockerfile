FROM ocaml/opam2:4.07

# Set home directory
ARG HOME=/home/opam

# Create working directory
WORKDIR $HOME/lama

# Copy files
COPY --chown=opam:opam . .

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure and build project
RUN    sudo apt-get update \
    && sudo apt-get install -y --no-install-recommends m4 gcc-multilib \
    && sudo rm -rf /var/lib/apt/lists/* \
    && echo "source $HOME/.opam/opam-init/init.sh &> /dev/null" >> $HOME/.bashrc \
    && eval $(opam env) \
    && opam pin add -n ostap https://github.com/sign5/ostap.git#memoCPS \
    && opam pin add -y lama https://github.com/JetBrains-Research/Lama.git \
    && sudo chown opam:opam $HOME/lama \
    && make install \
    && opam clean

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# Set home as working directory
WORKDIR $HOME

