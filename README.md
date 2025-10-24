sudo cp process_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/process_monitor.sh

# Копируем systemd файлы
sudo cp process-monitor.service /etc/systemd/system/
sudo cp process-monitor.timer /etc/systemd/system/

# Создаем лог-файл
sudo touch /var/log/monitoring.log
sudo chmod 644 /var/log/monitoring.log

# Перезагружаем systemd
sudo systemctl daemon-reload

# Включаем и запускаем таймер
sudo systemctl enable process-monitor.timer
sudo systemctl start process-monitor.timer

# Создаем символическую ссылку для процесса test
sudo ln -sf /usr/bin/sleep /usr/local/bin/test

# Запускаем тестовый процесс
/usr/local/bin/test 1000 &

# Запускаем мониторинг вручную
sudo /usr/local/bin/process_monitor.sh

# Смотрим логи
sudo tail -f /var/log/monitoring.log
Конец :)
