# --- Build stage -------------------------------------------------------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /workspace

# Cache dependencies separately from source so a source-only change doesn't
# force re-downloading the whole dependency tree.
COPY pom.xml .
RUN mvn -q -B dependency:go-offline || true

COPY src/ src/
RUN mvn -q -B clean package -DskipTests

# --- Run stage -----------------------------------------------------------
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN useradd --system --create-home appuser && mkdir -p /app/uploads && chown appuser:appuser /app/uploads
USER appuser

COPY --from=build /workspace/target/caffora-backend.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
