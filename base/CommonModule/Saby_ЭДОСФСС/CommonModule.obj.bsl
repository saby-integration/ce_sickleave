
#Область ОтправкаСообщенияСЭДО

Функция ОтправитьСообщениеСЭДОЧерезAPIСБИС(ПараметрыСообщения) Экспорт

	Результат = Новый Структура("Отправлено, ОписаниеОшибки", Истина, "");	
	
	ПараметрыСообщенияЭДО = ДокументооборотСКО.ПолучитьОбработкуЭДО();
	ОтпечаткиСертификатов = ПараметрыСообщенияЭДО.ПолучитьОтпечаткиСертификатовИзНастроекОрганизацииДляФСС(
		ПараметрыСообщения.Организация
	);
	ПараметрыСообщения.Вставить(
		"СертификатСтрахователяОтпечаток", 
		ОтпечаткиСертификатов.СертификатСтрахователяОтпечаток
	);	
	
	Попытка   
		// Вызовите метод «СБИС.ЗаписатьКомплект» для подготовки документа к отправке.
		// На этом этапе документ появлется в списке больничных в СБИС
		Документ = ЗаписатьКомплект(ПараметрыСообщения);	
		
		// Необходимо для отправки запроса в ФСС. На этом этапе передаем подписанный запрос
		// СБИС сразу запрос не отправляет, он делает это асинхронно. Запрос может уйти и через 30 минут 
		ПодготовитьВыполнитьДействие(Документ, ПараметрыСообщения);
		
		// Сохраняем связь уида докумнета сбис и ссылки 1С
		ОбработкаСБИС = Обработки.SABY.Создать();
		ОбработкаСБИС.СтатусыДокументовОбновить(Документ["Идентификатор"],,, ПараметрыСообщения.СсылкаНаДокумент, "0");
		ОтправитьДействиеНаСерверСтатистики("Robot", "Отправка проактивных больничных", ОбработкаСБИС);
	Исключение 
		Результат.Отправлено = Ложь;
		ИнфОбОшибке = ИнформацияОбОшибке();
		ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
		Результат.ОписаниеОшибки = "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
		ОтправитьОшибкуНаСерверСтатистики("Robot", "Отправка проактивных больничных", ОшибкаСтруктура, ОбработкаСБИС);
	КонецПопытки;
			
	Возврат Результат;
	
КонецФункции 

Функция ЗаписатьКомплект(ПараметрыСообщения)
	
	ОбработкаСБИС = Обработки.SABY.Создать();		
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	
	Комплект = ПолучитьСтруктуруОтправляемогоКомплекта( 
		ПараметрыСообщения
	);	
	РезультатЗаписиКомплекта = ОбработкаСБИС.local_helper_write_kit(context_params, Комплект); 
	
	Возврат РезультатЗаписиКомплекта[0] 
	
КонецФункции

