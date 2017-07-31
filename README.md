# Sakve

Aplikacja pozwalająca na przechowywanie i dzielenie się plikami miedzy zalogowanymi użytkownikami. Dodatkowo istnieje możliwość publicznych transferów plików

## Docker

Aplikacja jest połączona z Dockerem. Pozwala on nam uruchomić aplikację w środowisku produkcyjnym lub developerskim.

`docker-compose -f docker-compose-prod.yml up --build` - buduje i uruchamia aplikację w środowisku produkcyjnym (tabele __nie__ zostaną wypełnione przykładowymi danymi; pliki .coffee i .scss zostaną skompilowane).

`docker-compose -f docker-compose-dev.yml up --build` - buduje i uruchamia aplikację w środowisku developerskim (tabele __zostaną__ wypełnione przykładowymi danymi; pliki .coffee i .scss __nie__ zostaną skompilowane).

## Jak to działa?

Przed uruchomieniem aplikacji należy zainstalować najnowsze wersje gemów, wykonując komendę `bundle update`. Aplikacja wykonuje pewne operacje offline wykorzystując do tego sidekiq (redis) dlatego w systemie musi działać demon redisa i musi zostać włączony sidekiq.

Dodatkowo, aby zaoszczędzić miejce należy regularnie uruchamiać `rake sakve:transfer:clean`. Zadanie usuwa nieaktualne transfery plików.

## Zadanie wykonywane w tle

Aplikacja przetwarza pliki offline, aby nie blokować bazy i serwera http.

`FolderArchiveWorker` - tworzy archiwum zip z wybranego folderu.

`SelectionArchiveWorker` - tworzy archiwum zip z zaznaczonych plików i folderów.

`TransferArchiveWorker` - przetwarza wysłane pliki. Tworzy archiwum zip w razie potrzeby.

`ItemProcessWorker` - przetwarza dodany plik. Tworzy miniaturki i konwertuje pliki na przystępne formaty.
