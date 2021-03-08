# This file is licensed under the Affero General Public License version 3 or
# later. See the LICENSE file.

# Dependencies:
# * make
# * npm
# * curl: used if phpunit and composer are not installed to fetch them from the web
# * tar: for building the archive

app_name=$(notdir $(CURDIR))
project_directory=$(CURDIR)/../$(app_name)
build_tools_directory=$(CURDIR)/build/tools
appstore_build_directory=$(CURDIR)/build/artifacts/appstore
appstore_package_name=$(appstore_build_directory)/$(app_name)
appstore_sign_dir=$(appstore_build_directory)/sign
cert_dir=$(build_tools_directory)/certificates
npm=$(shell which npm 2> /dev/null)
composer=$(shell which composer 2> /dev/null)

all: dev-setup build-js-production
serve: dev-setup watch-js

# a copy is fetched from the web
.PHONY: composer
composer:
ifeq (,$(composer))
	@echo "No composer command available, downloading a copy from the web"
	mkdir -p $(build_tools_directory)
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar $(build_tools_directory)
	php $(build_tools_directory)/composer.phar install --prefer-dist
else
	composer install --prefer-dist
endif

# Dev env management
dev-setup: clean clean-dev composer npm-init

npm-init:
	npm ci

npm-update:
	npm update

# Building
build-js:
	npm run dev

build-js-production:
	npm run build

watch-js:
	npm run watch

# Linting
lint:
	npm run lint

lint-fix:
	npm run lint:fix
	npm run stylelint:fix

# Style linting
stylelint:
	npm run stylelint

.PHONY: docs
docs:
	./docs/node_modules/.bin/vuepress dev docs/

# Cleaning
.PHONY: clean
clean:
	rm -rf js/
	rm -rf $(appstore_build_directory)

clean-dev:
	rm -rf node_modules
	rm -rf vendor
	rm -rf $(appstore_build_directory)

.PHONY: test
test: composer
	$(CURDIR)/vendor/bin/phpunit -c phpunit.xml

# Builds the source package for the app store, ignores php and js tests
.PHONY: appstore
appstore: clean
	mkdir -p $(appstore_sign_dir)/$(app_name)
	composer install --no-dev
	npm run build
	cp -r \
		appinfo \
		cfssl \
		img \
		js \
		l10n \
		lib \
		templates \
		vendor \
		CHANGELOG.md \
		LICENSE \
		$(appstore_sign_dir)/$(app_name)
	chown -R www-data:www-data $(appstore_sign_dir)/$(app_name)

	mkdir -p $(cert_dir)
	@if [ -n "$$app_private_key" ]; then \
		echo "$$app_private_key" > $(cert_dir)/$(app_name).key; \
		echo "$$app_public_crt" > $(cert_dir)/$(app_name).crt; \
		echo "Signing app files…"; \
		runuser -u www-data -- \
		php ../../occ integrity:sign-app \
			--privateKey=$(cert_dir)/$(app_name).key\
			--certificate=$(cert_dir)/$(app_name).crt\
			--path=$(appstore_sign_dir)/$(app_name); \
		echo "Signing app files ... done"; \
	fi
	tar -czf $(appstore_package_name).tar.gz -C $(appstore_sign_dir) $(app_name)