Функция ПолучитьСтруктуруОтправляемогоКомплекта(ПараметрыСообщения)
	
	Комплект = Новый Структура;	
	
	Сотрудник = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(
		ПараметрыСообщения.СсылкаНаДокумент,
		"Сотрудник"
	);
	
	// Может есть фукнция API для получения идентификатора из СБИС. Если она есть, то лучше использовать её.
	Комплект.Вставить("Идентификатор", Строка(Новый УникальныйИдентификатор));
	Комплект.Вставить(
		"Расширение", 
		Новый Структура("ИдентификаторКомплекта", Строка(Новый УникальныйИдентификатор))
	);               
	Комплект.Вставить("Тип", "ДокументСЭДО");
	Комплект.Вставить("ПодТип", "");
	Комплект.Вставить("ДатаВремяСоздания", МестноеВремя(ТекущаяУниверсальнаяДата(), "Europe/Moscow"));
	
	НашаОрганизация = Saby_ЭДОСФССПовтИсп.Saby_НашаОрганизация(ПараметрыСообщения.Организация);
	Комплект.Вставить("НашаОрганизация", НашаОрганизация);
				
	Участники = Новый Структура;
	Участники.Вставить("Отправитель", НашаОрганизация); 
	Участники.Вставить("Получатель", Новый Структура("ГосударственнаяИнспекция", "ЕФСС"));
	Участники.Вставить("КонечныйПолучатель", Новый Структура("ГосударственнаяИнспекция", "ЕФСС")); 
	Комплект.Вставить("Участники", Участники);
	
	Комплект.Вставить("Вложение", Новый Массив);
	Вложение = Новый Структура;
	Вложение.Вставить("Идентификатор", Строка(Новый УникальныйИдентификатор));
	Вложение.Вставить("Название", Строка(Сотрудник));	
	Вложение.Вставить("Категория", "Основное");	
	Вложение.Вставить(
		"ПодТип", 
		Saby_ЭДОСФССПовтИсп.ПодтипВложенияПоТипуСообщения(ПараметрыСообщения.ТипСообщения)
	);	
	Вложение.Вставить("Направление", "Исходящий");	
	Вложение.Вставить("ВерсияФормата", "1.0");		
	Вложение.Вставить("Файл", ПолучитьСтруктуруОтправляемогоФайла(ПараметрыСообщения));		
	Комплект.Вложение.Добавить(Вложение);
		
	Комплект.Вставить("Сертификат", Новый Структура);
	Комплект.Сертификат.Вставить("Отпечаток", ПараметрыСообщения.СертификатСтрахователяОтпечаток);
		
	
	Описание = Новый Структура;
	Описание.Вставить("ВидДокумента", "первичный");
	Описание.Вставить(
		"ИмяФормы",
		Saby_ЭДОСФССПовтИсп.ИмяФормыПоТипуСообщения(ПараметрыСообщения.ТипСообщения)
	);
	Описание.Вставить(
		"КНДФормы", 
		Saby_ЭДОСФССПовтИсп.ПодтипВложенияПоТипуСообщения(ПараметрыСообщения.ТипСообщения)
	);
	Описание.Вставить("КолФайл", "1"); 

	РеквизитыФизическогоЛица = ПолучитьРеквизитыФизическогоЛица(Сотрудник);

	Описание.Вставить("СНИЛС", РеквизитыФизическогоЛица.СтраховойНомерПФР);
	Описание.Вставить(
		"ФИО", 
		Новый Структура(
			"Имя, Отчество, Фамилия", 
			РеквизитыФизическогоЛица.Имя, 
			РеквизитыФизическогоЛица.Отчество, 
			РеквизитыФизическогоЛица.Фамилия
		)
	);
	
	Сведения = Новый Структура;
	Сведения.Вставить("Описание", Описание);
	Сведения.Вставить(
		"Пакет", 
		Новый Структура(
			"ВерсПрог, ПрограммаФормированияОтчета", 
			Метаданные.Версия, 
			Метаданные.Имя
		)
	);    	
	Комплект.Вставить("Сведения", Сведения);
	
	Возврат Комплект;
		
КонецФункции

Функция ПолучитьСтруктуруОтправляемогоФайла(ПараметрыСообщения)
	
	СтруктураФайла = Новый Структура;
	СодержимоеСообщения = ?(
		ЭтоАдресВременногоХранилища(ПараметрыСообщения.СодержимоеИлиАдресСообщения),
		ПолучитьИзВременногоХранилища(ПараметрыСообщения.СодержимоеИлиАдресСообщения),
		ПараметрыСообщения.СодержимоеИлиАдресСообщения
	);
	
	ПотокВПамяти = Новый ПотокВПамяти;	
	
	ЗаписьXML = Новый ЗаписьXML;
	ЗаписьXML.ОткрытьПоток(ПотокВПамяти, "UTF-8", Ложь);
	ЗаписьXML.ЗаписатьОбъявлениеXML(); 
	ЗаписьXML.ЗаписатьБезОбработки(СодержимоеСообщения);
	ЗаписьXML.Закрыть();	
	
	ИмяФайла = СтрШаблон(
		"%1_%2_%3_%4.xml",
		Saby_ЭДОСФССПовтИсп.ПодтипВложенияПоТипуСообщения(ПараметрыСообщения.ТипСообщения),
		ПараметрыСообщения.РегистрационныйНомерФСС,
		Формат(ТекущаяДата(), "ДФ=yyyy_MM_dd"),
		Строка(Новый УникальныйИдентификатор)
	); 
	СтруктураФайла.Вставить("Имя", ИмяФайла); 
	
	СтруктураФайла.Вставить("ДвоичныеДанные", Base64Строка(ПотокВПамяти.ЗакрытьИПолучитьДвоичныеДанные()));
	
	Возврат СтруктураФайла
	
