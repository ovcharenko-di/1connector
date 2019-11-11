Перем мПулСоединений Экспорт;

Функция ВызватьHTTPМетод(Сессия, Метод, URL, ДополнительныеПараметры) Экспорт
	
	Если ТипЗнч(ДополнительныеПараметры) <> Тип("Структура") Тогда
		ДополнительныеПараметры = Новый Структура;
	КонецЕсли;
	
	ПодготовленныйЗапрос = ПодготовитьЗапрос(Сессия, Метод, URL, ДополнительныеПараметры);
	
	НастройкиПодключения = ПолучитьНастройкиПодключения(Метод, URL, ДополнительныеПараметры);
	
	Ответ = ОтправитьЗапрос(Сессия, ПодготовленныйЗапрос, НастройкиПодключения);
	
	Перенаправление = 0;
	Пока Перенаправление < Сессия.МаксимальноеКоличествоПеренаправлений Цикл
		Если Не НастройкиПодключения.РазрешитьПеренаправление ИЛИ Не Ответ.ЭтоРедирект Тогда
			Возврат Ответ;
		КонецЕсли;
		
		НовыйURL = СформироватьНовыйURLПриПеренаправлении(Ответ);

		ПодготовленныйЗапрос.URL = КодироватьСтроку(НовыйURL, СпособКодированияСтроки.URLВКодировкеURL);
		НовыйHTTPЗапрос = Новый HTTPЗапрос(СобратьАдресРесурса(КоннекторHTTP.РазобратьURL(НовыйURL), Неопределено));
		ПереопределитьМетод(ПодготовленныйЗапрос, Ответ);	
			
		Если Ответ.КодСостояния <> КодыСостоянияHTTP.ВременноеПеренаправление_307 
			И Ответ.КодСостояния <> КодыСостоянияHTTP.ПостоянноеПеренаправление_308 Тогда
			УдалитьЗаголовки(ПодготовленныйЗапрос.Заголовки, "content-length,content-type,transfer-encoding");
			НовыйHTTPЗапрос.Заголовки = ПодготовленныйЗапрос.Заголовки;
		Иначе
			НовыйHTTPЗапрос.УстановитьТелоИзДвоичныхДанных(ПодготовленныйЗапрос.HTTPЗапрос.ПолучитьТелоКакДвоичныеДанные());
		КонецЕсли;
		ПодготовленныйЗапрос.HTTPЗапрос = НовыйHTTPЗапрос;
		УдалитьЗаголовки(ПодготовленныйЗапрос.Заголовки, "cookies");

		ПодготовленныйЗапрос.Cookies = ОбъединитьCookies(Сессия.Cookies, ПодготовленныйЗапрос.Cookies);
		ПодготовитьCookies(ПодготовленныйЗапрос);
		
		// INFO: по хорошему аутентификацию нужно привести к новых параметрам, но пока будем игнорировать.
		
		Ответ = ОтправитьЗапрос(Сессия, ПодготовленныйЗапрос, НастройкиПодключения);
		
		Перенаправление = Перенаправление + 1;
	КонецЦикла;
	
	ВызватьИсключение("СлишкомМногоПеренаправлений");
	
КонецФункции

Функция СформироватьНовыйURLПриПеренаправлении(Ответ)

	НовыйURL = ПолучитьЗначениеЗаголовка("location", Ответ.Заголовки);
	НовыйURL = РаскодироватьСтроку(НовыйURL, СпособКодированияСтроки.URLВКодировкеURL);
	
	// Редирект без схемы
	Если СтрНачинаетсяС(НовыйURL, "//") Тогда
		СтруктураURL = КоннекторHTTP.РазобратьURL(Ответ.URL);
		НовыйURL = СтруктураURL.Схема + ":" + НовыйURL;
	КонецЕсли;

	СтруктураURL = КоннекторHTTP.РазобратьURL(НовыйURL);
	Если Не ЗначениеЗаполнено(СтруктураURL.Сервер) Тогда
		СтруктураURLОтвета = КоннекторHTTP.РазобратьURL(Ответ.URL);
		БазовыйURL = СтрШаблон("%1://%2", СтруктураURLОтвета.Схема, СтруктураURLОтвета.Сервер);
		Если ЗначениеЗаполнено(СтруктураURLОтвета.Порт) Тогда
			БазовыйURL = БазовыйURL + Формат(СтруктураURLОтвета.Порт, "ЧРГ=; ЧГ=");
		КонецЕсли;
		НовыйURL = БазовыйURL + НовыйURL;
	КонецЕсли;

	Возврат НовыйURL;

КонецФункции

Процедура УдалитьЗаголовки(Заголовки, СписокЗаголовковСтрокой)

	ЗаголовкиДляУдаления = Новый Массив;
	СписокЗаголовков = СтрРазделить(СписокЗаголовковСтрокой, ",", Ложь);
	Для Каждого Заголовок Из Заголовки Цикл
		Если СписокЗаголовков.Найти(НРег(Заголовок.Ключ)) <> Неопределено Тогда
			ЗаголовкиДляУдаления.Добавить(Заголовок.Ключ);
		КонецЕсли;
	КонецЦикла;
	Для Каждого ЗаголовокДляУдаления Из ЗаголовкиДляУдаления Цикл
		Заголовки.Удалить(ЗаголовокДляУдаления);
	КонецЦикла;

КонецПроцедуры

Функция ПолучитьНастройкиПодключения(Метод, URL, ДополнительныеПараметры) 

	РазрешитьПеренаправление = 
		ПолучитьЗначениеПоКлючу(ДополнительныеПараметры, "РазрешитьПеренаправление", ВРег(Метод) <> "HEAD");
	ПроверятьSSL = ПолучитьЗначениеПоКлючу(ДополнительныеПараметры, "ПроверятьSSL", Истина);
	КлиентскийСертификатSSL = ПолучитьЗначениеПоКлючу(ДополнительныеПараметры, "КлиентскийСертификатSSL");
	Прокси = ПолучитьЗначениеПоКлючу(ДополнительныеПараметры, "Прокси", ПолучитьПроксиПоУмолчанию(URL));

	Настройки = Новый Структура;
	Настройки.Вставить("Таймаут", ПолучитьТаймаут(ДополнительныеПараметры));
	Настройки.Вставить("РазрешитьПеренаправление", РазрешитьПеренаправление);
	Настройки.Вставить("ПроверятьSSL", ПроверятьSSL);
	Настройки.Вставить("КлиентскийСертификатSSL", КлиентскийСертификатSSL);
	Настройки.Вставить("Прокси", Прокси);

	Возврат Настройки;

КонецФункции

Функция ПолучитьТаймаут(ДополнительныеПараметры)
	
	Если ДополнительныеПараметры.Свойство("Таймаут") И ЗначениеЗаполнено(ДополнительныеПараметры.Таймаут) Тогда
		Таймаут = ДополнительныеПараметры.Таймаут;
	Иначе
		Таймаут = СтандартныйТаймаут();
	КонецЕсли;
	
	Возврат Таймаут;
	
КонецФункции

Функция ПолучитьПроксиПоУмолчанию(URL)
	
	Возврат Неопределено;
	
КонецФункции

