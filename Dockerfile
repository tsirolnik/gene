FROM ruby:2.3.0
RUN gem install bundler
RUN mkdir /app
WORKDIR /app
RUN bundler install
ENV PORT 4000
EXPOSE $PORT
CMD ["ruby", "gene.rb"]
