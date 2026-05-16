FROM decolua/9router

USER root

COPY sync_db.sh /app/sync_db.sh

RUN chmod +x /app/sync_db.sh

RUN apk add --no-cache rclone

USER node

EXPOSE 20128

ENTRYPOINT ["sh", "-c", "sh /app/sync_db.sh && node server.js"]