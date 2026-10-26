# TODO(supply-chain): Pin this base image by a reviewed digest and rebuild regularly for OS security fixes.
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./
# TODO(supply-chain): Generate and enforce a hashed dependency lock file; scan the resulting image in CI before release.
RUN pip install --no-cache-dir -r requirements.txt \
    && addgroup --system app \
    && adduser --system --ingroup app app

COPY app.py ./
RUN chown -R app:app /app

USER app
# TODO(runtime): Run a production WSGI server, set a read-only root filesystem where feasible, and write temporary
# data only to an explicitly mounted writable path.
EXPOSE 8080

CMD ["python", "app.py"]
