FROM decolua/9router:0.4.46

COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

USER root

RUN apk add --no-cache rclone

USER node

EXPOSE 20128

ENTRYPOINT ["sh", "/app/entrypoint.sh"]