КонецФункции

#Область include_sickleave_base_CommonModule_ПолучитьРеквизитыФизическогоЛица
#КонецОбласти

#КонецОбласти



#Область ПолучениеСпискаИзмененийИСпискаСлужебныхЭтапов

Функция СписокИзмененийПоДокументамСЭДО(context_params, Фильтр) Экспорт

	ОбработкаСБИС = Обработки.SABY.Создать();
	Если context_params.Количество() = 0 Тогда                              //при получении сообщений за период
		context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	КонецЕсли;
	Попытка
		СписокИзменений = ОбработкаСБИС.local_helper_read_changes(context_params, Фильтр);
		Если СписокИзменений["Навигация"]["ЕстьЕще"] <> "Да" Тогда
			ОтправитьДействиеНаСерверСтатистики("Robot", "Получение проактивных больничных", ОбработкаСБИС, context_params);
		КонецЕсли;
	Исключение
		ИнфОбОшибке = ИнформацияОбОшибке();
		ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
		Если Найти(нрег(ОшибкаСтруктура.message), "не найдено событие с идентификатором")>0 Тогда
			Фильтр.Удалить("ИдентификаторСобытия");
			Попытка
				СписокИзменений = ОбработкаСБИС.local_helper_read_changes(context_params, Фильтр);
				Если СписокИзменений["Навигация"]["ЕстьЕще"] <> "Да" Тогда
					ОтправитьДействиеНаСерверСтатистики("Robot", "Получение проактивных больничных", ОбработкаСБИС, context_params);
				КонецЕсли;
			Исключение
				ИнфОбОшибке = ИнформацияОбОшибке();
				ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
				ОтправитьОшибкуНаСерверСтатистики("Robot", "Получение проактивных больничных", ОшибкаСтруктура,
					ОбработкаСБИС, context_params);
				ВызватьИсключение "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
			КонецПопытки;
		Иначе
			ОтправитьОшибкуНаСерверСтатистики("Robot", "Получение проактивных больничных", ОшибкаСтруктура,
				ОбработкаСБИС, context_params);
			ВызватьИсключение "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
		КонецЕсли;
	КонецПопытки;
	Возврат СписокИзменений;
	
КонецФункции

Функция СписокСлужебныхЭтаповПоДокументамСЭДО(context_params, Фильтр) Экспорт
	
	ОбработкаСБИС = Обработки.SABY.Создать();
	Если context_params.Количество() = 0 Тогда
		context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	КонецЕсли;
	Попытка
		СписокСлужебныхЭтапов = ОбработкаСБИС.local_helper_read_service_changes(context_params, Фильтр);
	Исключение
		ИнфОбОшибке = ИнформацияОбОшибке();
		ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
		ОтправитьОшибкуНаСерверСтатистики("Robot", "Получение проактивных больничных", ОшибкаСтруктура,
			ОбработкаСБИС, context_params);
		ВызватьИсключение "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
	КонецПопытки;
	
	Возврат СписокСлужебныхЭтапов;
	
КонецФункции

#КонецОбласти


#Область ВспомогательныеФункции

Процедура ОтправитьДействиеНаСерверСтатистики(Действие, КонтекстДействия,
		ОбработкаСБИС = Неопределено, context_params = Неопределено)
		
	Если ОбработкаСБИС = Неопределено Тогда
		ОбработкаСБИС = Обработки.SABY.Создать();
	КонецЕсли;
	
	Если context_params = Неопределено Тогда
		context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	КонецЕсли;
	
	ЭлементСтатистики = ОбработкаСБИС.local_helper_element_action(Действие, КонтекстДействия, Новый Структура(), 1);
	
	МассивУспехов = Новый Массив;
 	МассивУспехов.Добавить(ЭлементСтатистики);
	
	ОбработкаСБИС.local_helper_register_actions(context_params, МассивУспехов);
	
