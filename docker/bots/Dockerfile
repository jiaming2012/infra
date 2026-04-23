FROM python:3.12-slim

WORKDIR /app

# Install dependencies first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Each bot is identified by BOT_NAME env var
CMD ["python", "-u", "main.py"]
