# syntax=docker/dockerfile:1.4

# ---------- Builder Stage ----------
FROM python:3.11.9-slim AS builder
WORKDIR /app

# Install build dependencies (if any) and the application requirements
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-warn-script-location --prefix=/install -r requirements.txt

# ---------- Runtime Stage ----------
FROM python:3.11.9-slim AS runtime
WORKDIR /app

# Create a non‑root user
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup --uid 1000 appuser

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY app.py .

# Set environment variables (defaults can be overridden at runtime)
ENV APP_NAME="myapp-take-home-assignment" \
    VERSION="1.0.0" \
    PORT=8080

# Use non‑root user to run the app
USER appuser

EXPOSE 8080
CMD ["python", "app.py"]
