![Sakve Logo](https://raw.githubusercontent.com/1000ideas/sakve/master/app/assets/images/logo.png "Sakve Logo")

__This project is obsolete. For our current developments see [1000.software website](https://1000.software/).__

Sakve aims to be a self-hosted alternative to WeTransfer, with cloud files storage for companies. Application is written in Ruby on Rails and allows You to store, share and send files. Perfect tool for sharing files inside any company.

Current features:
1.   Cloud file storage, with directories tree.
2.   Files shared inside the company
3.   Easy drag & drop file upload
4.   Customizable transfer download page
5.   Auto expiring transfers
6.   Each user can have different storage limit
...and many more smaller things.

## Current state

Sakve is fully functional, production-tested application, though got out of date with dependencies. It needs both Ruby and Rails updates, along with all dependencies in order to thrive.

## Docker

Application is composed with Docker and consists of two environments: production and dvelopment.

`docker-compose -f docker-compose-prod.yml up --build` - build and run app in a production environment (tables __won't be__ populated with seed data; files .coffee and .scss __will be__ compiled).

`docker-compose -f docker-compose-dev.yml up --build` - build and run app in a development environment (tables __will be__ populated with seed data; files .coffee and .scss __won't be__ compiled).

## How to start?

Before running the application you should install all necessary gems, by running a command `bundle update`. Some of the jobs are running in the background using Sidekiq. Thats why you need to have Redis daemon and Sidekiq running before.

There is a garbage collector task, you need to run it often in order to remove old transfers and temporary files. You can run it with: `rake sakve:transfer:clean`.

## Background jobs

Sakve processes files asynchronous with Sidekiq, so it won't clutch processors and RAM:

`FolderArchiveWorker` - creates zip archive from selected folder.

`SelectionArchiveWorker` - creates zip archive from selected files and folder.

`TransferArchiveWorker` - processes transfered files. Create zip arhive if needed.

`ItemProcessWorker` - processes added file. Creates thumbnails, converts files to friendly formats.

## How to start in more traditional way? (without Docker)

```bash
gem install bundler
bundle install
rake db:create
rake db:migrate
rake db:seed
```

## How to restart database:

```bash
rake db:setup
```

## In order to  run specific <command> in production environment
```
RAILS_ENV=production <command>
```




