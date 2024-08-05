# DS-StatScript
Скрипт формирует отчет по истории сделок советников, фильтруя их по части комментария или мэджику.

## Установка
1. Убедитесь, что ваш терминал MetaTrader 5 обновлен до последней версии. Для тестирования советников рекомендуется обновить терминал до самой последней бета-версии. Для этого запустите обновление из главного меню `Help->Check For Updates->Latest Beta Version`. На прошлых версиях советник может не запускаться, потому что скомпилирован на последней версии терминала. В этом случае вы увидите сообщения на вкладке `Journal` об этом.
2. Скопируйте исполняемый файл скрипта `*.ex5` в каталог данных терминала `MQL5\Scripts\`. ==Важно скопировать именно в папку Scripts.==

## Формирование отчета
1. Откройте график любой пары. Можно даже использовать уже открытые, на которых торгует советник. Скрипт никак не повлияет на это.
2. Переместите скрипт из окна Навигатор на график.
3. Выберите один из предустановленных фильтров по советнику в параметре `Тип фильтра позиции`.
4. Для формирования отчета по другим ботам можно использовать типы `Другой комментарий` или `Другой MAGIC` и указать подстроку комментария или MAGIC в поле `Другой комментарий/MAGIC`. **ВНИМАНИЕ:** Заглавные и строчные буквы - это важное различие.
5. Укажите нужный период для формирования отчета в полях `Период ОТ` и `Период ДО`. Если оставить значения по умолчанию, то скрипт сформирует отчет за всю доступную историю в терминале.
6. Нажмите `OK`.
7. Откройте панель `Инструменты` (главное меню `Вид`-`Инструменты`).
8. Перейдите на закладку `Эксперты`, чтобы увидеть отчет.
![Колонки отчета](img/UM001.%20Report%20Columns.png)