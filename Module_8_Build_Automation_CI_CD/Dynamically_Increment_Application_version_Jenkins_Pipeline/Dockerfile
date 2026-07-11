FROM amazoncorretto:21-alpine

EXPOSE 8080

COPY ./target/java-maven-app-*.jar /usr/app/app.jar
WORKDIR /usr/app

ENTRYPOINT ["java", "-jar", "app.jar"]