FROM alpine:latest

RUN apk add --no-cache aws-cli curl ffmpeg jq libc6-compat sudo \
  && rm -rf /var/cache/apk/*

WORKDIR /wdwnt

# Copy AWS credentials
COPY credentials /root/.aws/credentials

COPY intro.mp3 .
COPY gbbt.mp3 .

COPY script.sh .
RUN chmod a+x script.sh

CMD ./script.sh
