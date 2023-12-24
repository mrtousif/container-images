FROM docker.io/bitnami/node:20

WORKDIR /app

RUN npm install -y typescript tsx

ADD install_tooling.sh .

RUN chmod +x install_tooling.sh && ./install_tooling.sh && rm install_tooling.sh
