FROM python:3.11.3

RUN apt-get update && \
    apt-get install -y jq postgresql-client netcat-openbsd libgl1 libglib2.0-0 wget git openssh-client chromium && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -q https://quarto.org/download/latest/quarto-linux-amd64.deb -O /tmp/quarto.deb && \
    dpkg -i /tmp/quarto.deb || apt-get -f install -y -qq && \
    rm /tmp/quarto.deb && apt-get clean

RUN pip install --no-cache-dir nbdev==3.0.10

WORKDIR /workspace

# --- core helper scripts ---
COPY scripts/install-fhemb.sh /usr/local/bin/install-fhemb.sh
COPY scripts/configure-ssh.sh /usr/local/bin/configure-ssh.sh
COPY scripts/setup-env.sh /usr/local/bin/setup-env.sh

# --- merged CI script ---
COPY scripts/ci-prepare.sh /usr/local/bin/ci-prepare.sh

RUN chmod +x \
    /usr/local/bin/install-fhemb.sh \
    /usr/local/bin/configure-ssh.sh \
    /usr/local/bin/setup-env.sh \
    /usr/local/bin/ci-prepare.sh

# --- build/test entry scripts ---
COPY scripts/build.sh /usr/local/bin/build.sh
COPY scripts/test.sh /usr/local/bin/test.sh

RUN chmod +x \
    /usr/local/bin/build.sh \
    /usr/local/bin/test.sh

# No ENTRYPOINT - scripts are called explicitly
