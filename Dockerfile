FROM node:20

ENV PORT=20128
ARG BETTER_SQLITE3_VERSION=12.6.2

WORKDIR /root/.9router

RUN mkdir db runtime

# RUN cd runtime && npm install --no-save better-sqlite3@${BETTER_SQLITE3_VERSION}

RUN npm install -g 9router better-sqlite3@${BETTER_SQLITE3_VERSION}

EXPOSE 20128

ENTRYPOINT ["sh", "-c", "[ -f /etc/secrets/data.sqlite ] && cp /etc/secrets/data.sqlite ./db/data.sqlite; 9router"]