Функция ПодготовитьЗапрос(Сессия, Метод, URL, ДополнительныеПараметры)
	
	Cookies = ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "Cookies", Новый Массив);
	Cookies = ОбъединитьCookies(ДозаполнитьCookie(Сессия.Cookies, URL), ДозаполнитьCookie(Cookies, URL));
	Аутентификация = ОбъединитьПараметрыАутентификации(
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "Аутентификация", Новый Структура),
		Сессия.Аутентификация);
	ПараметрыЗапроса = ОбъединитьПараметрыЗапроса(
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "ПараметрыЗапроса", Новый Структура),
		Сессия.ПараметрыЗапроса);
	Заголовки = ОбъединитьЗаголовки(
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "Заголовки", Новый Соответствие),
		Сессия.Заголовки);
	ПараметрыПреобразованияJSON = 
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "ПараметрыПреобразованияJSON", Неопределено);
		
	ПодготовленныйЗапрос = Новый Структура;
	ПодготовленныйЗапрос.Вставить("Cookies", Cookies);
	ПодготовленныйЗапрос.Вставить("Аутентификация", Аутентификация);
	ПодготовленныйЗапрос.Вставить("Метод", Метод);
	ПодготовленныйЗапрос.Вставить("Заголовки", Заголовки);
	ПодготовленныйЗапрос.Вставить("ПараметрыЗапроса", ПараметрыЗапроса);
	ПодготовленныйЗапрос.Вставить("URL", ПодготовитьURL(URL, ПараметрыЗапроса));
	ПодготовленныйЗапрос.Вставить("ПараметрыПреобразованияJSON", ПараметрыПреобразованияJSON);
	
	ПодготовитьCookies(ПодготовленныйЗапрос);
	ПодготовитьТелоЗапроса(
		ПодготовленныйЗапрос,
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "Данные", Новый Структура),
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "Файлы", Новый Массив),
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "Json", Неопределено),
		ВыбратьЗначение(Неопределено, ДополнительныеПараметры, "ПараметрыЗаписиJSON", Неопределено));
	ПодготовитьАутентификацию(ПодготовленныйЗапрос);

	Возврат ПодготовленныйЗапрос;
	
КонецФункции

Функция ДозаполнитьCookie(Cookies, URL)
	
	СтруктураURL = КоннекторHTTP.РазобратьURL(URL);
	НовыеCookies = Новый Массив;
	Если ТипЗнч(Cookies) = Тип("Массив") Тогда
		Для Каждого Cookie Из Cookies Цикл
			НовыйCookie = КонструкторCookie(Cookie.Наименование, Cookie.Значение);
			ЗаполнитьЗначенияСвойств(НовыйCookie, Cookie);
			
			Если Не ЗначениеЗаполнено(НовыйCookie.Домен) Тогда
				НовыйCookie.Домен = СтруктураURL.Сервер;
			КонецЕсли;
			Если Не ЗначениеЗаполнено(НовыйCookie.Путь) Тогда
				НовыйCookie.Путь = "/";
			КонецЕсли;
			
			НовыеCookies.Добавить(НовыйCookie);
		КонецЦикла;
		
		Возврат НовыеCookies;
	КонецЕсли;
	
	Возврат Cookies;
	
КонецФункции

Процедура ДобавитьCookieВХранилище(ХранилищеCookies, Cookie, Замещать = Ложь)
	
	Если ХранилищеCookies.Получить(Cookie.Домен) = Неопределено Тогда
		ХранилищеCookies[Cookie.Домен] = Новый Соответствие;
	КонецЕсли;
	Если ХранилищеCookies[Cookie.Домен].Получить(Cookie.Путь) = Неопределено Тогда
		ХранилищеCookies[Cookie.Домен][Cookie.Путь] = Новый Соответствие;
	КонецЕсли;
	Если ХранилищеCookies[Cookie.Домен][Cookie.Путь].Получить(Cookie.Наименование) = Неопределено ИЛИ Замещать Тогда
		ХранилищеCookies[Cookie.Домен][Cookie.Путь][Cookie.Наименование] = Cookie;
	КонецЕсли;
	
КонецПроцедуры

Функция ДобавитьЛидирующуюТочку(Знач Домен)
	
	Если Не СтрНачинаетсяС(Домен, ".") Тогда
		Домен = "." + Домен;
	КонецЕсли;
	
	Возврат Домен;
	
КонецФункции

Процедура ЗаполнитьСписокОтфильрованнымиCookies(Cookies, СтруктураURL, Список)

	Для Каждого Cookie Из Cookies Цикл
		Если Cookie.Значение.ТолькоБезопасноеСоединение = Истина И СтруктураURL.Схема <> "https" Тогда
			Продолжить;
		КонецЕсли;
		// INFO: проверка срока действия игнорируется (Cookie.Значение.СрокДействия)
		// INFO: проверка порта игнорируется
		
		Список.Добавить(Cookie.Значение);
	КонецЦикла;

КонецПроцедуры

Функция ОтобратьCookiesДляЗапроса(СтруктураURL, Cookies)
	
	СерверВЗапросе = ДобавитьЛидирующуюТочку(СтруктураURL.Сервер);
	
	Результат = Новый Массив;
	Для Каждого Домен Из Cookies Цикл
		ДоменВCookie = ДобавитьЛидирующуюТочку(Домен.Ключ);
		Если Не СтрЗаканчиваетсяНа(СерверВЗапросе, Домен.Ключ) Тогда
			Продолжить;
		КонецЕсли;
		Для Каждого Путь Из Домен.Значение Цикл
			Если Не СтрНачинаетсяС(СтруктураURL.Путь, Путь.Ключ) Тогда
				Продолжить;
			КонецЕсли;
			ЗаполнитьСписокОтфильрованнымиCookies(Путь.Значение, СтруктураURL, Результат);
		КонецЦикла;
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

Функция ПодготовитьЗаголовокCookie(ПодготовленныйЗапрос)
	
	СтруктураURL = КоннекторHTTP.РазобратьURL(ПодготовленныйЗапрос.URL);
	
	Заголовок = "";
	Cookies = Новый Массив;
	Для Каждого Cookie Из ОтобратьCookiesДляЗапроса(СтруктураURL, ПодготовленныйЗапрос.Cookies) Цикл
		Cookies.Добавить(СтрШаблон("%1=%2", Cookie.Наименование, Cookie.Значение));
	КонецЦикла;
	
	Возврат СтрСоединить(Cookies, "; ");
	
КонецФункции

Процедура ПодготовитьCookies(ПодготовленныйЗапрос)
	
	ЗаголовокCookie = ПодготовитьЗаголовокCookie(ПодготовленныйЗапрос);
	Если ЗначениеЗаполнено(ЗаголовокCookie) Тогда
		ПодготовленныйЗапрос.Заголовки["Cookie"] = ЗаголовокCookie;
	КонецЕсли;
	
КонецПроцедуры

Функция КодироватьПараметрыЗапроса(ПараметрыЗапроса)
	
	ЧастиПараметрыЗапроса = Новый Массив;
	Для Каждого Параметр Из ПараметрыЗапроса Цикл
		Если ТипЗнч(Параметр.Значение) = Тип("Массив") Тогда
			Значения = Параметр.Значение;
		Иначе
			Значения = Новый Массив;
			Значения.Добавить(Параметр.Значение);
		КонецЕсли;
		
		Если Параметр.Значение = Неопределено Тогда
			ЧастиПараметрыЗапроса.Добавить(Параметр.Ключ);
		Иначе
			Для Каждого Значение Из Значения Цикл
				ЗначениеПараметра = КодироватьСтроку(Значение, СпособКодированияСтроки.URLВКодировкеURL);
				ЧастиПараметрыЗапроса.Добавить(СтрШаблон("%1=%2", Параметр.Ключ, ЗначениеПараметра));
			КонецЦикла;
		КонецЕсли;	
	КонецЦикла;
	
	Возврат СтрСоединить(ЧастиПараметрыЗапроса, "&");
	
