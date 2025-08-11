#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get -y upgrade

# install build tooling and header packages for squid 6
apt-get -y install \
    acl \
    winbind \
    libnss-winbind \
    libpam-winbind \
    krb5-user \
    samba-common \
    attr \
    bison \
    nettle-dev \
    wget \
    checkinstall \
    devscripts \
    dpkg-dev \
    dh-apparmor \
    debhelper \
    ed \
    msktutil \
    logrotate \
    libtool-bin \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libtdb-dev \
    libxml2-dev \
    libnetfilter-conntrack-dev \
    libsystemd-dev \
    libpam0g-dev \
    libblkid-dev \
    libbsd-dev \
    libcap2-dev \
    libattr1-dev \
    libacl1-dev \
    libaio-dev \
    libkrb5-dev \
    libsasl2-modules-gssapi-mit \
    libcppunit-dev \
    libexpat1-dev \
    libgnutls28-dev \
    libltdl-dev \
    libecap3-dev \
    libdbi-perl \
    libdb-dev \
    pkg-config

CI_BUILD_ROOT=${PWD}

# drop squid build folder
rm -R build/squid

# we will be working in a subfolder make it
mkdir -p build/squid

# load OS info into env
source /etc/os-release

# set squid version
source squid.ver
SQUID_GIT_TAG="SQUID_${SQUID_VER//./_}"

# decend into working directory
pushd build/squid

# get squid source code from github
git clone https://github.com/squid-cache/squid.git squid-${SQUID_VER}
cd squid-${SQUID_VER} && \
git fetch --tags --prune && \
# checkout the version we want to build
git checkout -b $SQUID_VER $SQUID_GIT_TAG
# build the package
    ./bootstrap.sh && \
    ./configure --srcdir=. --prefix=/usr --localstatedir=/var/lib/squid --libexecdir=/usr/lib/squid \
        --datadir=/usr/share/squid --sysconfdir=/etc/squid --with-default-user=proxy --with-logdir=/var/log/squid \
        --with-open-ssl=/etc/ssl/openssl.cnf --with-openssl --enable-ssl --enable-ssl-crtd \
        --with-pidfile=/var/run/squid.pid --enable-removal-policies=lru,heap \
        --enable-delay-pools --enable-cache-digests --enable-icap-client --enable-ecap --enable-follow-x-forwarded-for \
        --with-large-files --with-filedescriptors=65536 --with-default-user=proxy \
        --enable-auth-basic \
        --enable-auth-digest=file,LDAP --enable-auth-negotiate=kerberos,wrapper --enable-auth-ntlm=fake,SSPI \
        --enable-linux-netfilter --with-swapdir=/var/cache/squid --enable-useragent-log --enable-htpc \
        --infodir=/usr/share/info --mandir=/usr/share/man --includedir=/usr/include --disable-maintainer-mode \
        --disable-dependency-tracking --disable-silent-rules --enable-inline --enable-async-io \
        --enable-storeio=ufs,aufs,diskd,rock --enable-eui --enable-esi --enable-icmp --enable-zph-qos \
        --enable-external-acl-helpers=file_userip,kerberos_ldap_group,time_quota,LDAP_group,session,SQL_session,unix_group,wbinfo_group \
        --enable-url-rewrite-helpers=fake --enable-translation --enable-epoll --enable-snmp --enable-wccpv2 \
        --with-aio --with-pthreads --enable-arp --enable-arp-acl \
        --with-build-environment=default --disable-dependency-tracking && \
    checkinstall \
        --install=no \
        --fstrans=no \
        --default \
        --pkgname=squid \
        --provides=squid \
        --pkgversion=${SQUID_VER} \
        --pkgarch=$(dpkg --print-architecture) \
        --pkgrelease=${ID}-${VERSION_CODENAME} \
        --pakdir=${CI_BUILD_ROOT}/pkgs \
        --maintainer="Dave Cuza \<dave@cuza.dev\>" \
        --conflicts="squid5" \
        --requires="libcppunit-dev, \
                    libsasl2-dev, \
                    libxml2-dev, \
                    libkrb5-dev, \
                    libdb-dev, \
                    libnetfilter-conntrack-dev, \
                    libexpat1-dev, \
                    libcap2-dev, \
                    libldap2-dev, \
                    libpam0g-dev, \
                    libgnutls28-dev, \
                    libssl-dev, \
                    libdbi-perl, \
                    libecap3, \
                    libecap3-dev, \
                    libsystemd-dev, \
                    libtdb-dev, \
                    libltdl7" \
        make -j`nproc` install
# and revert
popd