КонецПроцедуры

Процедура ОтправитьОшибкуНаСерверСтатистики(Действие, КонтекстДействия, ОшибкаСтруктура,
		ОбработкаСБИС = Неопределено, context_params = Неопределено)
		
	Если ОбработкаСБИС = Неопределено Тогда
		ОбработкаСБИС = Обработки.SABY.Создать();
	КонецЕсли;
	
	Если context_params = Неопределено Тогда
		context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	КонецЕсли;
	
	ЭлементСтатистики = ОбработкаСБИС.local_helper_element_err(Действие, КонтекстДействия,
		ОшибкаСтруктура.message, ОшибкаСтруктура.detail, Новый Структура(), 500, 1);
	
	МассивОшибок = Новый Массив;
	МассивОшибок.Добавить(ЭлементСтатистики);
	
	ОбработкаСБИС.local_helper_register_errors(context_params, МассивОшибок);
	
КонецПроцедуры

Функция ПолучитьЗначениеФункциональнойОпции(ИмяФункциональнойОпции) Экспорт
	
	Возврат ПолучитьФункциональнуюОпцию(ИмяФункциональнойОпции);
	
КонецФункции

Функция ПолучитьНастройкиПодключения() Экспорт
	ОбработкаСБИС = Обработки.SABY.Создать();	
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	Возврат context_params;
КонецФункции

Функция ЗаписатьНастройкиПодключения(Ключ, Значение) Экспорт
	ОбработкаСБИС = Обработки.SABY.Создать();
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();	
	context_params.Вставить(Ключ, Значение);
	ОбработкаСБИС.НастройкиПодключенияЗаписать(context_params);
КонецФункции

Функция ПодготовитьВыполнитьДействие(Документ, ПараметрыСообщения) Экспорт

	РезультатВыполненияДействия = ПодготвитьДействие(Документ, ПараметрыСообщения);
	
	Возврат ВыполнитьДействие(РезультатВыполненияДействия, ПараметрыСообщения);
	
КонецФункции

Функция ПодготвитьДействие(Документ, ПараметрыСообщения) Экспорт

	ОбработкаСБИС = Обработки.SABY.Создать();		
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	
	ПодготовливаемоеДействие = ПолучитьСтруктуруПодготовливаемогоДействия(Документ, ПараметрыСообщения);
	Попытка
		Возврат ОбработкаСБИС.local_helper_prepare_action(
		context_params, 
		ПодготовливаемоеДействие
		);
	Исключение
		ИнфОбОшибке = ИнформацияОбОшибке();
		ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
		ВызватьИсключение "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
	КонецПопытки;		
	
КонецФункции

Функция ВыполнитьДействие(РезультатПодготовкиДействия, ПараметрыСообщения) Экспорт
	
	ОбработкаСБИС = Обработки.SABY.Создать();		
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
		
	ВыполняемоеДействие = ПолучитьСтруктуруВыполняемогоДействия(РезультатПодготовкиДействия, ПараметрыСообщения); 
	Попытка
		РезультатВыполненияДействия = ОбработкаСБИС.local_helper_execute_action(context_params, ВыполняемоеДействие);
	Исключение
		ИнфОбОшибке = ИнформацияОбОшибке();
		ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
		ВызватьИсключение "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
	КонецПопытки;
	
	Возврат РезультатВыполненияДействия;
	
КонецФункции

Функция ОтложитьСлужебныйЭтап(Документ) Экспорт
	
	ОбработкаСБИС = Обработки.SABY.Создать();		
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать();
	
	ОтложенноеДействие = ПолучитьСтруктуруПодготовливаемогоДействия(Документ, Неопределено);
	Попытка
		РезультатВыполнения = ОбработкаСБИС.local_helper_delay_service_stage(context_params, ОтложенноеДействие);
	Исключение
		ИнфОбОшибке = ИнформацияОбОшибке();
		ОшибкаСтруктура = NewExtExceptionСтруктура(ИнфОбОшибке);
		ВызватьИсключение "" + ОшибкаСтруктура.action + " " + ОшибкаСтруктура.message + " " + ОшибкаСтруктура.detail;
	КонецПопытки;
	
	Возврат РезультатВыполнения;
	
