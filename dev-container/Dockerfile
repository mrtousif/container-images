FROM docker.io/bitnami/node:22

WORKDIR /app

ADD install_tooling.sh .

RUN chmod +x install_tooling.sh && ./install_tooling.sh && rm install_tooling.sh
