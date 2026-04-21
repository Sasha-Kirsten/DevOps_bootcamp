FROM eclipse-temurin:17-jdk

ENV MYSQL_ROOT_PASSWORD = rootpassword\
    MYSQL_USER = myuser\
    MYSQL_PASSWORD = rootpassword\
    PMA_HOST = host.docker.internal\
    PMA_PORT = 3306

RUN mkdir -p ./home/app

COPY . /home/app

WORKDIR /home/app

# RUN ./gradlew build -x test

EXPOSE 8080

CMD ["java", "-jar", "build/libs/docker-exercises.jar"]