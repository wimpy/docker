FROM alpine:3.4

ENTRYPOINT ["/sbin/tini", "--", "ansible-playbook"]
CMD ["--version"]

COPY . /tmp

VOLUME ["/app"]
WORKDIR /app
ENV PWD /app

RUN apk add --update --repository https://dl-cdn.alpinelinux.org/alpine/edge/community/ tini=0.14.0-r0 python py-pip openssl ca-certificates git \
    && apk --update add --virtual build-dependencies python-dev libffi-dev openssl-dev build-base \
    && pip install --upgrade pip cffi \
    && pip install -r /tmp/requirements.txt \
    && pip install docker-compose==1.9.0 \
    && ansible-galaxy install -r /tmp/galaxy-requirements.yml \
    && cp /tmp/ansible.cfg /etc/ansible/ansible.cfg \
    && echo 'localhost' > /etc/ansible/hosts \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/*

ARG vcs_ref="Unknown"
ARG vcs_branch="Unknown"
ARG build_date="Unknown"

LABEL org.label-schema.vcs-ref=$vcs_ref \
      org.label-schema.vcs-branch=$vcs_branch \
      org.label-schema.build-date=$build_date \
      maintainer="jose@armesto.net"


