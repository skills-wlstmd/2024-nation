FROM python:3.12-alpine

COPY . .
RUN pip3 install -r requirements.txt
EXPOSE 8080

CMD ["python3", "main.py"]