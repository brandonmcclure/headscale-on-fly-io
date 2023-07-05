FROM ghcr.io/juanfont/headscale:0.22.3
RUN mkdir /persistent

COPY config.yaml /etc/headscale/config.yaml

EXPOSE 8080/tcp 9090/tcp

CMD ["headscale","serve"]
