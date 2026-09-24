FROM dart:stable AS build

WORKDIR /app
COPY server.dart ./
RUN dart compile exe server.dart -o server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/bin/

EXPOSE 8080
CMD ["/app/bin/server"]