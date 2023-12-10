FROM ruby:3.2.2
ENV BUNDLER_VERSION=2.4.22
RUN apt-get clean all && apt-get update -qq && apt-get install -y build-essential libpq-dev \
    curl gnupg2 apt-utils default-libmysqlclient-dev git libcurl3-dev cmake \
    libssl-dev pkg-config openssl imagemagick file nodejs yarn postgresql-client
RUN gem install bundler -v 2.4.22
COPY Gemfile Gemfile.lock ./
RUN bundle check || bundle install
WORKDIR /app
RUN bundle config build.nokogiri --use-system-libraries
COPY package.json yarn.lock ./
COPY . ./ 
ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]
EXPOSE 3000
# Run a shell
CMD ["/bin/sh"]