КонецФункции

Функция ПодготовитьURL(Знач URL, ПараметрыЗапроса = Неопределено)
	
	URL = СокрЛ(URL);
	
	СтруктураURL = КоннекторHTTP.РазобратьURL(URL);
	
	ПодготовленныйURL = СтруктураURL.Схема + "://";
	Если ЗначениеЗаполнено(СтруктураURL.Аутентификация.Пользователь) Тогда
		ПодготовленныйURL = ПодготовленныйURL 
			+ СтруктураURL.Аутентификация.Пользователь + ":"
			+ СтруктураURL.Аутентификация.Пароль + "@";
	КонецЕсли;
	ПодготовленныйURL = ПодготовленныйURL + СтруктураURL.Сервер;
	Если ЗначениеЗаполнено(СтруктураURL.Порт) Тогда
		ПодготовленныйURL = ПодготовленныйURL + ":" + Формат(СтруктураURL.Порт, "ЧРГ=; ЧГ=");
	КонецЕсли;
	
	ПодготовленныйURL = ПодготовленныйURL + СобратьАдресРесурса(СтруктураURL, ПараметрыЗапроса);
		
	Возврат ПодготовленныйURL;
	
КонецФункции

Функция ЗаголовкиВСтроку(Заголовки)
	
	РазделительСтрок = Символы.ВК + Символы.ПС;
	Строки = Новый Массив;
	
	СортированныеЗаголовки = "Content-Disposition,Content-Type,Content-Location";
	Для Каждого Ключ Из СтрРазделить(СортированныеЗаголовки, ",") Цикл
		Значение = ПолучитьЗначениеЗаголовка(Ключ, Заголовки);
		Если Значение <> Ложь И ЗначениеЗаполнено(Значение) Тогда
			Строки.Добавить(СтрШаблон("%1: %2", Ключ, Значение));
		КонецЕсли;
	КонецЦикла;
	
	Ключи = СтрРазделить(ВРег(СортированныеЗаголовки), ",");
	Для Каждого Заголовок Из Заголовки Цикл
		Если Ключи.Найти(ВРег(Заголовок.Ключ)) = Неопределено Тогда
			Строки.Добавить(СтрШаблон("%1: %2", Заголовок.Ключ, Заголовок.Значение));
		КонецЕсли;
	КонецЦикла;
	Строки.Добавить(РазделительСтрок);
	
	Возврат СтрСоединить(Строки, РазделительСтрок);
	
КонецФункции

Функция ПолучитьЗначениеПоКлючу(Структура, Ключ, ЗначениеПоУмолчанию = Неопределено)
	
	Если ТипЗнч(Структура) = Тип("Структура") И Структура.Свойство(Ключ) Тогда
		Значение = Структура[Ключ];
	ИначеЕсли ТипЗнч(Структура) = Тип("Соответствие") И Структура.Получить(Ключ) <> Неопределено Тогда
		Значение = Структура.Получить(Ключ);
	Иначе
		Значение = ЗначениеПоУмолчанию;
	КонецЕсли;
	
	Возврат Значение;
	
КонецФункции
	
Функция СоздатьПолеФормы(ИсходныеПараметры)
	
	Поле = Новый Структура("Имя,ИмяФайла,Данные,Тип,Заголовки");
	Поле.Имя = ИсходныеПараметры.Имя;
	Поле.Данные = ИсходныеПараметры.Данные;
	
	Поле.Тип = ПолучитьЗначениеПоКлючу(ИсходныеПараметры, "Тип");
	Поле.Заголовки = ПолучитьЗначениеПоКлючу(ИсходныеПараметры, "Заголовки", Новый Соответствие);
	Поле.ИмяФайла = ПолучитьЗначениеПоКлючу(ИсходныеПараметры, "ИмяФайла");
	
	Ключ = "Content-Disposition";
	Если ПолучитьЗначениеЗаголовка("content-disposition", Поле.Заголовки, Ключ) = Ложь Тогда
		Поле.Заголовки.Вставить("Content-Disposition", "form-data");
	КонецЕсли;
	
	Части = Новый Массив;
	Части.Добавить(Поле.Заголовки[Ключ]);
	Части.Добавить(СтрШаблон("name=""%1""", Поле.Имя));
	Если ЗначениеЗаполнено(Поле.ИмяФайла) Тогда
		Части.Добавить(СтрШаблон("filename=""%1""", Поле.ИмяФайла));
	КонецЕсли;
	
	Поле.Заголовки[Ключ] = СтрСоединить(Части, "; ");
	Поле.Заголовки["Content-Type"] = Поле.Тип;
	
	Возврат Поле;
	
КонецФункции

Функция ЗакодироватьФайлы(HTTPЗапрос, Файлы, Данные)
	
	Части = Новый Массив;
	Если ЗначениеЗаполнено(Данные) Тогда
		Для Каждого Поле Из Данные Цикл
			Части.Добавить(СоздатьПолеФормы(Новый Структура("Имя,Данные", Поле.Ключ, Поле.Значение)));
		КонецЦикла;
	КонецЕсли;
	Если ТипЗнч(Файлы) = Тип("Массив") Тогда
		Для Каждого Файл Из Файлы Цикл
			Части.Добавить(СоздатьПолеФормы(Файл));
		КонецЦикла;
	Иначе
		Части.Добавить(СоздатьПолеФормы(Файлы));
	КонецЕсли;
	
	Разделитель = СтрЗаменить(Новый УникальныйИдентификатор, "-", "");
	РазделительСтрок = Символы.ВК + Символы.ПС;
	
	ПотокДанных = Новый ПотокВПамяти();
	ЗаписьДанных = Новый ЗаписьДанных(
		ПотокДанных,
		КодировкаТекста.UTF8,
		ПорядокБайтов.LittleEndian,
		"",
		"",
		Ложь);
	Для Каждого Часть Из Части Цикл
		ЗаписьДанных.ЗаписатьСтроку("--" + Разделитель + РазделительСтрок);
		ЗаписьДанных.ЗаписатьСтроку(ЗаголовкиВСтроку(Часть.Заголовки));
		Если ТипЗнч(Часть.Данные) = Тип("ДвоичныеДанные") Тогда
			ЗаписьДанных.Записать(Часть.Данные);
		Иначе
			ЗаписьДанных.ЗаписатьСтроку(Часть.Данные);
		КонецЕсли;
		ЗаписьДанных.ЗаписатьСтроку(РазделительСтрок);
	КонецЦикла;
	ЗаписьДанных.ЗаписатьСтроку("--" + Разделитель + "--" + РазделительСтрок);
	HTTPЗапрос.УстановитьТелоИзДвоичныхДанных(ПотокДанных.ЗакрытьИПолучитьДвоичныеДанные());
	ЗаписьДанных.Закрыть();

	Возврат СтрШаблон("multipart/form-data; boundary=%1", Разделитель);
	
КонецФункции

