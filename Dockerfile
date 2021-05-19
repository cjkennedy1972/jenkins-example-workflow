FROM alpine:latest

ENV USER=jenkins
ENV UID=1000
ENV GID=1000

RUN addgroup --gid $GID $USER && adduser \
  --disabled-password \
  --gecos "" \
  --home /home/$USER \
  --ingroup $USER \
  --uid $UID \
  $USER

RUN apk add bash
WORKDIR /home/jenkins
COPY jenkins/run-tests.sh jenkins/
RUN chmod +x jenkins/run-tests.sh

USER jenkins
