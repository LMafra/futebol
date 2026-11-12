FROM ubuntu:24.04

ARG RUBY_VERSION=3.3.6

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/home/ubuntu/.local/bin:/home/ubuntu/.local/share/mise/shims:/usr/local/bin:${PATH}"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      build-essential \
      libpq-dev \
      libyaml-dev \
      libffi-dev \
      zlib1g-dev \
      libssl-dev \
      libreadline-dev \
      libvips42 \
      libvips-dev \
      postgresql \
      postgresql-contrib \
      libjemalloc2 \
      sudo \
      locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8

RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

USER ubuntu
WORKDIR /home/ubuntu

RUN curl -fsSL https://mise.run | sh && \
    ~/.local/bin/mise install "ruby@${RUBY_VERSION}" && \
    ~/.local/bin/mise use -g "ruby@${RUBY_VERSION}"

USER root
RUN RUBY_PREFIX="$(ls -d /home/ubuntu/.local/share/mise/installs/ruby/${RUBY_VERSION}*)" && \
    ln -sf "${RUBY_PREFIX}/bin/ruby" /usr/local/bin/ruby && \
    ln -sf "${RUBY_PREFIX}/bin/gem" /usr/local/bin/gem && \
    ln -sf "${RUBY_PREFIX}/bin/bundle" /usr/local/bin/bundle && \
    ln -sf "${RUBY_PREFIX}/bin/bundler" /usr/local/bin/bundler && \
    ruby -v && bundle -v

USER ubuntu
WORKDIR /workspace
