# ---- Build Stage ----
FROM maven:3.9-amazoncorretto-21-alpine AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# ---- Run Stage ----
FROM amazoncorretto:21-alpine
WORKDIR /app
EXPOSE 8080
COPY --from=build /app/target/app.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
