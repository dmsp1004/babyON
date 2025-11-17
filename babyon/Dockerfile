# Multi-stage build for Spring Boot application
FROM gradle:8.5-jdk17 AS build

WORKDIR /app

# Copy Gradle configuration files
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies
RUN gradle dependencies --no-daemon

# Copy source code
COPY src ./src

# Build the application
RUN gradle bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy the JAR file from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Expose application port
EXPOSE 8085

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

