FROM library/ubuntu:20.04
RUN  apt-get update
RUN  apt-get install -y fio
COPY pw.append /tmp
COPY group.append /tmp
RUN  cat /tmp/pw.append >> /etc/passwd && \
      cat /tmp/group.append >> /etc/group
