FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
	build-essential autoconf automake libtool intltool gtk-doc-tools unzip wget git pkg-config autoconf libtool nasm curl

# heroku:18 includes some libraries, like tiff and jpeg, as part of the
# run-time platform, and we want to use those libs if we can
#
# see https://devcenter.heroku.com/articles/stack-packages
#
# libgsf needs libxml2
RUN apt-get install -y \
	glib-2.0-dev libexpat-dev librsvg2-dev libpng-dev libjpeg-dev libtiff5-dev libexif-dev liblcms2-dev libxml2-dev libfftw3-dev vim

RUN echo 'Install mozjpeg' && \
    cd /tmp && \
    git clone git://github.com/mozilla/mozjpeg.git && \
    cd /tmp/mozjpeg && \
    git checkout v3.3.1 && \
    autoreconf -fiv && \
    ./configure --prefix=/usr && \
    make install

ARG VIPS_VERSION=8.9.1
ARG VIPS_URL=https://github.com/libvips/libvips/releases/download

RUN cd /usr/src \
	&& wget ${VIPS_URL}/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.gz \
	&& tar xzf vips-${VIPS_VERSION}.tar.gz \
	&& cd vips-${VIPS_VERSION} \
	&& export PKG_CONFIG_PATH=/usr/local/vips/lib/pkgconfig \
	&& ./configure --prefix=/usr/local/vips --disable-gtk-doc \
	&& make \
	&& make install

# clean the build area and make a tarball ready for packaging
RUN echo 'Cleaning up' \
	&& cd /usr/local/vips \
	&& rm bin/batch_* bin/vips-8.9 \
	&& rm bin/vipsprofile bin/light_correct bin/shrink_width \
	&& strip lib/*.a lib/lib*.so* \
	&& rm -rf share/gtk-doc \
	&& rm -rf share/man \
	&& rm -rf share/thumbnailers \
	&& cd /usr/local \
	&& tar cfz libvips-dev-{VIPS_VERSION}.tar.gz vips

# ruby-vips needs ffi, and ffi needs the dev headers for ruby
RUN echo "Testing" && apt-get install -y ruby-dev

# test ruby-vips
RUN export LD_LIBRARY_PATH=/usr/local/vips/lib && gem install ruby-vips && ruby -e 'require "ruby-vips"; puts "success!"'
