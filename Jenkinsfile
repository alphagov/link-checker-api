#!/usr/bin/env groovy

library("govuk")

node {
  govuk.buildProject([
    beforeTest: { -> sh("bundle exec rake db:environment:set") }
  ])
}
