FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Non-root user. It must own /app because SQLite writes db.sqlite3 there.
RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

# Demo setup: migrate on start (SQLite is recreated whenever the task is replaced), then serve.
CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn storage.wsgi:application --bind 0.0.0.0:8000 --workers 2"]
