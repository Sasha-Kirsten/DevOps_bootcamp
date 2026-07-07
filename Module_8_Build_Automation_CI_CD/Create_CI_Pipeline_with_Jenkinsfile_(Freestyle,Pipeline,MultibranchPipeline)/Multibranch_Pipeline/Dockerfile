FROM amazoncorretto:17-alpine-jdk

EXPOSE 8080

COPY ./target/app-*.jar /usr/app/
WORKDIR /usr/app

ENTRYPOINT ["java", "-jar", "app-1.0-SNAPSHOT.jar"]