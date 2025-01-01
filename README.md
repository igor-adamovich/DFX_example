# Частичная реконфигурация Artix-7 через PCI-Express
Данный репозиторий является дополнением к нашей статье в журнале **FPGA-Systems Magazine :: FSM :: № GAMMA (state_2)**.
Проект предназначен для **Vivado 2024.2** и демонстрирует возможности
частичной реконфигурации Artix-7 на devkit'е **Artix-7 AC701 Evaluation Platform (xc7a200tfbg676-2)**.

Проект состоит из двух частей:
- **hardware** -- содержит дизайн для Vivado.
- **software** -- содержит простую программу для взаимодействия с прошивкой.

## Hardware
Наше устройство настроено таким образом, что в PCI-Express имеет следующий ID:\
**Vendor ID - 0000, Device ID - 0001, Class - ff00**.\

Прошивка для ПЛИС генерируется обычным способом, проект уже настроен.
Больше деталей в статье.

## Software
### Подготовка
Сначала нужно прошить базовую (полную) прошивку в ПЛИС через JTAG.
Обычно после этого перестает работать PCI-Express у ПЛИС.
Для того, чтобы возобновить соединение нужно либо перезагрузить компьютер, либо выполнить
специальную последовательность команд.
Но сначала нужно сделать:
```
>  lspci -d 0000:0001:ff00
c1:00.0 Unassigned class [ff00]: Device 0000:0001
```
На нашем стенде devkit получил ID с1:00.0. В вашей системе он будет отличаться.
Этот ID надо запомнить и использовать в следующей команде для обновления PCI-Express устройства:
```
> sudo setpci -s c1:00.0 COMMAND=0x102
```

**Обратите внимание, что в последней команде используется ID *ПРЕДЫДУЩЕГО* устройства!**

### Реконфигурация
Для того, чтобы прошить реконфигурируемый модуль в ПЛИС через PCI-Express следуйте инструкции ниже.\
Сначала скомпилируйте утилиту software/dfxdevmem.c:
```
> gcc -o dfxdevmem dfxdevmem.c
```

Эта утилита использует /dev/mem для записи данных в нужные BAR'ы нашего устройства (и чтения версии прошивки).
Для ее корректной работы нужны правильные адреса BAR'ов. Эти адреса можно узнать с помощью **lspci -v**:
```
> lspci -v -d 0000:0001:ff00
c1:00.0 Unassigned class [ff00]: Device 0000:0001
        Flags: fast devsel, IOMMU group 10
        Memory at c4200000 (32-bit, non-prefetchable) [size=1M]
        Memory at 18020f00000 (64-bit, prefetchable) [size=1M]
        Capabilities: <access denied>
```
У нашего устройства 2 BAR'а,  которые имеют следующие адреса **в этой системе**: 
- **BAR 0** получил адрес **0xc4200000**. Этот адрес нужно указывать при частичной прошивке.
- **BAR 2** получил адрес **0x18020f00000**. Этот адрес используется для чтения версии прошивки (чтобы убедиться, что частичная конфигурация отработала корректно).
 
 ***В вашей системе адреса будут отличаться!***

Чтобы прошить устройство реконфигурируемым модулем запустите нашу программу следующим образом (но со своим адресом **BAR 0** и **местоположением файла прошивки**):
```
> sudo dfxdevmem -b 0xc4200000 -f dummy_axis_dummy_axis_dummy_wrapper_b_partial.bin
```
Обратите внимание, что dfxdevmem принимает данные в разных форматах: в 8-, 10- и 16- ричном. 
Поэтому ***перед адресом, полученным от lspci, необходимо дописать "0x"***

Версия прошивки доступна при чтении из **BAR 2** для конфигураций config_1 и config_2. Конфигурация config_3 содержит пустую прошивку для реконфигурируемой области, поэтому чтение из нее *приведет к зависанию системы*.
Чтобы прочитать версию прошивки для config_1/config_2 укажите адрес **BAR 2** без указания файла:
```
> sudo dfxdevmem -b 0x18020f00000
```
Для запуска нашей утилиты вам нужны права доступа к файлу **/dev/mem** или права суперпользователя.

VHDL and C source code of this project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.\
Copyright (c) 2024 Адамович Игорь Алексеевич