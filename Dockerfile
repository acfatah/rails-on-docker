FROM ruby:3.1.2

WORKDIR /usr/src/app

# Variables for building the image
ARG RAILS_ENV="${RAILS_ENV:-production}"
ARG NODE_ENV="${RAILS_ENV:-production}"

# Get host id and group by running "$(id -u)" and "$(id -g)"
ARG UID="${UID:-1000}"
ARG GID="${GID:-1000}"

# Variables for running the container
ENV RAILS_ENV="${RAILS_ENV:-production}" \
    NODE_ENV="${NODE_ENV}:-production" \
    PATH="/usr/src/app/bin:/usr/src/app/node_modules/.bin:${PATH}"

RUN apt update && apt install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        gnupg \
        imagemagick \
        libpq-dev \
        postgresql-client \
        vim && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main' | tee /etc/apt/sources.list.d/yarn.list && \
    apt update && apt install -y --no-install-recommends nodejs yarn && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    apt clean && \
    groupadd -g ${GID} ruby && \
    useradd -m -l -u ${UID} -g ruby ruby && \
    usermod --shell /bin/bash ruby && \
    chown --changes --silent --no-dereference --recursive \
        ${UID}:${GID} \
        /home/ruby \
        /usr/local/lib \
        /usr/local/bin \
        /usr/src/app

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

USER ruby

COPY --chown=ruby:ruby Gemfile* ./
RUN bundle install --jobs "$(nproc)"

ENTRYPOINT ["entrypoint.sh"]

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
