# Распределённое программирование. Задание #7 Материализованное представление (Materialized View)

## Постановка задачи
Предоставляем пользователю новую функциональность : суммарный отчёт по обработанным текстам. 

Отчёт содержит в себе: 
1. общее количество всех обработанных текстов (*TextNum*);
2. количество текстов с высокой оценкой (выше 0.5) (*HighRankPart*);
3. средняя оценка (*AvgRank*).

## Анализ задачи

Решение задачи подразумевает представление имеющихся данных в другом виде, отличном от того, как они хранятся и используются в контексте других задач. Поэтому нам нужно реализовать преобразование данных из одного формата в другой.

Подобное преобразование зачастую является очень ресурсоёмкой, а иногда и вовсе нереализуемой задачей в рамках имеющихся ограничений к системе. Такое может иметь место, если процесс преобразования включает в себя обработку больших объёмов данных, большую вычислительную нагрузку, необходимость обращения к удалённым системам и т.д. К тому же, если традиционные реляционные СУБД предоставляют возможность выполнить преобразование в рамках запроса на получение данных, то NoSQL базы данных наподобие *Redis* и вовсе не имеют такой возможности. Немаловажный факт, что в большинстве случаев при каждом последующем обращении за преобразованными данными происходят одни и те же операции по преобразованию, что влечёт неэффективное использование ресурсов системы.

Решением в таких случаях является иметь материализованное представление преобразованных данных, обеспечив его обновление и хранение при необходимости.

## Реализация

### Frontend

Добавляется страница со статистикой (MVC-контроллер ***StatisticsController*** c соответствующими View), на которой отображается статистическая информация. Данные для отображения берутся из *BackendApi* посредством вызова веб-сервиса по HTTP протоколу.

## Backend

*VowelConsRater* после записи результата ранга выкидывает сообщение ***TextRankCalculated(contextId, rank)*** в широковещательную очередь ***text-rank-calc***.

Добавляется компонент ***TextStatistics*** в виде EXE-приложения, который слушает появление сообщений *TextRankCalculated* в очереди *text-rank-calc* и обновляет статистику при получении сообщений. Статистика хранится в оперативной памяти процесса и сохраняется в *Redis*-хранилище.

В компонент *BackendApi* добавляется метод веб-сервиса, отдающий статистику фронтенду. При вызове метода происходит обращение в *Redis*-хранилище и полученное значение отдаётся клиенту. 

## Повышающий коэффициэнт (+0.1 за каждый пункт):
1. *Frontend*: выдача клиенту статистики из кэша вместо постоянного обращения за последними данными (длительность кэширования произвольная, но достаточная для проверки функционирования);
2. *TextStatistics*: локальные значения счётчиков  при старте инициируются значениями из Redis.