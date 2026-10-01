FROM python:3.12-alpine

WORKDIR /app

COPY src/ ./src/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_VERSION=development

RUN addgroup -S app && adduser -S app -G app

USER app

EXPOSE 8080

CMD ["python", "-m", "src.app"]
