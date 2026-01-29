FROM python:3.12

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
    postgresql-client netcat-openbsd libgl1 libglib2.0-0 wget git openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Quarto
RUN wget -q https://quarto.org/download/latest/quarto-linux-amd64.deb -O /tmp/quarto.deb && \
    dpkg -i /tmp/quarto.deb || apt-get -f install -y -qq && \
    rm /tmp/quarto.deb && \
    apt-get clean

# Install Python dependencies
RUN pip install --no-cache-dir nbdev==2.4.14

WORKDIR /workspace

COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

ENTRYPOINT ["/usr/local/bin/build.sh"]

