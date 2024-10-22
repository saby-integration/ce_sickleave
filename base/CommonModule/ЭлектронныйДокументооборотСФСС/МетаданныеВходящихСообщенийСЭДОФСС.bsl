
&Вместо("МетаданныеВходящихСообщенийСЭДОФСС")
Функция Saby_МетаданныеВходящихСообщенийСЭДОФСС(Организация, ДатаСообщений)
	
	Если Saby_ЭДОСФСС.ПолучитьЗначениеФункциональнойОпции("Saby_ИспользоватьЭЛН") Тогда
		// Возвращаем вместо идентификаторов даты сообщений. В дальнейшем мы выполним СБИС.СписокИзменений
		// и загрузим все входящие сообщения минимально указанной даты.
		Результат = Новый Структура("Выполнено, ОписаниеОшибки, ДанныеСообщений", Истина, "", Новый Массив);
		Результат.ДанныеСообщений.Добавить(
			Новый Структура(
				"Идентификатор, Тип, Получатель, ТребуетсяПодтверждение, Новое",
				ДатаСообщений,
				2,
				Ложь, 
				Ложь
			)
		); 
		
		Возврат Результат;
	Иначе
		Результат = ПродолжитьВызов(Организация, ДатаСообщений);
		Возврат Результат;
	КонецЕсли;
	
КонецФункции

