FROM python:3.12

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
    postgresql-client netcat-openbsd libgl1 libglib2.0-0 wget git openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -q https://quarto.org/download/latest/quarto-linux-amd64.deb -O /tmp/quarto.deb && \
    dpkg -i /tmp/quarto.deb || apt-get -f install -y -qq && \
    rm /tmp/quarto.deb && apt-get clean

RUN pip install --no-cache-dir nbdev==2.4.14

WORKDIR /workspace

COPY build.sh /usr/local/bin/build.sh
COPY test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/build.sh /usr/local/bin/test.sh

ENTRYPOINT ["/usr/local/bin/build.sh"]