КонецФункции

Функция ЗагрузитьСообщениеФССXMLИзСбис(СсылкаНаФайл) Экспорт
	
	ОбработкаСБИС = Обработки.SABY.Создать();	
	context_params = ОбработкаСБИС.НастройкиПодключенияПрочитать(); 
	
	ФайлДокументаСЭДО = ОбработкаСБИС.local_helper_download_from_link(context_params, СсылкаНаФайл); 
	
	Чтение = Новый ЧтениеТекста(ФайлДокументаСЭДО.ОткрытьПотокДляЧтения(), КодировкаТекста.UTF8);
	СообщениеФССXML = Чтение.Прочитать();
	Чтение.Закрыть();
	
	Возврат СообщениеФССXML;
	
КонецФункции

Функция ЗаписатьSEDI_UUID(ИдентификаторЗапроса, Документ) Экспорт
	
	ОбработкаСБИС = Обработки.SABY.Создать();
	Выборка = ОбработкаСБИС.СтатусыДокументовПрочитатьПоUID(Документ["Идентификатор"]);
	Если Не Выборка.Следующий() Тогда
		Возврат Неопределено;
	КонецЕсли;
	Объект1С = Выборка.Объект;
	
	// Фомируем строку списка, что бы 1С корректно обработала ответ и записала UUID в документ и нужные регистры.
	СтрокаСписка = Новый Структура;
	СтрокаСписка.Вставить("Ссылка", Объект1С);
	СтрокаСписка.Вставить("ДоставкаИдентификатор", ИдентификаторЗапроса);
	СтрокаСписка.Вставить("Доставлен", Истина);
	СтрокаСписка.Вставить("ДатаОтправки", ТекущаяДата());
	СтрокаСписка.Вставить("Результат", "");
	СтрокаСписка.Вставить("ЗначениеРасшифровки", "");
	
	Менеджер = ОбщегоНазначения.МенеджерОбъектаПоПолномуИмени(
		Объект1С.Метаданные().ПолноеИмя()
	);
	Попытка
		Менеджер.ЗарегистрироватьРезультатыОтправки(СтрокаСписка, Новый Массив);
	Исключение
		// Новый вариант записи 
		СтрокаСписка.Вставить("Измененные", Новый Массив);
		СтрокаСписка.Вставить("Страхователь", Объект1С.Организация);
		СтрокаСписка.Вставить("ГоловнаяОрганизация", Объект1С.Организация.ГоловнаяОрганизация);
		СтрокаСписка.Вставить("ИдентификаторСообщения", ИдентификаторЗапроса);
		СтрокаСписка.Вставить("ДоставленоФонду", Истина);
		СтрокаСписка.Вставить("Успех", Истина);
		СтрокаСписка.Вставить("ДатаОтправкиФонду", ТекущаяДата());
		СтрокаСписка.Вставить("ТекстОшибки", "");
		СтрокаСписка.Вставить("ОтправленоОператору", Ложь);
		СтрокаСписка.Вставить("ДатаОтправкиОператору", Дата(1,1,1));
		СтрокаСписка.Вставить("ИдентификаторПакета", "");
		Менеджер.ЗарегистрироватьРезультатОтправки(СтрокаСписка);
	КонецПопытки;
	
КонецФункции


Функция ПолучитьСтруктуруПодготовливаемогоДействия(Знач Документ, ПараметрыСообщения)
	
	ПодготавливаемоеДействие = Новый Структура;
	
	ПодготавливаемоеДействие.Вставить("Идентификатор", Документ["Идентификатор"]); 
	ПодготавливаемоеДействие.Вставить("Тип", Документ["Тип"]);
	ПодготавливаемоеДействие.Вставить("ПодТип", ""); 
	ПодготавливаемоеДействие.Вставить("Этап", Новый Структура);
	
	ПодготавливаемоеДействие.Этап.Вставить("Название", Документ["Этап"][0]["Название"]); 
	ПодготавливаемоеДействие.Этап.Вставить("Идентификатор", Документ["Этап"][0]["Идентификатор"]); 
	
	ПодготавливаемоеДействие.Этап.Вставить("Действие", Новый Структура); 
	ПодготавливаемоеДействие.Этап.Действие.Вставить("Название", Документ["Этап"][0]["Действие"][0]["Название"]); 
	ПодготавливаемоеДействие.Этап.Действие.Вставить("Комментарий", ""); 
		
	Если ПараметрыСообщения <> Неопределено Тогда
		Сертификат = Новый Структура; 
		Сертификат.Вставить("Отпечаток", ПараметрыСообщения.СертификатСтрахователяОтпечаток); 
		Сертификат.Вставить("Ключ", Новый Структура("Тип", "Клиентский")); 
		ПодготавливаемоеДействие.Этап.Действие.Вставить("Сертификат", Сертификат);
	КонецЕсли;
		
	Возврат ПодготавливаемоеДействие;
		
