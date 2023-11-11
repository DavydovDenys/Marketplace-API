# Multi-stage build
# Stage for creating a slim base image
FROM ruby:3.2.2-slim AS base
LABEL PROJECT=PANTERA
ENV BUNDLER_VERSION=2.4.21
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
    postgresql-client shared-mime-info libjemalloc2 \
    && apt-get upgrade -y \
    && gem update --system \
    && gem install bundler -v ${BUNDLER_VERSION} \
    && apt-get clean \
    && rm /bin/sh && ln -s /bin/bash /bin/sh \
    && rm -rf /var/cache/apt/archives/* \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/ \
    && truncate -s 0 /var/log/*log

# Stage for installing dependencies
FROM base as addons
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends apt-transport-https \
    curl git openssh-client tar nano tzdata \
    ruby-dev gnupg2 build-essential libpq-dev

# Stage for installing Ruby gems and compile assets
FROM addons AS dependencies
ARG RAILS_ENV=development
COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install --jobs=3 --retry=3
WORKDIR /app
COPY . ./
RUN rm -rf $GEM_HOME/cache/*

# Stage for building a final image
FROM base
ARG UID=1000
ARG GID=1000
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends apt-transport-https curl
WORKDIR /app
# add permission to user api
RUN groupadd -r api \
    && groupmod -g ${GID} api \
    && useradd -u ${UID} -g api -ms /bin/bash api \
    && chown api /app
USER api
COPY --chown=api --from=dependencies /usr/local/bundle/ /usr/local/bundle/
COPY --chown=api --from=dependencies /app/public/ public/
COPY --chown=api . ./

CMD ["bundle","exec","rails","server","-b","0.0.0.0","--pid","/tmp/server.pid"]
