FROM python:3.11-alpine
WORKDIR /app
COPY ./src/app.py .
RUN pip3 install --no-cache-dir flask gunicorn &&  apk add --no-cache curl && rm -rf /root/.cache/
EXPOSE 8080
CMD ["python3", "app.py"]