Процедура ПодготовитьТелоЗапроса(ПодготовленныйЗапрос, Данные, Файлы, Json, ПараметрыЗаписиJSON)
	
	HTTPЗапрос = Новый HTTPЗапрос;
	HTTPЗапрос.АдресРесурса = СобратьАдресРесурса(
		КоннекторHTTP.РазобратьURL(ПодготовленныйЗапрос.URL), 
		ПодготовленныйЗапрос.ПараметрыЗапроса);
	Если ЗначениеЗаполнено(Файлы) Тогда
		ContentType = ЗакодироватьФайлы(HTTPЗапрос, Файлы, Данные);
	ИначеЕсли ЗначениеЗаполнено(Данные) Тогда
		ContentType = "application/x-www-form-urlencoded";
		Если ТипЗнч(Данные) = Тип("ДвоичныеДанные") Тогда
			HTTPЗапрос.УстановитьТелоИзДвоичныхДанных(Данные);
		Иначе
			Если ТипЗнч(Данные) = Тип("Строка") Тогда
				Тело = Данные;
			Иначе
				Тело = КодироватьПараметрыЗапроса(Данные);
			КонецЕсли;
			HTTPЗапрос.УстановитьТелоИзСтроки(Тело, КодировкаТекста.UTF8, ИспользованиеByteOrderMark.НеИспользовать);
		КонецЕсли;
	ИначеЕсли Json <> Неопределено Тогда
		ContentType = "application/json";
		HTTPЗапрос.УстановитьТелоИзСтроки(
			ОбъектВJson(Json, ПодготовленныйЗапрос.ПараметрыПреобразованияJSON, ПараметрыЗаписиJSON),
			КодировкаТекста.UTF8,
			ИспользованиеByteOrderMark.НеИспользовать);
	Иначе
		ContentType = Неопределено;
	КонецЕсли;
	ЗначениеЗаголовка = ПолучитьЗначениеЗаголовка("content-type", ПодготовленныйЗапрос.Заголовки);
	Если ЗначениеЗаголовка = Ложь И ЗначениеЗаполнено(ContentType) Тогда
		ПодготовленныйЗапрос.Заголовки.Вставить("Content-Type", ContentType);
	КонецЕсли;
	
	HTTPЗапрос.Заголовки = ПодготовленныйЗапрос.Заголовки;
	ПодготовленныйЗапрос.Вставить("HTTPЗапрос", HTTPЗапрос);
	
КонецПроцедуры

Процедура ПодготовитьАутентификацию(ПодготовленныйЗапрос)
	
	Если Не ЗначениеЗаполнено(ПодготовленныйЗапрос.Аутентификация) Тогда
		СтруктураURL = КоннекторHTTP.РазобратьURL(ПодготовленныйЗапрос.URL);
		Если ЗначениеЗаполнено(СтруктураURL.Аутентификация) Тогда
			ПодготовленныйЗапрос.Аутентификация = СтруктураURL.Аутентификация;
		КонецЕсли;
	КонецЕсли;

	Если ЗначениеЗаполнено(ПодготовленныйЗапрос.Аутентификация) Тогда
		Если ПодготовленныйЗапрос.Аутентификация.Свойство("Тип") Тогда
			ТипАутентификации = НРег(ПодготовленныйЗапрос.Аутентификация.Тип);
			Если ТипАутентификации = "aws4-hmac-sha256" Тогда
				ПодготовитьАутентификациюAWS4(ПодготовленныйЗапрос);
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

Функция ОбъединитьCookies(ГлавныйИсточник, ДополнительныйИсточник)
	
	Cookies = Новый Соответствие;
	Для Каждого Cookie Из ПреобразоватьХранилищеCookiesВМассивCookies(ГлавныйИсточник) Цикл
		ДобавитьCookieВХранилище(Cookies, Cookie, Ложь);
	КонецЦикла;
	Для Каждого Cookie Из ПреобразоватьХранилищеCookiesВМассивCookies(ДополнительныйИсточник) Цикл
		ДобавитьCookieВХранилище(Cookies, Cookie, Ложь);
	КонецЦикла;
	
	Возврат Cookies;
	
КонецФункции

Функция ПреобразоватьХранилищеCookiesВМассивCookies(ХранилищеCookies)
	
	Cookies = Новый Массив;
	Если ТипЗнч(ХранилищеCookies) = Тип("Массив") Тогда
		Для Каждого Cookie Из ХранилищеCookies Цикл
			НоваяCookie = КонструкторCookie();
			ЗаполнитьЗначенияСвойств(НоваяCookie, Cookie);
			Cookies.Добавить(НоваяCookie);
		КонецЦикла;
		
		Возврат Cookies;
	КонецЕсли;
	
	Для Каждого Домен Из ХранилищеCookies Цикл
		Для Каждого Путь Из Домен.Значение Цикл
			Для Каждого Наименование Из Путь.Значение Цикл
				Cookies.Добавить(Наименование.Значение);
			КонецЦикла;
		КонецЦикла;
	КонецЦикла;
	
	Возврат Cookies;
	
КонецФункции

Функция ОбъединитьПараметрыАутентификации(ГлавныйИсточник, ДополнительныйИсточник)
	
	ПараметрыАутентификации = Новый Структура;
	Если ТипЗнч(ГлавныйИсточник) = Тип("Структура") Тогда
		Для Каждого Параметр Из ГлавныйИсточник Цикл
			ПараметрыАутентификации.Вставить(Параметр.Ключ, Параметр.Значение);
		КонецЦикла;
	КонецЕсли;
	Если ТипЗнч(ДополнительныйИсточник) = Тип("Структура") Тогда
		Для Каждого Параметр Из ДополнительныйИсточник Цикл
			Если Не ПараметрыАутентификации.Свойство(Параметр) Тогда
				ПараметрыАутентификации.Вставить(Параметр.Ключ, Параметр.Значение);
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	Возврат ПараметрыАутентификации;
	
КонецФункции

Функция ОбъединитьЗаголовки(ГлавныйИсточник, ДополнительныйИсточник)
	
	Заголовки = Новый Соответствие;
	Для Каждого Заголовок Из ГлавныйИсточник Цикл
		Заголовки.Вставить(Заголовок.Ключ, Заголовок.Значение);
	КонецЦикла;
	Для Каждого Заголовок Из ДополнительныйИсточник Цикл
		Если Заголовки.Получить(Заголовок.Ключ) = Неопределено Тогда
			Заголовки.Вставить(Заголовок.Ключ, Заголовок.Значение);
		КонецЕсли;
	КонецЦикла;
	
	Возврат Заголовки;
	
КонецФункции

Функция ОбъединитьПараметрыЗапроса(ГлавныйИсточник, ДополнительныйИсточник)
	
	ПараметрыЗапроса = Новый Соответствие;
	Если ТипЗнч(ГлавныйИсточник) = Тип("Структура") ИЛИ ТипЗнч(ГлавныйИсточник) = Тип("Соответствие") Тогда
		Для Каждого Параметр Из ГлавныйИсточник Цикл
			ПараметрыЗапроса.Вставить(Параметр.Ключ, Параметр.Значение);
		КонецЦикла;
	КонецЕсли;
	Если ТипЗнч(ДополнительныйИсточник) = Тип("Структура") ИЛИ ТипЗнч(ДополнительныйИсточник) = Тип("Соответствие") Тогда
		Для Каждого Параметр Из ДополнительныйИсточник Цикл
			Если ПараметрыЗапроса.Получить(Параметр) = Неопределено Тогда
				ПараметрыЗапроса.Вставить(Параметр.Ключ, Параметр.Значение);
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	Возврат ПараметрыЗапроса;
	
