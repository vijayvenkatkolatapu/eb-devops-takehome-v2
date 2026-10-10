FROM python:3.11.9-slim-bookworm AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11.9-slim-bookworm
WORKDIR /app
RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup --uid 1000 appuser
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup app.py .
ENV PORT=8080 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
USER appuser
EXPOSE 8080
CMD ["python", "-u", "app.py"]
