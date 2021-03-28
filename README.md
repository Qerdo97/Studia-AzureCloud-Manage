Wymogi Formalne

1 - Raport o maszynach wirtualnych
a) raport w csv zawierający informacje o wszystkich maszynach wirtualnych posiadanych w ramach tenanta Azure. Raport zawiera poniższe informacje
• Nazwa maszyny
• Rozmiar maszyny
• Obecny status
• Wersja zainstalowanego systemu operacyjnego
• Nazwa Wbudowanego konta Administratora
• Rozmiar dysku z systemem operacyjnym
• Typ dysku z systemem operacyjnym
• Ilość dysków DATA i dla każdego w nich
o Rozmiar dysku
o Typ dysku
• Publiczny adres IP
• Prywatny adres IP
• Przypisana grupa NSG
• Przypisana grupa ASG
• Grupa zasobów
• Subskrypcja Azure
Nazwa raportu „numerindeksu_VMs.csv”
Lokalizacja raportu c:\wit\numerindeksu\VM
b) raport zawierający listę wszystkich sieci wirtualnych w tenancie Azure
Nazwa raportu „numerindeksu_sieciwirtualne.csv”
Lokalizacja raportu c:\wit\numerindeksu\VM
Pola w raporcie:
• Nazwa sieci
• Adresacja (IP+ maska)
• Ilość podsieci, dla każdej z podsieci:
o Adresacja (IP+ maska)
• Grupa zasobów
• Nazwa subskrypcji
c) raport zawierający listę wszystkich grup NSG oraz ich wpisów odnośnie ruchu przychodzącego i wychodzącego
Nazwa raportu „numerindeksu_NSG.csv”
Lokalizacja raportu c:\wit\numerindeksu\VM
Pola w raporcie:
• Nazwa grupy
• Rodzaj reguły (przychodząca / wychodząca)
• Konfiguracja
• Grupa zasobów
• Nazwa subskrypcji

2 - Raport wszystkich kont użytkowników w Azure Active Directory
raporty zawierające listy wszystkich osób z w Azure Active Directory z podziałem na działy.
Raport ma dynamicznie budować listę działy na podstawie danych z Azure Active Directory.
Dla każdego z działów ma zostać wygenerowany oddzielny plik csv o nazwie „numerindeksu_nazwadzialu.csv”.
Lokalizacja raportów: c:\wit\numerindeksu\dzialyAAD
Każdy raport musi zawierać pola:
• Imię
• Nazwisko
• UPN
• Przydzielone licencje

3 - Raport wszystkich grup w Azure Active Directory
raporty zawierające listę członków oraz właścicieli dla każdej grupy będącej w Azure Active Directroy
Dla każdej z grupy musi zostać utworzony oddzielny raport o nazwie „numerindeksu_ nazwagrupy.csv”.
Lokalizacja raportów: c:\wit\numerindeksu\grupyAAD
Pola w raporcie:
• Owner
• Member

4 - Raport wszystkich zdarzeń w katalogu oddziałujących na konta użytkownika
raport zawierający listę wszystkich zdarzeń zarejestrowanych, które zostały wykonane na kontach użytkowników. Raport musi zawierać poniższe pola:
• Kto
• Kiedy
• Na jakim obiekcie
• Co zostało wykonane
• Nowa wartość (jeśli istnieje)
Nazwa raportu „numerindeksu_LogiAAD.csv”
Lokalizacja raportu c:\wit\numerindeksu\logiAAD