КонецФункции

Функция ОтправитьHTTPЗапрос(Сессия, ПодготовленныйЗапрос, Настройки)
	
	Соединение = ПолучитьСоединение(
		КоннекторHTTP.РазобратьURL(ПодготовленныйЗапрос.URL), ПодготовленныйЗапрос.Аутентификация, Настройки);
	Возврат Соединение.ВызватьHTTPМетод(ПодготовленныйЗапрос.Метод, ПодготовленныйЗапрос.HTTPЗапрос);
	
КонецФункции

Функция ОтправитьЗапрос(Сессия, ПодготовленныйЗапрос, Настройки)
	
	Начало = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Ответ = ОтправитьHTTPЗапрос(Сессия, ПодготовленныйЗапрос, Настройки);
	
	ЗаголовокContentType = ПолучитьЗначениеЗаголовка("content-type", Ответ.Заголовки);
	Если ЗаголовокContentType = Ложь Тогда
		ЗаголовокContentType = "";
	КонецЕсли;
	
	ПодготовленныйОтвет = Новый ПодготовленныйОтвет(Ответ, ПодготовленныйЗапрос.ПараметрыПреобразованияJSON);
	ПодготовленныйОтвет.ВремяВыполнения = ТекущаяУниверсальнаяДатаВМиллисекундах() - Начало;
	ПодготовленныйОтвет.Cookies = ИзвлечьCookies(Ответ.Заголовки, ПодготовленныйЗапрос.URL); 
	ПодготовленныйОтвет.Заголовки = Ответ.Заголовки;
	ПодготовленныйОтвет.ЭтоПостоянныйРедирект = ЭтоПостоянныйРедирект(Ответ.КодСостояния, Ответ.Заголовки);
	ПодготовленныйОтвет.ЭтоРедирект = ЭтоРедирект(Ответ.КодСостояния, Ответ.Заголовки);
	ПодготовленныйОтвет.Кодировка = ПолучитьКодировкуИзЗаголовка(ЗаголовокContentType);
	ПодготовленныйОтвет.КодСостояния = Ответ.КодСостояния;
	ПодготовленныйОтвет.URL = ПодготовленныйЗапрос.URL;
	
	Сессия.Cookies = ОбъединитьCookies(Сессия.Cookies, ПодготовленныйОтвет.Cookies);
	
	Возврат ПодготовленныйОтвет;
	
КонецФункции

Процедура ПереопределитьМетод(ПодготовленныйЗапрос, Ответ)
	
	Метод = ПодготовленныйЗапрос.Метод;

	// http://tools.ietf.org/html/rfc7231#section-6.4.4
	Если Ответ.КодСостояния = КодыСостоянияHTTP.СмотретьДругое_303 И Метод <> "HEAD" Тогда
		Метод = "GET";
	КонецЕсли;
	
	// Поведение браузеров
	Если Ответ.КодСостояния = КодыСостоянияHTTP.ПеремещеноВременно_302 И Метод <> "HEAD" Тогда
		Метод = "GET";
	КонецЕсли;
	
	Если Ответ.КодСостояния = КодыСостоянияHTTP.ПеремещеноНавсегда_301 И Метод = "POST" Тогда
		Метод = "GET";
	КонецЕсли;
	
	ПодготовленныйЗапрос.Метод = Метод;
	
КонецПроцедуры	

Функция ИзвлечьCookies(Заголовки, URL)
	
	Cookies = Новый Соответствие;
	Для Каждого ОчереднойЗаголовок Из Заголовки Цикл
		Если НРег(ОчереднойЗаголовок.Ключ) = "set-cookie" Тогда
			Для Каждого ЗаголовокCookie Из РазбитьНаОтдельныеЗаголовкиCookies(ОчереднойЗаголовок.Значение) Цикл
				Cookie = РаспарситьCookie(ЗаголовокCookie, URL);
				Если Cookie <> Неопределено Тогда
					ДобавитьCookieВХранилище(Cookies, Cookie);
				КонецЕсли;
			КонецЦикла;
		КонецЕсли;
	КонецЦикла;	
	
	Возврат Cookies;
	
КонецФункции

Функция РазбитьНаОтдельныеЗаголовкиCookies(Знач Заголовок)
	
	Заголовки = Новый Массив;
	
	Если Не ЗначениеЗаполнено(Заголовок) Тогда
		Возврат Заголовки;
	КонецЕсли;
	
	ЗапчастиЗаголовков = СтрРазделить(Заголовок, ",", Ложь);
	
	ОтдельныйЗаголовок = ЗапчастиЗаголовков[0];
	Для Индекс = 1 По ЗапчастиЗаголовков.ВГраница() Цикл
		ТочкаяСЗапятой = СтрНайти(ЗапчастиЗаголовков[Индекс], ";");
		Равно = СтрНайти(ЗапчастиЗаголовков[Индекс], "=");
		Если ТочкаяСЗапятой И Равно И Равно < ТочкаяСЗапятой Тогда
			Заголовки.Добавить(ОтдельныйЗаголовок);
			ОтдельныйЗаголовок = ЗапчастиЗаголовков[Индекс];
		Иначе
			ОтдельныйЗаголовок = ОтдельныйЗаголовок + ЗапчастиЗаголовков[Индекс];
		КонецЕсли;
	КонецЦикла;
	Заголовки.Добавить(ОтдельныйЗаголовок);	
	
	Возврат Заголовки;
	
КонецФункции

Функция КонструкторCookie(Наименование = "", Значение = Неопределено)
	
	Cookie = Новый Структура;
	Cookie.Вставить("Наименование", Наименование);
	Cookie.Вставить("Значение", Значение);
	Cookie.Вставить("Домен", "");
	Cookie.Вставить("Путь", "");
	Cookie.Вставить("Порт", Неопределено);
	Cookie.Вставить("СрокДействия", Неопределено);
	Cookie.Вставить("ТолькоБезопасноеСоединение", Неопределено);

	Возврат Cookie;
	
КонецФункции

Функция СоздатьCookieИЗаполнитьОсновныеПараметры(Параметр)

	Части = СтрРазделить(Параметр, "=", Ложь);
	Наименование = Части[0];
	Если Части.Количество() > 1 Тогда
		Значение = Части[1];
	КонецЕсли;
	
	Возврат КонструкторCookie(Наименование, Значение);

КонецФункции

Функция РаспарситьCookie(Заголовок, URL)
	
	Cookie = Неопределено;
	Индекс = 0;
	
	Для Каждого Параметр Из СтрРазделить(Заголовок, ";", Ложь) Цикл
		Индекс = Индекс + 1;
		Параметр = СокрЛП(Параметр);
		
		Если Индекс = 1 Тогда
			Cookie = СоздатьCookieИЗаполнитьОсновныеПараметры(Параметр);
			Продолжить;
		КонецЕсли;
		
		Части = СтрРазделить(Параметр, "=", Ложь);
		Ключ = НРег(Части[0]);
		Если Части.Количество() > 1 Тогда
			Значение = Части[1];
		КонецЕсли;

		Если Ключ = "domain" Тогда
			Cookie.Домен = Значение;
		ИначеЕсли Ключ = "path" Тогда
			Cookie.Путь = Значение;
		ИначеЕсли Ключ = "secure" Тогда
			Cookie.ТолькоБезопасноеСоединение = Истина;
		Иначе
			Продолжить; // INFO: другие параметры пока игнорируются
		КонецЕсли; 
	КонецЦикла;

	Если Cookie = Неопределено Тогда
		Возврат Cookie;
	КонецЕсли;
	
	СтруктураURL = КоннекторHTTP.РазобратьURL(URL);
	Если Не ЗначениеЗаполнено(Cookie.Домен) Тогда
		Cookie.Домен = СтруктураURL.Сервер;
	КонецЕсли;
	Если Не ЗначениеЗаполнено(Cookie.Порт) И ЗначениеЗаполнено(СтруктураURL.Порт) Тогда
		Cookie.Порт = СтруктураURL.Порт;
	КонецЕсли;
	
	Возврат Cookie;
	
