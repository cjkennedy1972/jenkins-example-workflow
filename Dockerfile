FROM alpine:latest

RUN apk add bash
COPY jenkins/run-tests.sh jenkins/
RUN chmod +x jenkins/run-tests.sh
