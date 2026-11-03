FROM amazoncorretto:21-alpine

EXPOSE 8080 

COPY ./target/java-maven-app-*.jar /usr/app/app.jar
WORKDIR /usr/app

CMD java -jar java-maven-app-*.jar 

