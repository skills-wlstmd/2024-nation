FROM python:3.12-alpine
WORKDIR /app
COPY app.py .
RUN pip3 install --no-cache-dir flask gunicorn &&  apk add --no-cache curl && rm -rf /root/.cache/ && mkdir /logs
EXPOSE 8080
CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0", "--port=8080"]