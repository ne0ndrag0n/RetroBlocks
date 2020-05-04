FROM alpine:edge

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
RUN apk update
RUN apk add bash gcc libc-dev make tar sed gzip xvfb xvfb-run mame@testing
RUN wget -O /root/vasm.tar.gz http://sun.hasenbraten.de/vasm/release/vasm.tar.gz && \
	tar xvzf /root/vasm.tar.gz -C /root && \
	cd /root/vasm && \
	make CPU=m68k SYNTAX=mot && \
	cp /root/vasm/vasmm68k_mot /bin/vasmm68k_mot