КонецФункции

Функция ПолучитьЗначениеЗаголовка(Заголовок, ВсеЗаголовки, Ключ = Неопределено)
	
	Для Каждого ОчереднойЗаголовок Из ВсеЗаголовки Цикл
		Если НРег(ОчереднойЗаголовок.Ключ) = НРег(Заголовок) Тогда
			Ключ = ОчереднойЗаголовок.Ключ;
			Возврат ОчереднойЗаголовок.Значение;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Ложь;
	
КонецФункции

Функция ЭтоПостоянныйРедирект(КодСостояния, Заголовки)
	
	Возврат ЕстьЗаголовокLocation(Заголовки) И 
		(КодСостояния = КодыСостоянияHTTP.ПеремещеноНавсегда_301 
		ИЛИ КодСостояния = КодыСостоянияHTTP.ПостоянноеПеренаправление_308);
	
КонецФункции

Функция ЭтоРедирект(КодСостояния, Заголовки)
	
	СостоянияРедиректа = Новый Массив;
	СостоянияРедиректа.Добавить(КодыСостоянияHTTP.ПеремещеноНавсегда_301);
	СостоянияРедиректа.Добавить(КодыСостоянияHTTP.ПеремещеноВременно_302);
	СостоянияРедиректа.Добавить(КодыСостоянияHTTP.СмотретьДругое_303);
	СостоянияРедиректа.Добавить(КодыСостоянияHTTP.ВременноеПеренаправление_307);
	СостоянияРедиректа.Добавить(КодыСостоянияHTTP.ПостоянноеПеренаправление_308);
	
	Возврат ЕстьЗаголовокLocation(Заголовки) И СостоянияРедиректа.Найти(КодСостояния) <> Неопределено;
	
КонецФункции

Функция ЕстьЗаголовокLocation(Заголовки)
	
	Возврат ПолучитьЗначениеЗаголовка("location", Заголовки) <> Ложь;
	
КонецФункции

