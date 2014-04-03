# Sakve

Aplikacja pozwalająca na przechowywanie i dzielenie się plikami miedzy zalogowanymi użytkownikami. Dodatkowo istnieje możliwość publicznych transferów plików

## Jak to działa?

Przed uruchomieniem plikacji należy zainstalować najnowsze wersje gemów, wykonując komendę `bundle update`. Aplikacja wykonuje pewne operacje offline wykorzystując do tego sidekiq (redis) dlatego w systemie musi działać demon redisa i musi zostać właczony sidekiq.

Dodatkowo, aby zaoszczędziś miejce nalezy regularnie uruchamiać `rake sakve:transfer:clean`. Zadanie usuwa nieaktualne transfery plików.

## Zadanie wykonywane w tle

Aplikacja przetwarza pliki offline, aby nie blokować bazy i serwera http.

`FolderArchiveWorker` - tworzy archiwum zip z wybranego folderu.

`SelectionArchiveWorker` - tworzy archiwum zip z zaznaczonych plików i folderów.

`TransferArchiveWorker` - przetwarza wysłane pliki. Tworzy archiwum zip w razie potrzeby.

`ItemProcessWorker` - przetwarza dodany plik. Tworzy miniaturki i konwertuje pliki na przystępne formaty.