КонецФункции

Функция ПолучитьСтруктуруВыполняемогоДействия(Знач РезультатПодготовкиДействия, ПараметрыСообщения)
			
	Если ПараметрыСообщения.Свойство("АдресПодписаногоЗапросаSOAP") Тогда
		РезультатПодготовкиДействия["Этап"][0]["Вложение"][0].Вставить("Подпись", Новый Массив);
		
		Файл = Новый Структура; 
		Файл.Вставить("Имя", РезультатПодготовкиДействия["Этап"][0]["Вложение"][0]["Файл"]["Имя"] + ".p7s");	
		Файл.Вставить(
			"ДвоичныеДанные", 
			Base64Строка(
				ПолучитьИзВременногоХранилища(ПараметрыСообщения.АдресПодписаногоЗапросаSOAP)
			)
		);                             
		
		Подпись = Новый Структура;  
		Подпись.Вставить("Тип", "XML");
		Подпись.Вставить("Файл", Файл);
			
		РезультатПодготовкиДействия["Этап"][0]["Вложение"][0]["Подпись"].Добавить(Подпись); 
	КонецЕсли;
	
	Если ПараметрыСообщения.Свойство("АдресРасшифрованногоОтветаSOAP") Тогда
    	Файл = Новый Структура; 
		Файл.Вставить("Имя", РезультатПодготовкиДействия["Этап"][0]["Вложение"][0]["Файл"]["Имя"]);
		
		Поток = Новый ПотокВПамяти;
		Запись = Новый ЗаписьТекста;
		Запись.Открыть(Поток, КодировкаТекста.UTF8);
		Запись.Записать(ПолучитьИзВременногоХранилища(ПараметрыСообщения.АдресРасшифрованногоОтветаSOAP));
		Запись.Закрыть();
		
		Файл.Вставить(
			"ДвоичныеДанные", 
			Base64Строка(
				Поток.ЗакрытьИПолучитьДвоичныеДанные()	
			)
		);
		
		РезультатПодготовкиДействия["Этап"][0]["Вложение"][0]["Файл"] = Файл;
	КонецЕсли;
		
	Возврат РезультатПодготовкиДействия;
		
КонецФункции

Процедура СохранитьДатуОтправкиПодтвержденияОПрочтении(Организация, ИдентификаторыСообщений) Экспорт

	Для каждого ИдентификаторСообщения Из ИдентификаторыСообщений Цикл
		Запись = РегистрыСведений.ВходящиеСообщенияСЭДОФСС.СоздатьМенеджерЗаписи();
		Запись.Организация = Организация;
		Запись.Идентификатор = ИдентификаторСообщения.Идентификатор;
		Запись.Прочитать();
		Если НЕ Запись.ПодтверждениеОтправлено Тогда
			Запись.Организация = Организация;
			Запись.Идентификатор = ИдентификаторСообщения.Идентификатор;
			Запись.ДатаОтправкиПодтверждения = ИдентификаторСообщения.Дата;
			Запись.ПодтверждениеОтправлено = Истина;
			Запись.Записать();
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры

#КонецОбласти

#Область include_core_base_Helpers_РаботаСоСвойствамиСтруктуры
#КонецОбласти

#Область include_core_base_locale_ЛокализацияНазваниеПродукта
#КонецОбласти

#Область include_core_base_ExtException
#КонецОбласти
