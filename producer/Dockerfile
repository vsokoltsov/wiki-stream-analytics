FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VENV_PATH=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

RUN pip install --no-cache-dir -U pip \
 && pip install --no-cache-dir uv \
 && python -m venv "$VENV_PATH"

SHELL ["/bin/bash", "-lc"]

COPY pyproject.toml /app/pyproject.toml
COPY uv.lock /app/uv.lock

RUN uv pip compile --group producer --group dev /app/pyproject.toml -o /tmp/req.txt \
# 2) ставим ИМЕННО в /opt/venv
 && uv pip install --python /opt/venv/bin/python --no-cache-dir -r /tmp/req.txt \
# 3) проверка
 && /opt/venv/bin/python -c "import aiohttp; import aiokafka; print('deps ok')"

# твой файл (по логам он /app/app.py — оставлю так)
COPY producer/app.py /app/producer/app.py
COPY producer/settings.py /app/producer/settings.py

CMD ["python", "-m", "producer.app"]