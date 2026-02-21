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
 && uv pip install --python /opt/venv/bin/python --no-cache-dir -r /tmp/req.txt \
 && /opt/venv/bin/python -c "import aiohttp; import aiokafka; print('deps ok')"

COPY common/ /app/common/
COPY producer/ /app/producer/

CMD ["python", "-m", "producer.app"]