FROM ruby:3.0.4
ENV BUNDLER_VERSION=2.3.25
RUN apt-get update -qq && apt-get install -y yarn nodejs postgresql-client redis-server
RUN gem install bundler -v 2.3.25
COPY Gemfile Gemfile.lock ./
RUN bundle check || bundle install
WORKDIR /app
RUN bundle config build.nokogiri --use-system-libraries
COPY package.json yarn.lock ./
COPY . ./
ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]
# Run a shell
CMD ["/bin/sh"]
