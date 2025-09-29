FROM python:3.11-slim AS base
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
COPY pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir .[dev]
COPY src ./src


# runtime image
FROM python:3.11-slim
WORKDIR /app
ENV APP_VERSION=0.1.0 \
    APP_ENV=container
RUN useradd -m nonroot
COPY --from=base /usr/local /usr/local
COPY --from=base /app/src /app/src
USER nonroot
EXPOSE 8080
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]