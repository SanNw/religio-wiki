# Trust Gateway -- Fase 2 do sistema anti-bot (ver
# scratch/religio-antibot-trust-gateway.html). Diferente de citoid/zotero
# (serviços externos clonados de um repositório upstream), este é código
# PRÓPRIO do projeto: builda o TypeScript deste diretório e roda o servidor
# compilado. Sem porta publicada pro host/internet -- só o mediawiki fala com
# ele, pelo nome do serviço Docker (ver docker-compose.yml e
# AntiBotPreAuthenticationProvider.php).
FROM node:20-slim AS build

WORKDIR /srv/trust-gateway

COPY package.json tsconfig.json ./
RUN npm install

COPY src ./src
RUN npm run build

FROM node:20-slim

WORKDIR /srv/trust-gateway

COPY package.json ./
RUN npm install --omit=dev

COPY --from=build /srv/trust-gateway/dist ./dist
COPY migrations ./migrations

EXPOSE 3001

CMD [ "node", "dist/main.js" ]