Функция ПолучитьКодировкуИзЗаголовка(Знач Заголовок)

	Кодировка = Неопределено;
	
	Заголовок = НРег(СокрЛП(Заголовок));
	ИндексРазделителя = СтрНайти(Заголовок, ";");
	Если ИндексРазделителя Тогда
		ТипСодержимого = СокрЛП(Лев(Заголовок, ИндексРазделителя - 1));
		КлючКодировки = "charset=";
		ИндексКодировки = СтрНайти(Заголовок, КлючКодировки);
		Если ИндексКодировки Тогда
			ИндексРазделителя = СтрНайти(Заголовок, ";", НаправлениеПоиска.СНачала, ИндексКодировки);
			НачальнаяПозиция = ИндексКодировки + СтрДлина(КлючКодировки);
			Если ИндексРазделителя Тогда
				ДлинаКодировки = ИндексРазделителя - НачальнаяПозиция;
			Иначе
				ДлинаКодировки = СтрДлина(Заголовок);
			КонецЕсли;
			Кодировка = Сред(Заголовок, НачальнаяПозиция, ДлинаКодировки);
			Кодировка = СтрЗаменить(Кодировка, """", "");
			Кодировка = СтрЗаменить(Кодировка, "'", "");
		КонецЕсли;
	Иначе
		ТипСодержимого = Заголовок;
	КонецЕсли;
	
	Если Кодировка = Неопределено И СтрНайти(ТипСодержимого, "text") Тогда
		Кодировка = "iso-8859-1";
	КонецЕсли;
	
	Возврат Кодировка;
	
КонецФункции

Функция СобратьАдресРесурса(СтруктураURL, ПараметрыЗапроса)
	
	АдресРесурса = СтруктураURL.Путь;
	
	ОбъединенныеПараметрыЗапроса = ОбъединитьПараметрыЗапроса(ПараметрыЗапроса, СтруктураURL.ПараметрыЗапроса);
	Если ЗначениеЗаполнено(ОбъединенныеПараметрыЗапроса) Тогда
		АдресРесурса = АдресРесурса + "?" + КодироватьПараметрыЗапроса(ОбъединенныеПараметрыЗапроса);
	КонецЕсли;
	Если ЗначениеЗаполнено(СтруктураURL.Фрагмент) Тогда
		АдресРесурса = АдресРесурса + "#" + СтруктураURL.Фрагмент;
	КонецЕсли;
	
	Возврат АдресРесурса;
	
КонецФункции

Функция ПолучитьСоединение(ПараметрыСоединения, Аутентификация, ДополнительныеПараметры)
	
	Если Не ЗначениеЗаполнено(ПараметрыСоединения.Порт) Тогда
		Если ПараметрыСоединения.Схема = "https" Тогда
			ПараметрыСоединения.Порт = 443;
		Иначе
			ПараметрыСоединения.Порт = 80;
		КонецЕсли;
	КонецЕсли;
	
	Пользователь = "";
	Пароль = "";
	Если ЗначениеЗаполнено(Аутентификация) Тогда
		Если Аутентификация.Свойство("Пользователь") И Аутентификация.Свойство("Пароль") Тогда
			Пользователь = Аутентификация.Пользователь;
			Пароль = Аутентификация.Пароль;
		КонецЕсли;
	КонецЕсли;
	
	ПараметрыПодключения = Новый Структура;
	ПараметрыПодключения.Вставить("Схема", ПараметрыСоединения.Схема);
	ПараметрыПодключения.Вставить("Сервер", ПараметрыСоединения.Сервер);
	ПараметрыПодключения.Вставить("Порт", ПараметрыСоединения.Порт);
	ПараметрыПодключения.Вставить("Пользователь", Пользователь);
	ПараметрыПодключения.Вставить("Пароль", Пароль);
	ПараметрыПодключения.Вставить("Прокси", ДополнительныеПараметры.Прокси);
	ПараметрыПодключения.Вставить("Таймаут", ДополнительныеПараметры.Таймаут);

	Возврат мПулСоединений.Получить(ПараметрыПодключения); 

КонецФункции

Функция ВыбратьЗначение(ОсновноеЗначение, ДополнительныеЗначения, Ключ, ЗначениеПоУмолчанию)
	
	Если ОсновноеЗначение <> Неопределено Тогда
		Возврат ОсновноеЗначение;
	КонецЕсли;
	
	Значение = ПолучитьЗначениеПоКлючу(ДополнительныеЗначения, Ключ);
	Если Значение <> Неопределено Тогда
		Возврат Значение;
	КонецЕсли;
	
	Возврат ЗначениеПоУмолчанию;
	
КонецФункции

Функция ХешированиеДанных(Знач Алгоритм, Знач Данные) Экспорт
	
	Если ТипЗнч(Данные) = Тип("Строка") Тогда
		Данные = ПолучитьДвоичныеДанныеИзСтроки(Данные, КодировкаТекста.UTF8, Ложь);
	КонецЕсли;
	
	Хеширование = Новый ХешированиеДанных(Алгоритм);
	Хеширование.Добавить(Данные);
	
	Возврат НРег(ПолучитьHexСтрокуИзДвоичныхДанных(Хеширование.ХешСумма));
	
КонецФункции

#Область АутентификацияAWS4

Функция ПолучитьКлючПодписиAWS4(СекретныйКлюч, Дата, Регион, Сервис)
	
	КлючДата = ПодписатьСообщениеHMAC("AWS4" + СекретныйКлюч, Дата);
	КлючРегион = ПодписатьСообщениеHMAC(КлючДата, Регион);
	КлючСервис = ПодписатьСообщениеHMAC(КлючРегион, Сервис);
	
	Возврат ПодписатьСообщениеHMAC(КлючСервис, "aws4_request");
	
КонецФункции

Функция ПодписатьСообщениеHMAC(Знач Ключ, Знач Сообщение, Знач Алгоритм = Неопределено)
	
	Если Алгоритм = Неопределено Тогда
		Алгоритм = ХешФункция.SHA256;
	КонецЕсли;
	
	Если ТипЗнч(Ключ) = Тип("Строка") Тогда
		Ключ = ПолучитьДвоичныеДанныеИзСтроки(Ключ, КодировкаТекста.UTF8, Ложь);
	КонецЕсли;
	Если ТипЗнч(Сообщение) = Тип("Строка") Тогда
		Сообщение = ПолучитьДвоичныеДанныеИзСтроки(Сообщение, КодировкаТекста.UTF8, Ложь);
	КонецЕсли;

	Возврат КоннекторHTTP.HMAC(Ключ, Сообщение, Алгоритм);
	
КонецФункции

Процедура ПодготовитьАутентификациюAWS4(ПодготовленныйЗапрос)

	ТекущееВремя = ТекущаяУниверсальнаяДата();
	ПодготовленныйЗапрос.Заголовки["x-amz-date"] = Формат(ТекущееВремя, "ДФ=yyyyMMddTHHmmssZ");
	ОбластьДействияДата = Формат(ТекущееВремя, "ДФ=yyyyMMdd");
	
	ПодготовленныйЗапрос.Заголовки["x-amz-content-sha256"] = ХешированиеДанных(
		ХешФункция.SHA256, ПодготовленныйЗапрос.HTTPЗапрос.ПолучитьТелоКакПоток());
	
	СтруктураURL = КоннекторHTTP.РазобратьURL(ПодготовленныйЗапрос.URL);
	
	КаноническиеЗаголовки = ПолучитьКаноническиеЗаголовкиAWS4(ПодготовленныйЗапрос.Заголовки, СтруктураURL.Сервер);
	
	КаноническийПуть = СтруктураURL.Путь;
	КаноническиеПараметрыЗапроса = ПолучитьКаноническиеПараметрыЗапросаAWS4(СтруктураURL.ПараметрыЗапроса);
	
	ЧастиЗапроса = Новый Массив;
	ЧастиЗапроса.Добавить(ПодготовленныйЗапрос.Метод);
	ЧастиЗапроса.Добавить(КаноническийПуть);
	ЧастиЗапроса.Добавить(КаноническиеПараметрыЗапроса);
	ЧастиЗапроса.Добавить(КаноническиеЗаголовки.КаноническиеЗаголовки);
	ЧастиЗапроса.Добавить(КаноническиеЗаголовки.ПодписываемыеЗаголовки);
	ЧастиЗапроса.Добавить(ПодготовленныйЗапрос.Заголовки["x-amz-content-sha256"]);
	КаноническийЗапрос = СтрСоединить(ЧастиЗапроса, Символы.ПС);
	
	ЧастиОбластиДействия = Новый Массив;
	ЧастиОбластиДействия.Добавить(ОбластьДействияДата);
	ЧастиОбластиДействия.Добавить(ПодготовленныйЗапрос.Аутентификация.Регион);
	ЧастиОбластиДействия.Добавить(ПодготовленныйЗапрос.Аутентификация.Сервис);
	ЧастиОбластиДействия.Добавить("aws4_request");
	ОбластьДействия = СтрСоединить(ЧастиОбластиДействия, "/");
	
	ЧастиСтрокиДляПодписи = Новый Массив;
	ЧастиСтрокиДляПодписи.Добавить(ПодготовленныйЗапрос.Аутентификация.Тип);
	ЧастиСтрокиДляПодписи.Добавить(ПодготовленныйЗапрос.Заголовки["x-amz-date"]);
	ЧастиСтрокиДляПодписи.Добавить(ОбластьДействия);
	ЧастиСтрокиДляПодписи.Добавить(ХешированиеДанных(ХешФункция.SHA256, КаноническийЗапрос));
	СтрокаДляПодписи = СтрСоединить(ЧастиСтрокиДляПодписи, Символы.ПС);
	
	Ключ = ПолучитьКлючПодписиAWS4(
		ПодготовленныйЗапрос.Аутентификация.СекретныйКлюч,
		ОбластьДействияДата,
		ПодготовленныйЗапрос.Аутентификация.Регион,
		ПодготовленныйЗапрос.Аутентификация.Сервис);
	Подпись = НРег(ПолучитьHexСтрокуИзДвоичныхДанных(ПодписатьСообщениеHMAC(Ключ, СтрокаДляПодписи)));
	
	ПодготовленныйЗапрос.Заголовки["Authorization"] = СтрШаблон(
		"%1 Credential=%2/%3, SignedHeaders=%4, Signature=%5",
		ПодготовленныйЗапрос.Аутентификация.Тип,
		ПодготовленныйЗапрос.Аутентификация.ИдентификаторКлючаДоступа,
		ОбластьДействия,
		КаноническиеЗаголовки.ПодписываемыеЗаголовки,
		Подпись);
	
	ПодготовленныйЗапрос.HTTPЗапрос.Заголовки = ПодготовленныйЗапрос.Заголовки;

КонецПроцедуры

Функция ПолучитьКаноническиеЗаголовкиAWS4(Заголовки, Сервер)
	
	Список = Новый СписокЗначений;
	
	ЗаголовокHostЕстьВЗапросе = Ложь;
	ЗаголовкиПоУмолчанию = ЗаголовкиПоУмолчаниюAWS4();
	Для Каждого ОчереднойЗаголовок Из Заголовки Цикл
		Заголовок = НРег(ОчереднойЗаголовок.Ключ);
		Если ЗаголовкиПоУмолчанию.Исключения.Найти(Заголовок) <> Неопределено Тогда
			Продолжить;
		КонецЕсли;
		ЗаголовокHostЕстьВЗапросе = Заголовок = "host";
		
		Если ЗаголовкиПоУмолчанию.Равно.Найти(Заголовок) <> Неопределено Тогда
			Список.Добавить(Заголовок, СокрЛП(ОчереднойЗаголовок.Значение));
		Иначе
			Для Каждого Префикс Из ЗаголовкиПоУмолчанию.НачинаетсяС Цикл
				Если СтрНачинаетсяС(Заголовок, Префикс) Тогда
					Список.Добавить(Заголовок, СокрЛП(ОчереднойЗаголовок.Значение));
					Прервать;
				КонецЕсли;
			КонецЦикла;
		КонецЕсли;
	КонецЦикла;
	
	Если Не ЗаголовокHostЕстьВЗапросе Тогда
		Список.Добавить("host", Сервер);
	КонецЕсли;
	
	Список.СортироватьПоЗначению(НаправлениеСортировки.Возр);
	
	КаноническиеЗаголовки = Новый Массив;
	ПодписываемыеЗаголовки = Новый Массив;
	Для Каждого ЭлементСписка Из Список Цикл
		КаноническиеЗаголовки.Добавить(ЭлементСписка.Значение + ":" + ЭлементСписка.Представление);
		ПодписываемыеЗаголовки.Добавить(ЭлементСписка.Значение);
	КонецЦикла;
	КаноническиеЗаголовки.Добавить("");
	
	Возврат Новый Структура(
		"КаноническиеЗаголовки, ПодписываемыеЗаголовки",
		СтрСоединить(КаноническиеЗаголовки, Символы.ПС),
		СтрСоединить(ПодписываемыеЗаголовки, ";"));
	
КонецФункции

Функция ПолучитьКаноническиеПараметрыЗапросаAWS4(ПараметрыЗапроса)
	
	Список = Новый СписокЗначений;
	Для Каждого ОчереднойПараметрЗапроса Из ПараметрыЗапроса Цикл
		Список.Добавить(ОчереднойПараметрЗапроса.Ключ, СокрЛП(ОчереднойПараметрЗапроса.Значение));
	КонецЦикла;
	Список.СортироватьПоЗначению(НаправлениеСортировки.Возр);
	
	КаноническиеПараметры = Новый Массив;
	Для Каждого ЭлементСписка Из Список Цикл
		ЗначениеПараметра = КодироватьСтроку(ЭлементСписка.Представление, СпособКодированияСтроки.КодировкаURL);
		КаноническиеПараметры.Добавить(ЭлементСписка.Значение + "=" + ЗначениеПараметра);
	КонецЦикла;
	
	Возврат СтрСоединить(КаноническиеПараметры, "&");
		
КонецФункции

Функция ЗаголовкиПоУмолчаниюAWS4()
	
	Заголовки = Новый Структура;
	Заголовки.Вставить("Равно", СтрРазделить("host,content-type,date", ","));
	Заголовки.Вставить("НачинаетсяС", СтрРазделить("x-amz-", ","));
	Заголовки.Вставить("Исключения", СтрРазделить("x-amz-client-context", ","));
	
	Возврат Заголовки;
	
КонецФункции

#КонецОбласти

Функция ОбъектВJson(Объект, Знач ПараметрыПреобразования, Знач ПараметрыЗаписи) Экспорт
	
	ПараметрыПреобразованияJSON = ДополнитьПараметрыПреобразованияJSON(ПараметрыПреобразования);

	ПараметрыЗаписи = ДополнитьПараметрыЗаписиJSON(ПараметрыЗаписи);
	
	ПараметрыЗаписиJSON = Новый ПараметрыЗаписиJSON(
		ПараметрыЗаписи.ПереносСтрок,
		ПараметрыЗаписи.СимволыОтступа,
		ПараметрыЗаписи.ИспользоватьДвойныеКавычки,
		ПараметрыЗаписи.ЭкранированиеСимволов,
		ПараметрыЗаписи.ЭкранироватьУгловыеСкобки,
		ПараметрыЗаписи.ЭкранироватьРазделителиСтрок,
		ПараметрыЗаписи.ЭкранироватьАмперсанд,
		ПараметрыЗаписи.ЭкранироватьОдинарныеКавычки,
		ПараметрыЗаписи.ЭкранироватьСлеш);
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку(ПараметрыЗаписиJSON);
	ЗаписатьJSON(ЗаписьJSON, Объект);

	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции

Функция JsonВОбъект(Json, ПараметрыПреобразования) Экспорт
	
	ПараметрыПреобразованияJSON = ДополнитьПараметрыПреобразованияJSON(ПараметрыПреобразования);
	
	ЧтениеJSON = Новый ЧтениеJSON;
	ЧтениеJSON.УстановитьСтроку(Json);
	
	Объект = ПрочитатьJSON(
		ЧтениеJSON, 
		ПараметрыПреобразованияJSON.ПрочитатьВСоответствие,
		ПараметрыПреобразованияJSON.ИменаСвойствСоЗначениямиДата,
		ПараметрыПреобразованияJSON.ФорматДатыJSON);
	ЧтениеJSON.Закрыть();
	
	Возврат Объект;

КонецФункции

Функция ДополнитьПараметрыПреобразованияJSON(ПараметрыПреобразования)
	
	ПараметрыПреобразованияJSON = ПолучитьПараметрыПреобразованияJSONПоУмолчанию();
	Если ЗначениеЗаполнено(ПараметрыПреобразования) Тогда
		Для Каждого Параметр Из ПараметрыПреобразования Цикл
			Если ПараметрыПреобразованияJSON.Свойство(Параметр.Ключ) Тогда
				ПараметрыПреобразованияJSON.Вставить(Параметр.Ключ, Параметр.Значение);
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	Возврат ПараметрыПреобразованияJSON;
	
КонецФункции

Функция ДополнитьПараметрыЗаписиJSON(ПараметрыЗаписи)
	
	ПараметрыЗаписиJSON = ПолучитьПараметрыЗаписиJSONПоУмолчанию();
	Если ЗначениеЗаполнено(ПараметрыЗаписи) Тогда
		Для Каждого Параметр Из ПараметрыЗаписи Цикл
			Если ПараметрыЗаписиJSON.Свойство(Параметр.Ключ) Тогда
				ПараметрыЗаписиJSON.Вставить(Параметр.Ключ, Параметр.Значение);
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	Возврат ПараметрыЗаписиJSON;
	
КонецФункции

Функция СтандартныйТаймаут()
	
	Возврат 30;
	
КонецФункции

Функция ПолучитьПараметрыПреобразованияJSONПоУмолчанию()
	
	ПараметрыПреобразованияПоУмолчанию = Новый Структура;
	ПараметрыПреобразованияПоУмолчанию.Вставить("ПрочитатьВСоответствие", Истина);
	ПараметрыПреобразованияПоУмолчанию.Вставить("ФорматДатыJSON", ФорматДатыJSON.ISO);
	ПараметрыПреобразованияПоУмолчанию.Вставить("ИменаСвойствСоЗначениямиДата", Новый Массив());
	
	Возврат ПараметрыПреобразованияПоУмолчанию;
	
КонецФункции

Функция ПолучитьПараметрыЗаписиJSONПоУмолчанию()
	
	ПараметрыЗаписиJSONПоУмолчанию = Новый Структура;
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ПереносСтрок", ПереносСтрокJSON.Авто);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("СимволыОтступа", " ");
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ИспользоватьДвойныеКавычки", Истина);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ЭкранированиеСимволов", ЭкранированиеСимволовJSON.Нет);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ЭкранироватьУгловыеСкобки", Ложь);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ЭкранироватьРазделителиСтрок", Истина);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ЭкранироватьАмперсанд", Ложь);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ЭкранироватьОдинарныеКавычки", Ложь);
	ПараметрыЗаписиJSONПоУмолчанию.Вставить("ЭкранироватьСлеш", Ложь);
	
	Возврат ПараметрыЗаписиJSONПоУмолчанию;
	
КонецФункции

мПулСоединений = Новый ПулСоединений();
