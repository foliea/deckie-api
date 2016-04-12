#!/bin/bash
set -e

cmd="$1"

build="$2"

app="$build-deckie-api"

function init() {
    echo "Creating heroku app $app..."

    heroku apps:create $app --region eu
}

function configure() {
    if [ "$CUSTOM_DOMAIN" ]; then
        if [ $build == "production" ]; then
            api_domain_name="api.$CUSTOM_DOMAIN"
            front_domain_name="www.$CUSTOM_DOMAIN"
        else
            api_domain_name="$build-api.$CUSTOM_DOMAIN"
            front_domain_name="$build-front.$CUSTOM_DOMAIN"
        fi
        heroku domains:clear --app $app

        heroku domains:add --app $app $api_domain_name
    else
        api_domain_name="$app.herokuapp.com"

        front_domain_name=${api_domain_name/api/front}
    fi

    heroku config:set --app $app API_URL="http://$api_domain_name" \
                                 FRONT_URL="http://$front_domain_name"
}

function deploy() {
    echo "Deploying heroku app $app..."

    heroku maintenance:on --app $app

    heroku docker:release --app $app

    heroku run --app $app bundle exec rake db:migrate

    heroku maintenance:off --app $app
}

function env() {
    echo "Copying heroku app $app environment variables..."

    heroku config --app $app -s > .env
}

function clean() {
    heroku apps:destroy --app $app --confirm $app
}

function name() {
    echo $app
}

for supported_cmd in init configure deploy env clean name
do
    if [ "$cmd" == $supported_cmd ]; then
        if [ ! $build ]; then
            echo "Please specify a build type."

            exit -1
        fi

        eval $cmd

        exit 0
    fi
done

echo "usage: bash scripts/heroku.sh [init|configure|deploy|env|clean|name] build"

exit -1