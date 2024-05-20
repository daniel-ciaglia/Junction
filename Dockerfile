# run `docker build --output type=local,dest=. .`
FROM ubuntu:24.04 as builder
LABEL authors="daniel@sigterm.de"

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y flatpak dpkg-dev
WORKDIR /
# get the binary
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
    flatpak install --assumeyes --noninteractive --no-deps flathub re.sonny.Junction
RUN mkdir -p build-deb/usr/local/bin && mkdir -p build-deb/usr/local/share/re.sonny.Junction/ && \
    cp /var/lib/flatpak/app/re.sonny.Junction/current/active/files/bin/re.sonny.Junction build-deb/usr/local/bin/ && \
    cp /var/lib/flatpak/app/re.sonny.Junction/current/active/files/share/re.sonny.Junction/re.sonny.Junction.src.gresource build-deb/usr/local/share/re.sonny.Junction/
# adjust installation paths
RUN sed -i 's/\/app/\/usr\/local/g' build-deb/usr/local/bin/re.sonny.Junction

# add surrounding data
RUN mkdir -p build-deb/usr/local/share/dbus-1/services
COPY  data/re.sonny.Junction.service build-deb/usr/local/share/dbus-1/services/

RUN mkdir -p build-deb/usr/local/share/icons/hicolor/symbolic/apps && mkdir -p build-deb/usr/local/share/icons/hicolor/scalable/apps
COPY data/icons/re.sonny.Junction-symbolic.svg build-deb/usr/local/share/icons/hicolor/symbolic/apps/
COPY data/icons/re.sonny.Junction.svg build-deb/usr/local/share/icons/hicolor/scalable/apps/

RUN mkdir -p build-deb/usr/local/share/applications && mkdir -p build-deb/usr/local/share/metainfo && mkdir -p build-deb/usr/local/share/glib-2.0/schemas
COPY data/re.sonny.Junction.desktop build-deb/usr/local/share/applications/
COPY data/re.sonny.Junction.metainfo.xml build-deb/usr/local/share/metainfo/
COPY data/re.sonny.Junction.gschema.xml build-deb/usr/local/share/glib-2.0/schemas/

# deb build stuff
RUN mkdir -p build-deb/DEBIAN
COPY build-deb/ build-deb/DEBIAN/
RUN dpkg-deb --build build-deb re.sonny.Junction.deb

# ---------------------------------------------------------------------
FROM scratch as export
COPY --from=builder /*.deb .
