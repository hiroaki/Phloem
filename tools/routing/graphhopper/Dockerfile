FROM cgr.dev/chainguard/jre:latest

WORKDIR /app

COPY graphhopper-web-*.jar app.jar
COPY graphhopper-main.yml config-main.yml
COPY graphhopper-lite.yml config-lite.yml

EXPOSE 8989 8990

# Chiyoda-ku - minimal memory footprint for testing and development
CMD ["-Xmx48m", "-jar", "app.jar", "server", "config-lite.yml"]
# The 23 special wards of Tokyo - moderate memory footprint for more realistic routing
#CMD ["-Xmx96m", "-jar", "app.jar", "server", "config-main.yml"]
# Kanto region - larger memory footprint for more complex routing
#CMD ["-Xmx4g", "-jar", "app.jar", "server", "config-main.yml"]
