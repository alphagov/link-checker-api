#!/usr/bin/env groovy

library("govuk")

node("postgresql-9.3") {
  govuk.buildProject(
    beforeTest: { -> sh("bundle exec rake db:environment:set") },
    brakeman: true,
  )
}
