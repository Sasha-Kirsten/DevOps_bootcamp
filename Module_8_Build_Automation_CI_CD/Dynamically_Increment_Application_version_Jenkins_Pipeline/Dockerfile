FROM amazoncorretto:21-alpine

COPY ./target/simple-maven-app-*.jar /usr/app/app.jar
WORKDIR /usr/app

ARG APP_VERSION=development
LABEL org.opencontainers.image.version=$APP_VERSION
ENV APP_VERSION=$APP_VERSION

ENTRYPOINT ["java", "-jar", "app.jar"]