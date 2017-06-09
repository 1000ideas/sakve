FROM ruby:2.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs libqt4-dev libqtwebkit-dev
RUN mkdir /sakve
WORKDIR /sakve
ADD Gemfile /sakve/Gemfile
ADD Gemfile.lock /sakve/Gemfile.lock
RUN bundle install
ADD . /sakve
