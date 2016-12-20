# Распил профилей.


Добавил кнопку "Cut profile". При нажатии на кнопку таблица "Материалы" дополняется остатком профиля, а также изменяются Cost percentage.
Пока никаких проверок нет. Работает только с одной строкой из первой закладки.

Productie de Profile
A fost adaugat un Buton "Cut Profile".
Prin apasarea acestui Buton, in tabelul "Materiale" se completeaza Profil-restul si se calculeaza Ratele de impartire a costurilor.

Scenariul de lucru:
1. Utilizatorul creeaza un Document nou "Productie"
2. Utilizatorul alege tipul de operatie "Dezassamblare"
3. In tabelul "Productie" se completeaza Profil-sursa, care va fi "Dezassamblat"
4. In tabelul "Materiale" se completeaza Profil, care urmeaza a fi vandut
5. Apasa Buton "Cut Profile"
6. Programul automat calculeaza, alege si adauga o linia noua cu Profil-restul 
7. Programul automat calculeaza si completeaza "Ratele de impartire a costurilor"
