FROM cgr.dev/chainguard/jre:latest

WORKDIR /app

COPY graphhopper-web-*.jar app.jar
COPY graphhopper.yml config.yml

EXPOSE 8989 8990

CMD ["-Xmx4g", "-jar", "app.jar", "server", "config.yml"]